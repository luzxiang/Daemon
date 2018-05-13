#!/bin/bash

path=${1}
slp=${2}
#check the path is valid
if [[ ! -d "$path" ]];then
    echo No such directory: $path
    exit 1
fi
#check the args is not equal 0
if [[ $slp < 1 ]];then
    slp=1
fi
#print the result 
while :
do
    n=`find ${path} -type f | wc -l`
#    clear
    echo "------<find "'$path'" -type f | wc -l>------"
    echo '$path: '$path
    echo "[`date "+%T"`] wc = ${n}"
    echo "----------------------------------------"
    sleep $slp
done
