#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 domain"
    exit 1
fi

DOMAIN="$1"
BIN_FILE="tls_clienthello_$(echo ${DOMAIN} | sed 's/\./_/g').bin"

OUTPUT_DIR="/opt/zapret/files/fake"

if [ ! -d "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(pwd)
fi

BIN_FILE="${OUTPUT_DIR}/${BIN_FILE}"

CAPTURE_FILE=$(mktemp)
JSON_FILE=$(mktemp)

sudo apt install tshark jq curl

sudo tshark -i any -f "tcp port 443" -w "$CAPTURE_FILE" &
TSHARK_PID=$!

sleep 2

curl -k "https://$DOMAIN" > /dev/null 2>&1

sleep 2

sudo kill $TSHARK_PID
wait $TSHARK_PID 2>/dev/null

sudo tshark -r "$CAPTURE_FILE" -Y "tls.handshake.type==1 && tls.handshake.extensions_server_name == \"$DOMAIN\"" -T jsonraw > "$JSON_FILE"

if jq -e '.[]._source.layers.tls."tls.record_raw"[0]' "$JSON_FILE" > /dev/null; then
    cat "$JSON_FILE" | jq -r '.[]._source.layers.tls."tls.record_raw"[0]' | xxd -r -p > "$BIN_FILE"
    echo "TLS Client Hello record raw data saved to $BIN_FILE"
    echo "File size: $(stat -c %s "$BIN_FILE") bytes"
else
    echo "No TLS Client Hello record found for $DOMAIN."
fi

rm "$CAPTURE_FILE"
rm "$JSON_FILE"