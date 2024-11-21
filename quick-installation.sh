#!/bin/bash

# Pastikan script dijalankan sebagai root atau dengan sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[0;31mThis script must be run as root\033[0m" 
    exit 1
fi

# Langkah 1: Memperbarui dan Menginstal Dependensi
echo -e "\033[0;32mUpdating and Installing dependencies...\033[0m"
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 expect

# Install Docker
echo -e "\033[0;32mAdd repository and Installing Docker...\033[0m"
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# Install docker latest version
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin -y 

# Install Go
echo -e "\033[0;32mInstalling Go...\033[0m"
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
source ~/.bash_profile
go version

# Langkah 2: Install EigenLayer CLI
echo -e "\033[0;32mInstalling EigenLayer CLI...\033[0m"
curl -sSfL https://raw.githubusercontent.com/layr-labs/eigenlayer-cli/master/scripts/install.sh | sh -s
export PATH=$PATH:~/bin
eigenlayer --version

# Langkah 3: Clone Repo Chainbase AVS
echo -e "\033[0;32mCloning Chainbase AVS repository...\033[0m"
git clone https://github.com/ryzwan29/chainbase-avs-setup
cd chainbase-avs-setup/holesky
