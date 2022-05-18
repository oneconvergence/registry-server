#!/bin/bash

reg="registry-server.dkube.io:443"
image=$2
log_file=$1

wget -q --spider --timeout 1 --tries 1 http://google.com
if [ $? -ne 0 ]; then
       offline_error="Upload failed due to loss of internet!\nPlease enable internet and rerun upload.sh script to finish uploading pending images."
       if [[ "$(tail -1 $log_file)" != "Please enable internet and rerun upload.sh script to finish uploading pending images." ]]; then
               echo -e $offline_error | tee -a $log_file
       fi
       exit 1
fi

echo "Pulling image: $image..." >> $log_file 
sudo docker pull "$image" 2>> $log_file 1>/dev/null 

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
sudo docker push $reg/$newimage 2>> $log_file 1>/dev/null
if [ $? -eq 0 ]; then
	echo "Pushed image: $reg/$newimage!" >> $log_file
else
	echo "Failed to push image: $reg/$newimage" >> $log_file
fi
