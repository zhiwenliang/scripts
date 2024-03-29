#!/usr/bin/bash

# sdk
# set rust environment
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# set go environment

# install sdkman
curl -s "https://get.sdkman.io" | bash

# use sdkman install maven, mvnd, gradle
sdk install maven
sdk install mvnd
sdk install gradle

# dnf install some packages
sudo dnf install npm zip unzip gcc g++ gdb make cmake vim meld wireshark git libreoffice curl calibre thunderbird libre-office qemu cups
sudo npm install -g n
sudo n stable

# install solidity compiler
sudo npm install -g solc

# install vscode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf upgrade
sudo dnf install code

# install chrome
curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
sudo dnf install google-chrome-stable_current_x86_64.rpm

# set git(user.name,user.email,core.autocrlf,init.defaultBranch)
git config --global user.name zhiwen
git config --global user.email zhiwen_liang@outlook.com
git config --global core.autocrlf=false
git config --global init.defaultBranch=main

# download telegram, tor, postman, janetfilter-all

# install jetbrain-toolbox
# install idea, andriod studio, datagrip, clion, pycharm, goland
