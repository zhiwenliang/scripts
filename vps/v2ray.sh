#!/bin/bash

apt install unzip iptables iptables-persistent -y
curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh &&
bash install-release.sh &&
curl -LO https://raw.githubusercontent.com/zhiwenliang/scripts/main/vps/config.json &&
mv ./config.json /usr/local/etc/v2ray/config.json && 
apt-get update &&
iptables -I INPUT -p tcp --dport 6666 -j ACCEPT &&
iptables-save &&
netfilter-persistent save &&
netfilter-persistent reload &&  
systemctl enable v2ray && 
systemctl restart v2ray
