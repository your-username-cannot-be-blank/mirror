#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import print_function

import binascii,socket,struct
from collections import deque
from ipaddress import IPv4Network

from dnslib import DNSRecord,RCODE,QTYPE,A
from dnslib.server import DNSServer,DNSHandler,BaseResolver,DNSLogger
import subprocess
import shlex
import sys

class ProxyResolver(BaseResolver):
    """
        Proxy resolver - passes all requests to upstream DNS server and
        returns response

        Note that the request/response will be each be decoded/re-encoded 
        twice:

        a) Request packet received by DNSHandler and parsed into DNSRecord 
        b) DNSRecord passed to ProxyResolver, serialised back into packet 
           and sent to upstream DNS server
        c) Upstream DNS server returns response packet which is parsed into
           DNSRecord
        d) ProxyResolver returns DNSRecord to DNSHandler which re-serialises
           this into packet and returns to client

        In practice this is actually fairly useful for testing but for a
        'real' transparent proxy option the DNSHandler logic needs to be
        modified (see PassthroughDNSHandler)

    """

    def __init__(self,address,port,timeout,iprange,tablename='dnsmap'):
        self.address = address
        self.port = port
        self.timeout = timeout
        self.unassigned_addresses = deque([str(x) for x in IPv4Network(iprange).hosts()])
        self.ipmap = {}
        self.tablename = tablename

        # Load existing mappings
        output = subprocess.check_output(["./get_iptables_mappings.sh"])
        for mapped in output.decode().split("\n"):
            if mapped:
                fake_addr, real_addr = mapped.split(' ')
                self.add_mapping(real_addr, fake_addr) or sys.exit(1)
        #self.unassigned_addresses.remove()

    def get_mapping(self, real_addr):
        return self.ipmap.get(real_addr)

    def add_mapping(self, real_addr, fake_addr=None):
        if self.get_mapping(real_addr):
            # Real addr is already mapped
            print("Real addr {} is already mapped".format(real_addr))
            return False

        if fake_addr:
            try:
                self.unassigned_addresses.remove(fake_addr)
                self.ipmap[real_addr]=fake_addr
                print('Mapping {} to {}'.format(fake_addr, real_addr))
            except ValueError:
                print("Fake addr {} not in unassigned addresses list".format(fake_addr))
                return False
        else:
            try:
                fake_addr = self.unassigned_addresses.popleft()
            except IndexError:
                print("ERROR: No IP addresses left!!!")
                return False
            print('Mapping {} to {}'.format(fake_addr, real_addr))
            self.ipmap[real_addr]=fake_addr
            subprocess.call(
                ["./set_iptables.sh", real_addr, fake_addr]
                )
            return fake_addr
        return True


    def resolve(self,request,handler):
        try:
            if handler.protocol == 'udp':
                proxy_r = request.send(self.address,self.port,
                                timeout=self.timeout)
            else:
                proxy_r = request.send(self.address,self.port,
                                tcp=True,timeout=self.timeout)
            reply = DNSRecord.parse(proxy_r)

            if request.q.qtype == QTYPE.AAAA or request.q.qtype == QTYPE.HTTPS:
                print('GOT AAAA or HTTPS')
                reply = request.reply()
                return reply

            if request.q.qtype == QTYPE.A:
                print('GOT A')

                newrr = []
                for record in reply.rr:
                    if record.rtype == QTYPE.CNAME:
                        continue
                    newrr.append(record)
                reply.rr = newrr

                for record in reply.rr:
                    if record.rtype != QTYPE.A:
                        continue
                    print("Got RECORD:", record)
                    #print(dir(record))
                    #print(type(record.rdata))

                    real_addr = str(record.rdata)
                    fake_addr = self.get_mapping(real_addr)
                    if not fake_addr:
                        fake_addr = self.add_mapping(real_addr)
                    if not fake_addr:
                        print("No fake_addr, something went wrong!")
                        reply = request.reply()
                        reply.header.rcode = getattr(RCODE,'SERVFAIL')
                        return reply

                    record.rdata = A(fake_addr)
                    record.rname = request.q.qname
                    record.ttl = 300
                    #print(a.rdata)
                return reply

            #print(reply)
        except socket.timeout:
            reply = request.reply()
            reply.header.rcode = getattr(RCODE,'NXDOMAIN')

        return reply

