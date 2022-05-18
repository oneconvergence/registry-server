#!/bin/bash

k8s_ini="$HOME/.dkube/k8s.ini"

port="3128"
ext_proxy=false
ext_proxy_address=""
start_proxy=true

usage () {
    echo "USAGE: $0 [--start/--stop] [--port 3128] [--use-proxy 10.10.8.8:5000]"
    echo "  [--start] Start proxy server."
    echo "  [--stop] Shutdown proxy server."
    echo "  [--port] Port Number to start and expose proxy server on."
    echo "  [--use-proxy] Address of external proxy server to use."
    echo "  [-h|--help] Usage message"
}

enable_external_proxy() {
	sudo echo "http_proxy=http://$ext_proxy_address/" | tee -a /etc/environment
	sudo echo "https_proxy=http://$ext_proxy_address/" | tee -a /etc/environment
	sudo mkdir -p /etc/systemd/system/docker.service.d
	sudo cat >> /etc/systemd/system/docker.service.d/proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://$ext_proxy_address"
Environment="HTTPS_PROXY=https://$ext_proxy_address"
EOF
	sudo systemctl daemon-reload
	sudo systemctl restart docker
}

disable_external_proxy() {
	sudo sed -i "/http_proxy/d" /etc/environment 
	sudo sed -i "/https_proxy/d" /etc/environment 
	sudo sed -i "/Service/d" /etc/systemd/system/docker.service.d/proxy.conf 
	sudo sed -i "/HTTP_PROXY/d" /etc/systemd/system/docker.service.d/proxy.conf 
	sudo sed -i "/HTTPS_PROXY/d" /etc/systemd/system/docker.service.d/proxy.conf 
	sudo systemctl daemon-reload
	sudo systemctl restart docker
}

start_proxy_server() {
	if [ $ext_proxy == true ] ; then
		enable_external_proxy 
	else
		sudo docker run --name squid -d --restart=always \
		--publish $port:3128 \
		--volume $PWD/proxy-server/config/squid.conf:/etc/squid/squid.conf \
		--volume /srv/docker/squid/cache:/var/spool/squid \
		sameersbn/squid:3.5.27-2
	fi	       
}

stop_proxy_server() {
	sudo docker kill squid || true
	sudo docker rm squid
	disable_external_proxy
}

while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
	    --start)
		start_proxy=true
		shift # past argument
	    ;;
	    --stop)
		start_proxy=false
		shift # past argument 
	    ;;
	    -p|--port)
		port="$2"
		shift # past argument
		shift # past value
	    ;;
	    --use-proxy)
		ext_proxy=true
		ext_proxy_address="$2"
		shift # past argument
		shift # past value
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
done

if $start_proxy; then
	start_proxy_server
else
	stop_proxy_server
fi
