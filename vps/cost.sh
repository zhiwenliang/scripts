#!/bin/sh
result=$(ssh -o stricthostkeychecking=no $1 "cat /proc/uptime")
# hour
h=$(echo $result|awk '{split(($1/3600),a,".");print a[1]}')
# minute
m=$(echo $result|awk '{split(($1/60%60),a,".");print a[1]}')

# cost
cost=$(echo $h|awk '{print 0.01+substr(($1+1)*3.5/672,1,4)}')

echo "running time: $h:$m"
echo "current cost: \$$cost"
