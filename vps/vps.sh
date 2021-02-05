#!/bin/bash

# remote install v2ray on VPS
function install_v2ray() {
    ssh-keygen -f "/home/alpha/.ssh/known_hosts" -R $1
    ssh -o StrictHostKeyChecking=no root@$1 "curl -L https://raw.githubusercontent.com/zhiwenliang/scripts/main/vps/v2ray.sh > /root/v2ray.sh;bash /root/v2ray.sh"
}

# get cost of VPS
function cost() {
    result=$(ssh -o stricthostkeychecking=no root@$1 "cat /proc/uptime")
    # hour
    h=$(echo $result | awk '{split(($1/3600),a,".");print a[1]}')
    # minute
    m=$(echo $result | awk '{split(($1/60%60),a,".");print a[1]}')

    # cost
    cost=$(echo $h | awk '{print 0.01+substr(($1+1)*3.5/672,1,4)}')

    echo "running time: $h:$m"
    echo "current cost: \$$cost"
}

function main() {
    while getopts "i:c:" optname; do
        case $optname in
        "i")
            install_v2ray $OPTARG
            ;;
        "c")
            cost $OPTARG
            ;;
        *)
            echo "Unknown error while processing options"
            exit 1
            ;;
        esac
    done
}

main "$@"