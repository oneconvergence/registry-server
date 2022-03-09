# Dkube Registry Server
This repository contains the scripts to install and push images to the Harbor registry server used for hosting images to use Dkube in airgapped environments. The following are the scripts used for bringup:
1. install.sh - To install Harbor registry on the node on which the script is run.
2. download.sh - To download and tar required images from dockerhub (Only if registry-server node does not have internet access).
3. upload.sh - To upload the required images to Harbor registry server.
4. update-dockerd.sh - To update docker configuration on all nodes in the airgapped cluster.

# Registry Server Install 

## Prerequisites
1. Registry-server should have the following packages installed - docker, docker-compose, curl.

## Registry Server Bringup:
1. On registry-server node, Clone this repo: `git clone https://github.com/oneconvergence/registry-server.git`
2. Go to registy-server directory: `cd registry-server`
3. Run `./install.sh` (Logs stored at `/tmp/harbor.log` on host machine)

## Upload Images to the registry server
#### If registry server node does not have internet access:
1. On a separate node with internet, list required images in `images.txt` and use `registry-server/download.sh` to download the images: 
 `./download.sh --image-list images/<dkube_version>.txt --output images.tar`
2. Transfer `images.tar`  to registry server node via USB disk or any other method.
3. On the registry server node, run:
 `./upload.sh --image-list images/<dkube_version>.txt --images images.tar`

#### If registry server node has internet access:
1. On the registry server node run the following:
 `./upload.sh --image-list images/<dkube_version>.txt`
 
 
# Update docker configuration on cluster nodes

## Prerequisites
Passwordless ssh should be allowed from registry server node to all other nodes.

1. Run `./update-dockerd.sh` and pass the username and list of cluster node's IPs
