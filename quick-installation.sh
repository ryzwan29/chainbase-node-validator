#!/bin/bash

# Pastikan script dijalankan sebagai root atau dengan sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[0;31mThis script must be run as root\033[0m" 
    exit 1
fi

# Langkah 1: Memperbarui dan Menginstal Dependensi
echo -e "\033[0;32mUpdating and Installing dependencies...\033[0m"
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4

# Install Docker
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
git clone https://github.com/chainbase-labs/chainbase-avs-setup
cd chainbase-avs-setup/holesky

# Langkah 4: Membuat Wallet EigenLayer
echo -e "\033[0;32mCreating EigenLayer Wallet...\033[0m"
eigenlayer operator keys create --key-type ecdsa opr
echo -e "\033[0;32mSave your wallet private key securely!\033[0m"

# Optional: Import old key
# echo -e "\033[0;32mImporting old key...\033[0m"
# eigenlayer operator keys import --key-type ecdsa opr PRIVATEKEY

# Langkah 5: Mendaftarkan Operator
echo -e "\033[0;32mConfiguring and Registering Operator...\033[0m"
eigenlayer operator config create

# Langkah 6: Edit metadata.json
echo -e "\033[0;32mEditing metadata.json...\033[0m"
nano metadata.json

# Langkah 7: Menjalankan EigenLayer Holesky Node
echo -e "\033[0;32mRegistering and Running Holesky Node...\033[0m"
eigenlayer operator register operator.yaml
eigenlayer operator status operator.yaml

# Langkah 8: Konfigurasi Chainbase AVS
echo -e "\033[0;32mCreating .env file for Chainbase AVS...\033[0m"
cat <<EOL > .env
# Chainbase AVS Image
MAIN_SERVICE_IMAGE=repository.chainbase.com/network/chainbase-node:testnet-v0.1.7
FLINK_TASKMANAGER_IMAGE=flink:latest
FLINK_JOBMANAGER_IMAGE=flink:latest
PROMETHEUS_IMAGE=prom/prometheus:latest

MAIN_SERVICE_NAME=chainbase-node
FLINK_TASKMANAGER_NAME=flink-taskmanager
FLINK_JOBMANAGER_NAME=flink-jobmanager
PROMETHEUS_NAME=prometheus

# FLINK CONFIG
FLINK_CONNECT_ADDRESS=flink-jobmanager
FLINK_JOBMANAGER_PORT=8081
NODE_PROMETHEUS_PORT=9091
PROMETHEUS_CONFIG_PATH=./prometheus.yml

# Chainbase AVS mounted locations
NODE_APP_PORT=8080
NODE_ECDSA_KEY_FILE=/app/operator_keys/ecdsa_key.json
NODE_LOG_DIR=/app/logs

# Node logs configs
NODE_LOG_LEVEL=debug
NODE_LOG_FORMAT=text

# Metrics specific configs
NODE_ENABLE_METRICS=true
NODE_METRICS_PORT=9092

# holesky smart contracts
AVS_CONTRACT_ADDRESS=0x5E78eFF26480A75E06cCdABe88Eb522D4D8e1C9d
AVS_DIR_CONTRACT_ADDRESS=0x055733000064333CaDDbC92763c58BF0192fFeBf

###############################################################################
####### TODO: Operators please update below values for your node ##############
###############################################################################
# TODO: Operators need to point this to a working chain rpc
NODE_CHAIN_RPC=https://rpc.ankr.com/eth_holesky
NODE_CHAIN_ID=17000

# TODO: Operators need to update this to their own paths
USER_HOME=\$HOME
EIGENLAYER_HOME=\${USER_HOME}/.eigenlayer
CHAINBASE_AVS_HOME=\${EIGENLAYER_HOME}/chainbase/holesky

NODE_LOG_PATH_HOST=\${CHAINBASE_AVS_HOME}/logs

# TODO: Operators need to update this to their own keys
NODE_ECDSA_KEY_FILE_HOST=\${EIGENLAYER_HOME}/operator_keys/opr.ecdsa.key.json

# TODO: Operators need to add password to decrypt the above keys
# If you have some special characters in password, make sure to use single quotes
NODE_ECDSA_KEY_PASSWORD=***123ABCabc123***
EOL

echo -e "\033[0;32mCreating docker-compose.yml file...\033[0m"
cat <<EOL > docker-compose.yml
services:
  prometheus:
    image: \${PROMETHEUS_IMAGE}
    container_name: \${PROMETHEUS_NAME}
    env_file:
      - .env
    volumes:
      - "\${PROMETHEUS_CONFIG_PATH}:/etc/prometheus/prometheus.yml"
    command: 
      - "--enable-feature=expand-external-labels"
      - "--config.file=/etc/prometheus/prometheus.yml"
    ports:
      - "9091:9090"
    networks:
      - chainbase
    restart: unless-stopped

  flink-jobmanager:
    image: \${FLINK_JOBMANAGER_IMAGE}
    container_name: \${FLINK_JOBMANAGER_NAME}
    env_file:
      - .env
    ports:
      - "8081:8081"
    command: jobmanager
    networks:
      - chainbase
    restart: unless-stopped

  flink-taskmanager:
    image: \${FLINK_JOBMANAGER_IMAGE}
    container_name: \${FLINK_TASKMANAGER_NAME}
    env_file:
      - .env
    depends_on:
      - flink-jobmanager
    command: taskmanager
    networks:
      - chainbase
    restart: unless-stopped

  chainbase-node:
    image: \${MAIN_SERVICE_IMAGE}
    container_name: \${MAIN_SERVICE_NAME}
    command: ["run"]
    env_file:
      - .env
    ports:
      - "8080:8080"
      - "9092:9092"
    volumes:
      - "\${NODE_ECDSA_KEY_FILE_HOST:-./opr.ecdsa.key.json}:\${NODE_ECDSA_KEY_FILE}"
      - "\${NODE_LOG_PATH_HOST}:\${NODE_LOG_DIR}:rw"
    depends_on:
      - prometheus
      - flink-jobmanager
      - flink-taskmanager
    networks:
      - chainbase
    restart: unless-stopped

networks:
  chainbase:
    driver: bridge
EOL

# Langkah 9: Membuat folder untuk docker
echo -e "\033[0;32mCreating folders for Docker...\033[0m"
source .env && mkdir -pv \${EIGENLAYER_HOME} \${CHAINBASE_AVS_HOME} \${NODE_LOG_PATH_HOST}

# Langkah 10: Menjalankan Chainbase AVS
echo -e "\033[0;32mRunning Chainbase AVS...\033[0m"
chmod +x ./chainbase-avs.sh
./chainbase-avs.sh register
./chainbase-avs.sh run

# Langkah 11: Memeriksa Kesehatan AVS
echo -e "\033[0;32mChecking Chainbase Node Logs...\033[0m"
docker compose logs chainbase-node -f
