#!/bin/bash

apt install unzip iptables iptables-persistent -y
iptables -I INPUT -p tcp --dport 6666 -j ACCEPT &&
iptables-save &&
netfilter-persistent save &&
netfilter-persistent reload 
bash <(curl -s -L https://git.io/v2ray.sh)
