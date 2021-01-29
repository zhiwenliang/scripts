#!/bin/sh
dir=$(cd "$(dirname "$0")";pwd)
ssh-keygen -f "/home/alpha/.ssh/known_hosts" -R "149.28.235.28"
ssh -o StrictHostKeyChecking=no root@149.28.235.28 "sh " < $dir/v2ray.sh
