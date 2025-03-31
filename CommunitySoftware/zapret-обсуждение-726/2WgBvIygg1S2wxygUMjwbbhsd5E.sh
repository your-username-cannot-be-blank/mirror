#!/bin/bash

if [ -z "$1" ]; then
    echo "Использование: $0 example.com"
    exit 1
fi

DOMAIN="$1"
BIN_FILE="tls_clienthello_$(echo ${DOMAIN} | sed 's/\./_/g').bin"
OUTPUT_DIR="/opt/zapret/files/fake"

if [ ! -d "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(pwd)
fi

BIN_FILE="${OUTPUT_DIR}/${BIN_FILE}"
PORT=4343

(nc -l -p $PORT > "$BIN_FILE") &

NC_PID=$!

curl -k "https://$DOMAIN" --connect-to ::127.0.0.1:$PORT -m 1 > /dev/null 2>&1

if [ -s "$BIN_FILE" ]; then
    echo "Данные TLS Client Hello сохранены в $BIN_FILE"
else
    echo "Данные не были захвачены."
    rm "$BIN_FILE"
fi
