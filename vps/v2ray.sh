#!/bin/bash

apt install unzip -y
curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh &&
bash install-release.sh &&
wget https://github.com/v2fly/v2ray-core/releases/download/v4.39.2/v2ray-linux-64.zip &&
unzip ~/v2ray-linux-64.zip "vpoint_vmess_freedom.json" &&
sed -i "3s/.*/\"port\": 12345,/g" ~/vpoint_vmess_freedom.json &&
sed -i "8s/.*/\"id\": \"e15a7a6f-8b5c-43d0-958a-11fe1dcb79ea\",/g" ~/vpoint_vmess_freedom.json &&
rm -rf /usr/local/etc/v2ray/* &&
mv ~/vpoint_vmess_freedom.json /usr/local/etc/v2ray/config.json && 
systemctl enable v2ray && systemctl restart v2ray
