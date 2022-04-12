#!/bin/bash

reg="registry-server.dkube.io:443"
image=$1
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
sudo docker push --quiet $reg/$newimage
