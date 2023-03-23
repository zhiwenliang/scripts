#!/bin/bash

# Remove existing go
echo "Remove existing go"
sudo rm -rf /usr/local/go

# Download latest go version
echo "Download latest go version"
latest_version=$(curl -L "https://golang.org/VERSION?m=text")
curl -O "https://dl.google.com/go/$latest_version.linux-amd64.tar.gz"

# Extract the package
echo "Extract the package"
sudo tar -C /tmp -xzf $latest_version.linux-amd64.tar.gz
sudo mv /tmp/go /usr/local

# Set environment variables
# echo 'export GOPATH=$HOME/go' >> ~/.bashrc
# echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin' >> ~/.bashrc
# 
# source ~/.bashrc

# Verify the installation
echo "Verify the installation"
go version

# Remove downloaded file
echo "Remove downloaded file"
rm $latest_version.linux-amd64.tar.gz
