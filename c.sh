#./b.sh 1>out.txt 2> err.txt 
#echo "Inside c.sh!!"
#echo hello
#echo world
#rm time.txt
./cleanup.sh
echo -------
echo PARALLEL >> time.txt
START=$(date +%s.%N)
echo START time: $START >> time.txt
cat images/test.txt | xargs -n 1 -P 5 ./pull-push.sh 
END=$(date +%s.%N)
echo END time: $END >> time.txt
DIFF=$(echo "$END - $START" | bc)
echo DIFF time: $DIFF >> time.txt
echo -------
./cleanup.sh
#echo SERIAL >> time.txt
#START=$(date +%s.%N)
#echo START time: $START >> time.txt
#cat images/test.txt | xargs -n 1 ./pull-push.sh 
#END=$(date +%s.%N)
#echo END time: $END >> time.txt
#DIFF=$(echo "$END - $START" | bc)
#echo DIFF time: $DIFF >> time.txt