class PassthroughDNSHandler(DNSHandler):
    """
        Modify DNSHandler logic (get_reply method) to send directly to 
        upstream DNS server rather then decoding/encoding packet and
        passing to Resolver (The request/response packets are still
        parsed and logged but this is not inline)
    """
    def get_reply(self,data):
        host,port = self.server.resolver.address,self.server.resolver.port

        request = DNSRecord.parse(data)
        self.log_request(request)

        if self.protocol == 'tcp':
            data = struct.pack("!H",len(data)) + data
            response = send_tcp(data,host,port)
            response = response[2:]
        else:
            response = send_udp(data,host,port)

        reply = DNSRecord.parse(response)
        self.log_reply(reply)

        return response

def send_tcp(data,host,port):
    """
        Helper function to send/receive DNS TCP request
        (in/out packets will have prepended TCP length header)
    """
    sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    sock.connect((host,port))
    sock.sendall(data)
    response = sock.recv(8192)
    length = struct.unpack("!H",bytes(response[:2]))[0]
    while len(response) - 2 < length:
        response += sock.recv(8192)
    sock.close()
    return response

def send_udp(data,host,port):
    """
        Helper function to send/receive DNS UDP request
    """
    sock = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
    sock.sendto(data,(host,port))
    response,server = sock.recvfrom(8192)
    sock.close()
    return response

if __name__ == '__main__':

    import argparse,sys,time

    p = argparse.ArgumentParser(description="DNS Proxy")
    p.add_argument("--port","-p",type=int,default=53,
                    metavar="<port>",
                    help="Local proxy port (default:53)")
    p.add_argument("--address","-a",default="",
                    metavar="<address>",
                    help="Local proxy listen address (default:all)")
    p.add_argument("--upstream","-u",default="8.8.8.8:53",
            metavar="<dns server:port>",
                    help="Upstream DNS server:port (default:8.8.8.8:53)")
    p.add_argument("--tcp",action='store_true',default=False,
                    help="TCP proxy (default: UDP only)")
    p.add_argument("--timeout","-o",type=float,default=5,
                    metavar="<timeout>",
                    help="Upstream timeout (default: 5s)")
    p.add_argument("--passthrough",action='store_true',default=False,
                    help="Dont decode/re-encode request/response (default: off)")
    p.add_argument("--log",default="request,reply,truncated,error",
                    help="Log hooks to enable (default: +request,+reply,+truncated,+error,-recv,-send,-data)")
    p.add_argument("--log-prefix",action='store_true',default=False,
                    help="Log prefix (timestamp/handler/resolver) (default: False)")
    p.add_argument("--iprange",default="10.224.0.0/24",
            metavar="<ip/mask>",
                    help="Fake IP range (default:10.224.0.0/24)")
    args = p.parse_args()

    args.dns,_,args.dns_port = args.upstream.partition(':')
    args.dns_port = int(args.dns_port or 53)

    print("Starting Proxy Resolver (%s:%d -> %s:%d) [%s]" % (
                        args.address or "*",args.port,
                        args.dns,args.dns_port,
                        "UDP/TCP" if args.tcp else "UDP"))

    resolver = ProxyResolver(args.dns,args.dns_port,args.timeout,args.iprange)
    handler = PassthroughDNSHandler if args.passthrough else DNSHandler
    logger = DNSLogger(args.log,args.log_prefix)
    udp_server = DNSServer(resolver,
                           port=args.port,
                           address=args.address,
                           logger=logger,
                           handler=handler)
    udp_server.start_thread()

    if args.tcp:
        tcp_server = DNSServer(resolver,
                               port=args.port,
                               address=args.address,
                               tcp=True,
                               logger=logger,
                               handler=handler)
        tcp_server.start_thread()

    while udp_server.isAlive():
        time.sleep(1)
