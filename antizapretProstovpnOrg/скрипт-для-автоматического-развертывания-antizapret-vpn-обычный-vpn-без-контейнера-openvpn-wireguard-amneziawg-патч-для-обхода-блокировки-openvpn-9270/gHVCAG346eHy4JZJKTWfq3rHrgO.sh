#!/bin/bash
set -e

echo ""
echo "Tell me a name for the new client AntiZapret VPN"
echo "The name must consist of alphanumeric character, it may also include an underscore or a dash"

until [[ $CLIENT =~ ^[a-zA-Z0-9_-]+$ ]]; do
	read -rp "Client name: " -e CLIENT
done

HERE="$(dirname "$(readlink -f "${0}")")"
cd "$HERE/easyrsa3"

export EASYRSA_CERT_EXPIRE=3650

set +e

SERVER=""
for i in 1 2 3 4 5;
do
    SERVER="$(curl -s -4 icanhazip.com)"
    [[ "$?" == "0" ]] && break
    sleep 2
done
[[ ! "$SERVER" ]] && echo "Can't determine global IP address!" && exit

set -e

if [[ ! -f /etc/openvpn/client/keys/$CLIENT.crt ]] || \
   [[ ! -f /etc/openvpn/client/keys/$CLIENT.key ]]
then
    EASYRSA_BATCH=1 ./easyrsa build-client-full "$CLIENT" nopass nodatetime
    cp ./pki/issued/$CLIENT.crt /etc/openvpn/client/keys/$CLIENT.crt
    cp ./pki/private/$CLIENT.key /etc/openvpn/client/keys/$CLIENT.key
else
	echo "The specified client was already found, please choose another name"
fi

./easyrsa revoke $CLIENT
rm /etc/openvpn/client/$CLIENT-udp.ovpn
rm /etc/openvpn/client/$CLIENT-tcp.ovpn
echo "Пользователь $CLIENT удален."
