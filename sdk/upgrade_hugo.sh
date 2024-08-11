#! /usr/bin/bash
latest_version=$(curl -sL https://github.com/gohugoio/hugo/releases/latest | grep -oP '(?<=href="/gohugoio/hugo/releases/tag/v)[^"]*')
upgrade() {
    # get download url and download
    file_name="hugo_extended_${latest_version}_linux-amd64.tar.gz"
    download_url="https://github.com/gohugoio/hugo/releases/download/v${latest_version}/${file_name}"
    echo "Download url is：$download_url"
    curl -LO $download_url

    # Extract the package
    echo "Extract the package"
    sudo tar -C /tmp -xzf $file_name hugo
    sudo mv /tmp/hugo /usr/local/bin/

    # Remove downloaded file
    echo "Remove downloaded file"
    rm $file_name

    hugo version
}

# Check if Go is installed on the system
if ! command -v hugo &> /dev/null; then
    echo "Hugo is not installed on your system. Install it first."
    upgrade
    exit 1
fi

# Get the current version of Go installed on the system
current_version=$(hugo version | awk '{print $2}' | awk -F'-' '{print $1}' | awk -F'v' '{print $2}')


# Check if the current version is same as the latest version
echo "current_version: $current_version; latest_version: $latest_version"
if [ "$current_version" == "$latest_version" ]; then
    echo "Hugo is already up to date."
    exit 0
else
    # upgrade
    upgrade
fi

