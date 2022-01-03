#!/bin/bash

URL="http://ftp.lfs-matrix.net/pub/lfs/lfs-packages/8.4/"

echo "Read line by line"
if [ -z ${1} ]; then
    echo "No arg1"
    exit 1
fi    
if [ -z ${2} ]; then
    echo "No arg2"
    exit 1
fi

echo ${1}
FILE=${1}
FILE_OUT=${2}

echo "" > ${FILE_OUT}


while IFS= read -r line
do
    # echo ${line}
    filename=${line##*/}
    if [ ! -z ${filename} ]; then
	echo ${filename}
	echo "${URL}${filename}" >> ${FILE_OUT}
    fi

done < ${FILE}


echo -e "\n-- Done --\n"
