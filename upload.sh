#!/bin/bash
images=""
reg="registry-server.dkube.io:443"
list=""
dkube_version=""
log_file="/tmp/upload-images.log"
metrics_file="metrics.txt"
usage () {
    echo "USAGE: $0 --dkube-version 3.1.0.3 [--image-list images.txt] [--images images.tar or /path/to/images/directory] [--registry my.registry.com:5000]"
    echo "  [--dkube-version version] version of dkube of which images have to be uploaded."
    echo "  [-m|--minimal] Optional. Flag to upload images for minimal version of dkube."
    echo "  [-l|--image-list path] Optional. Text file with list of images; one image per line."
    echo "  [-i|--images path] Optional. tar/tar.gz file containing source images to upload or path to directory containing multiple image tar files."
    echo "  [-r|--registry registry:port] Optional. target private registry:port."
    echo "  [-h|--help] Usage message"
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
	--dkube-version)
	dkube_version="$2"
	shift # past argument
	shift # past value
	;;
	-r|--registry)
	reg="$2"
	shift # past argument
	shift # past value
	;;
	-l|--image-list)
	image_list="$2"
	shift # past argument
	shift # past value
	;;
	-i|--images)
	images="$2"
	shift # past argument
	shift # past value
	;;
	-m|--minimal)
	minimal="true"
	shift
	;;
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
if [[ -z $dkube_version ]]; then
	echo "Required: --dkube-version"
	usage
	exit 1
fi
if [[ $help ]]; then
    usage
    exit 0
fi

list="./images/$dkube_version.txt"
if [[ ! -z $image_list ]]; then
	list=$image_list
fi

echo Logs available at: $log_file 
echo Metrics available at: $metrics_file 

if [[ ! -z $image_list && ! -z $images ]]; then
	list=$image_list
	if [ ! -d $images ]; then
	    if [ -f $images ]; then
		if [ [ $images == *.tar ] || [ $images == *.tar.gz ] ]; then
			echo "Loading images from ${images} to local docker..."
			sudo docker load --input ${images}
		else
			echo "Error: Path $images is neither a .tar/.tar.gz file, nor a directory. Check --help for usage."
			exit 1
		fi
	    fi
    	else
	    for f in $images/*
	    do
	    	sudo docker load --input ${f} 
	    done
	fi 
	cat $list | parallel --bar -P 5  ./scripts/push.sh
else
	echo "Uploading non-datascience images..." | tee -a $log_file
	if [[ $minimal ]]; then
		./scripts/parallel-pull-push.sh images/$dkube_version-non-ds-minimal.txt $metrics_file $log_file
	else
		./scripts/parallel-pull-push.sh images/$dkube_version-non-ds.txt $metrics_file $log_file
	fi
	echo "Done uploading non-datascience images!" | tee -a $log_file
	echo "This script will upload datascience images in the background..." | tee -a $log_file
	echo "Follow progress of datascience images using this command: tail -f $log_file"
	echo "Meanwhile, you may proceed with DKube installation."
	nohup ./scripts/parallel-pull-push.sh images/$dkube_version-ds.txt $metrics_file $log_file >> /dev/null 2>&1 &
fi
