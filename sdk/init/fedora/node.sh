#!/usr/bin/bash

dnf install -y npm
npm i -g n
export N_NODE_MIRROR=https://npm.taobao.org/mirrors/node
n stable
