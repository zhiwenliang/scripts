#!/bin/bash

images=$(docker images | awk '{printf "%s:%s ",$1,$2}')
read -a image_arr <<< "$images"
image_arr=($images)
unset image_arr[0]
for i in ${image_arr[@]}
do
echo "Start updating $i ..."
docker pull $i
echo "------------------------------"
done
