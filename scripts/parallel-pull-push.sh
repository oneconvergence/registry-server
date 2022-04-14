#!/bin/bash

list=$1
metrics_file=$2
log_file=$3 

echo Pulling and pushing the images listed in: $list >> $log_file
echo ----------------METRICS: $list -------------- >> $metrics_file
START=$(date +%s.%N)
echo START time: $START >> $metrics_file
echo START size: >> $metrics_file
df -h >> $metrics_file
cat $list | parallel --bar -P 5  ./scripts/pull-push.sh $log_file
END=$(date +%s.%N)
echo END time: $END >> $metrics_file
echo END size: >>  $metrics_file
df -h >> $metrics_file
DIFF=$(echo "$END - $START" | bc)
echo DIFF time: $DIFF >>  $metrics_file
echo Done pulling and pushing images from: $list >> $log_file
echo Done pulling and pushing images from: $list >> $metrics_file
echo -------------------------------------------------------- >> $metrics_file
