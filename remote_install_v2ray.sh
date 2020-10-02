#!/bin/sh
ssh-keygen -f "/home/alpha/.ssh/known_hosts" -R "149.28.60.133"
ssh -o StrictHostKeyChecking=no root@149.28.60.133 "sh " < ./v2ray.sh
