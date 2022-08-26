#!/usr/bin/bash

sudo dnf install -y npm
sudo npm i -g n
export N_NODE_MIRROR=https://npm.taobao.org/mirrors/node
sudo n stable
