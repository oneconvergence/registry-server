set -x
server_name="registry-server.dkube.io"

# Generate CA cert
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=$server_name" \
 -key ca.key \
 -out ca.crt

# Generate server cert
openssl genrsa -out $server_name.key 4096
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=$server_name" \
    -key $server_name.key \
    -out $server_name.csr
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=$server_name
EOF
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in $server_name.csr \
    -out $server_name.crt

sudo mkdir -p /data/cert
sudo cp $server_name.crt /data/cert/
sudo cp $server_name.key /data/cert/

openssl x509 -inform PEM -in $server_name.crt -out $server_name.cert

# Configuration for harbor - only on server node 
sudo mv $server_name.crt ../installer/config/proxy/
sudo mv $server_name.key ../installer/config/proxy/
chmod 644 ../installer/config/proxy/$server_name.key
