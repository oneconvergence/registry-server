#!/bin/bash
usage () {
    echo "USAGE: $0 OPTION"
    echo "  [--start] Start proxy server."
    echo "  [--stop] Shutdown proxy server."
    echo "  [-h|--help] Usage message"
}

start_proxy_server() {
    sudo docker run --name squid -d --restart=always \
      --publish 3128:3128 \
      --volume $PWD/proxy-server/config/squid.conf:/etc/squid/squid.conf \
      --volume /srv/docker/squid/cache:/var/spool/squid \
      sameersbn/squid:3.5.27-2
}

stop_proxy_server() {
    sudo docker kill squid || true
    sudo docker rm squid
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi
key="$1"
case $key in
    --start)
	start_proxy_server
	exit 0
    ;;
    --stop)
	stop_proxy_server
	exit 0
    ;;
    -h|--help)
        usage
        exit 0
    ;;
    *)
        usage
        exit 1
    ;;
esac
