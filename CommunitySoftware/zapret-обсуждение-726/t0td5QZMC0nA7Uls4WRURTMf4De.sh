#!/bin/sh
SERVICE_NAME="dvtws"
SERVICE_CMD="/opt/zapret/nfq/dvtws"
YOUTUBE_LIST="/opt/zapret/lists/russia-youtube.txt"
SECOND_LIST="/opt/zapret/lists/russia-blacklist.txt"
QUIC_BIN="/opt/zapret/files/fake/quic_initial_www_google_com.bin"
TLS_BIN="/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
NETIF="pppoe0"
is_service_running() {
  pgrep -f "${SERVICE_CMD}" > /dev/null && return 0 || return 1
}
require_module() {
  if ! kldstat | grep "${1}" > /dev/null; then
    if ! kldload "${1}"; then
      exit 1
    fi
  fi
  echo "Модуль ${1} загружен."
  return 1
}
mng_service() {
  if [ "${1}" = "start" ]; then
    require_module ipdivert
    require_module ipfw

    ipfw delete 100
    ipfw add 100 divert 989 tcp from any to any 80,443 out not diverted xmit "$NETIF"
    ipfw add 100 divert 989 udp from any to any 443 out not diverted xmit "$NETIF"

    ${SERVICE_CMD} \
    --port=989 \
    --filter-udp=443 --hostlist="$YOUTUBE_LIST" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="$QUIC_BIN" --new \
    --filter-udp=50000-65535 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic="$QUIC_BIN" --new \
    --filter-tcp=80 --hostlist="$YOUTUBE_LIST" --dpi-desync=fake,split2 --dpi-desync-fooling=md5sig --new \
    --filter-tcp=443 --dpi-desync=split2 --dpi-desync-split-seqovl=49 --dpi-desync-split-pos=50 --wssize 1:6 \
    | logger -t "${SERVICE_NAME}" >/dev/null 2>&1 &
    
    pfctl -d; pfctl -e
  elif [ "${1}" = "stop" ]; then

    ipfw delete 100

    pkill -f "${SERVICE_CMD}"

    pfctl -d; pfctl -e

  fi
}
show_service_status() {
  if is_service_running; then
    echo "Сервис ${SERVICE_NAME} запущен."
  else
    echo "Сервис ${SERVICE_NAME} не работает."
  fi
}
case "${1}" in
start)
  mng_service start
  ;;
stop)
  mng_service stop
  ;;
status)
  show_service_status
  ;;
restart)
  mng_service stop
  sleep 2
  mng_service start
  ;;
*)
  echo "Usage: ${SERVICE_NAME} {start|stop|status|restart}"
  exit 1
  ;;
esac