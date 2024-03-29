#!/bin/bash
usage () {
    echo "USAGE: $0 [--address x.x.x.x]"
    echo "  [-i|--address IPAddress] Optional. Local IP of the machine on which this script is to be run."
    echo "  [-u|--uninstall] Uninstall harbor registry"
    echo "  [-h|--help] Usage message"
}

packageList="docker-compose parallel curl wget"
distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
if [[ $distro == *"Ubuntu"* ]]; then
        for packageName in $packageList; do
		dpkg -s $packageName &> /dev/null
                if [ $? -ne 0 ]; then
                        echo "Install failed: Package $packageName not installed."
                        echo "Please install the following packages and retry: [$packageList]"
                        exit 1
                fi
        done
elif [[ $distro == *"CentOS"* ]]; then
        for packageName in $packageList; do
                yum list installed $packageName &> /dev/null
                if [ $? -ne 0 ]; then
                        echo "Install failed: Package $packageName not installed."
                        echo "Please install the following packages and retry: [$packageList]"
                        exit 1
                fi
        done
fi


while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -i|--address)
        privateIP="$2"
        shift # past argument
        shift # past value
        ;;
        -h|--help)
        help="true"
        shift
        ;;
        -u|--uninstall)
        cd installer
        sudo docker-compose down
        exit 0
        ;;
        *)
        usage
        exit 1
        ;;
    esac
done
if [[ $help ]]; then
    usage
    exit 0
fi

privateIP="$(hostname -I | awk '{print $1;}')"
echo "Using local IP $privateIP for registry-server..."

echo "Updating hosts list on registry-server node..."
numDkubeRegistryhosts=$(grep -nr "registry-server.dkube.io" /etc/hosts | wc -l)
if [ $numDkubeRegistryhosts -lt 1 ]; then
	sudo -- sh -c "echo \"$privateIP registry-server.dkube.io\" >> /etc/hosts"
else
	sudo sed -i "s/.* registry-server.dkube.io/$privateIP registry-server.dkube.io/g" /etc/hosts
fi
echo "Updated hosts list!"

echo "Updating docker certs on the registry server node..."
docker_certs_path="/etc/docker/certs.d/registry-server.dkube.io:443"
sudo mkdir -p $docker_certs_path
sudo cp ./certs/ca.crt $docker_certs_path
sudo cp ./certs/registry-server.dkube.io.cert $docker_certs_path
sudo cp ./installer/config/proxy/registry-server.dkube.io.key $docker_certs_path
echo "Updated docker certs!"

echo "Bringing up harbor registry server..."
docker_certs_path="/etc/docker/certs.d/registry-server.dkube.io:443"
sed -i "s/registry_server_IP/$privateIP/g" ./installer/docker-compose.yml
cd installer
sudo docker-compose up -d
sudo docker-compose logs -f -t > /tmp/harbor.log &

# Check if registry server is running
while true
do
        nc $privateIP 443 -zv &> /dev/null
        if [ $? -ne 0 ]; then
                echo "Couldn't connect to registry server at $privateIP:443. Trying again..." >&2
                sleep 10s
        else
                echo "Successfully brought up registry server at $privateIP:443" >&2
                break
        fi
done
./create_default_projects.sh $privateIP
echo "Harbor registry server bringup and configuration done."
