#!/bin/bash

# Get the latest version of Go available
latest_version_curl=$(curl -sL https://golang.org/VERSION?m=text)
latest_version=$(echo $latest_version_curl | cut -d' ' -f1)

echo "latest version is $latest_version"

upgrade() {
    # Download latest go version
    echo "Download latest go version"
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
}

# Check if Go is installed on the system
if ! command -v go &> /dev/null; then
    echo "Go is not installed on your system. Install it first."
    upgrade
    exit 1
fi

# Get the current version of Go installed on the system
current_version=$(go version | awk '{print $3}')

echo "current version is $current_version"

# Check if the current version is the same as the latest version
if [ "$current_version" == "$latest_version" ]; then
    echo "Go is already up to date."
    exit 0
else
    # Remove existing go
    echo "Remove existing go"
    sudo rm -rf /usr/local/go
    upgrade
fi
