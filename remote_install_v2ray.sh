#!/bin/sh
ip=$(echo $1|awk '{split($0,a,"@");print a[2]}')
ssh-keygen -f "/home/alpha/.ssh/known_hosts" -R "$ip"
ssh -o StrictHostKeyChecking=no $1 "sh " < ./v2ray.sh
