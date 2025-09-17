# remove old version if exists
sudo rm -f /usr/local/bin/telepresence

# 1. Download the latest Telepresence binary:
sudo curl -fL https://github.com/telepresenceio/telepresence/releases/latest/download/telepresence-linux-amd64 -o /usr/local/bin/telepresence

# 2. Make the binary executable:
sudo chmod a+x /usr/local/bin/telepresence