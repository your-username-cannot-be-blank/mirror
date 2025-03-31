#!/opt/dns_server_venv/bin/python
import socket as orig_socket
import socks
import socketserver
from dnslib import DNSRecord, QTYPE, RR, A
import re
import sys
import os
import subprocess
import time
from collections import OrderedDict

# Настройки
PROXY_HOST = '127.0.0.1'
PROXY_PORT = 1080
DNS_SERVER = '8.8.8.8'
DNS_PORT = 53
HOST, PORT = "0.0.0.0", 53

# Настраиваем socket для использования SOCKS5 прокси (TCP)
socks.set_default_proxy(socks.SOCKS5, PROXY_HOST, PROXY_PORT)
socks.wrapmodule(orig_socket)

def load_ip_list(filename):
    if os.path.exists(filename):
        with open(filename, 'r') as f:
            return set(line.strip() for line in f if line.strip())
    return set()

def add_ip(ip, ip_set, filename):
    if ip not in ip_set:
        try:
            subprocess.run(['ipset', 'add', 'redirect_domains', ip], check=True)
            print(f"Добавлен IP: {ip}")
            ip_set.add(ip)
            with open(filename, 'a') as f:
                f.write(f"{ip}\n")
        except subprocess.CalledProcessError:
            print(f"Не удалось добавить IP: {ip}", file=sys.stderr)

# Загрузка списка IP-адресов и доменов
ip_list = load_ip_list('ip_list.txt')
with open('list.txt', 'r') as f:
    domains = set(line.strip() for line in f)

# Добавление существующих IP-адресов в ipset
for ip in ip_list:
    try:
        subprocess.run(['ipset', 'add', 'redirect_domains', ip], check=True)
        print(f"Добавлен существующий IP: {ip}")
    except subprocess.CalledProcessError:
        print(f"Не удалось добавить существующий IP: {ip}", file=sys.stderr)


# Настройки кэша
CACHE_SIZE = 1000  # Максимальное количество записей в кэше
CACHE_TTL = 300    # Время жизни записи в кэше (в секундах)

class LRUCache:
    def __init__(self, capacity):
        self.cache = OrderedDict()
        self.capacity = capacity

    def get(self, key):
        if key not in self.cache:
            return None
        value, expiry = self.cache[key]
        if time.time() > expiry:
            self.cache.pop(key)
            return None
        self.cache.move_to_end(key)
        return value

    def put(self, key, value, ttl):
        self.cache[key] = (value, time.time() + ttl)
        self.cache.move_to_end(key)
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)

dns_cache = LRUCache(CACHE_SIZE)

class DNSHandler(socketserver.BaseRequestHandler):
    def handle(self):
        data, local_socket = self.request
        dns_request = DNSRecord.parse(data)

        print(f"Получен запрос: {dns_request.q.qname}")

        cache_key = (dns_request.q.qname, dns_request.q.qtype)
        cached_response = dns_cache.get(cache_key)

        if cached_response:
            print(f"Найден кэшированный ответ для {dns_request.q.qname}")
            # Создаем новый DNSRecord с правильным ID
            cached_dns_response = DNSRecord.parse(cached_response)
            cached_dns_response.header.id = dns_request.header.id
            response_data = cached_dns_response.pack()
        else:
            requested_domain = str(dns_request.q.qname).rstrip('.')
            domain_match = any(d in requested_domain for d in domains)

            with socks.socksocket(orig_socket.AF_INET, orig_socket.SOCK_STREAM) as s:
                s.connect((DNS_SERVER, DNS_PORT))
                
                tcp_request = len(data).to_bytes(2, 'big') + data
                s.sendall(tcp_request)
                
                length_bytes = s.recv(2)
                if len(length_bytes) < 2:
                    return
                length = int.from_bytes(length_bytes, 'big')
                response_data = s.recv(length)

            dns_response = DNSRecord.parse(response_data)

            if domain_match:
                for rr in dns_response.rr:
                    if rr.rtype == QTYPE.A:
                        ip = str(rr.rdata)
                        print(f"Найден IP-адрес для {requested_domain}: {ip}", file=sys.stderr)
                        add_ip(ip, ip_list, 'ip_list.txt')

            # Кэшируем ответ без учета ID запроса
            dns_cache.put(cache_key, response_data, CACHE_TTL)

        # Отправляем ответ клиенту
        local_socket.sendto(response_data, self.client_address)
        print(f"Ответ отправлен клиенту: {self.client_address}")

class DNSServer(socketserver.UDPServer):
    def __init__(self, server_address, handler_class):
        super().__init__(server_address, handler_class)
        self.socket = orig_socket.socket(orig_socket.AF_INET, orig_socket.SOCK_DGRAM)
        self.server_bind()
        self.server_activate()

if __name__ == '__main__':
    with DNSServer((HOST, PORT), DNSHandler) as server:
        print(f"DNS сервер запущен на {HOST}:{PORT}")
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("Сервер остановлен пользователем.")
        finally:
            print("Сервер завершил работу.")