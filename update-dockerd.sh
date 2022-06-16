user=""
nodes=""
harbor_ip="$(hostname -I | awk '{print $1;}')"
docker_certs_path="/etc/docker/certs.d/registry-server.dkube.io:443"
k8s_ini="$HOME/.dkube/k8s.ini"

usage () {
    echo "USAGE: $0"
    echo "  Modify ~/.dkube/k8s.ini to contain the list of node IPS and ssh user before running script. All nodes should be accessible by ssh passwordlessly."
    echo "  [-h|--help] Usage message"
}

nodes=$(awk '/\[nodes\]/{ f = 1; next } /\[STORAGE\]/{ f = 0 } f' $k8s_ini | sed '/^#/d' | tr '\n' ' ' | awk '{$1=$1};1')
user=$(sed -n -e 's/user=//p' $k8s_ini)

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
        help="true"
        shift
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

#Read the split words into an array based on space delimiter
IFS=' ' read -a nodes_arr <<< "$nodes"

for IP in "${nodes_arr[@]}"; do

	echo "Adding registry server in hosts for $user at ($IP)..."
	ssh $user@$IP "num_dkube_hosts=\$(grep -nr \"registry-server.dkube.io\" /etc/hosts | wc -l)
	if [ \$num_dkube_hosts -lt 1 ]; then
		sudo -- sh -c \"echo $harbor_ip registry-server.dkube.io >> /etc/hosts\"
	else
		sudo sed -i \"s/.* registry-server.dkube.io/$harbor_ip registry-server.dkube.io/g\" /etc/hosts
	fi"
	echo "Added registry server in hosts for user ($user) at ($IP) successfully!"
	echo ""

	echo "Updating docker certs for user ($user) at ($IP)..."
	temp="/home/$user/temp"
	ssh $user@$IP "mkdir -p $temp"
	scp ./certs/ca.crt $user@$IP:$temp
	scp ./certs/registry-server.dkube.io.cert $user@$IP:$temp
	scp ./installer/config/proxy/registry-server.dkube.io.key $user@$IP:$temp
	ssh $user@$IP "sudo mkdir -p $docker_certs_path; sudo cp -r $temp/* $docker_certs_path; rm -rf $temp; sudo systemctl restart docker; sudo getent group docker || sudo groupadd docker; sudo usermod -aG docker $user"
	echo "Updated docker certs for user ($user) at ($IP) successfully!"
	echo ""
	echo ""

done

echo "Updated dockerd on all nodes."
