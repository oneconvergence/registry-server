#!/bin/bash
images=""
reg="registry-server.dkube.io:443"
list=""
dkube_version=""
usage () {
    echo "USAGE: $0 --dkube-version 3.1.0.3 [--image-list images.txt] [--images images.tar or /path/to/images/directory] [--registry my.registry.com:5000]"
    echo "  [--dkube-version version] version of dkube of which images have to be uploaded."
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

if [[ ! -z $images ]]; then
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
fi

while read -r image; do
	[ -z "${image}" ] && continue
	if [[ -z $images ]]; then
		sudo docker pull "$image"
	fi
	newimage=$image
	img=$image
	if [[ $img == *"@sha256:"* ]]; then
		IFS='@'
		#Read the split words into an array based on comma delimiter
		read -a strarr <<< $img

		imagename=${strarr[0]}
		if [[ $imagename == *":"* ]]; then
			newimage="$imagename-${img: -6}"
		else
			newimage="$imagename:${img: -6}"
		fi
	fi
	sudo docker tag "$image" $reg/$newimage
	sudo docker push $reg/$newimage
done < $list
