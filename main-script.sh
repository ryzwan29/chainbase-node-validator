#!/bin/bash

# Fungsi untuk membuat dan memperbarui file .env
create_and_update_env() {
    # Nama file .env
    ENV_FILE=".env"

    # Memeriksa apakah file .env sudah ada
    if [ -f "$ENV_FILE" ]; then
        echo -e "\033[1;33mFile .env already exists. You can update the password.\033[0m"
    else
        echo -e "\033[1;32mFile .env not found. Creating a new file...\033[0m"
        
        # Membuat file .env baru dengan nilai default
        cat <<EOL > $ENV_FILE
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
NODE_ECDSA_KEY_PASSWORD=***123ABCabc123***
EOL
        echo -e "\033[1;32mNew .env file created!\033[0m"
    fi

    # Meminta pengguna untuk memasukkan password yang mereka buat sebelumnya
    echo -e "\033[1;34mPlease enter your Eigenlayer wallet password (the one you created earlier):\033[0m"
    read -s password

    # Mengganti nilai NODE_ECDSA_KEY_PASSWORD di dalam file .env
    sed -i "s/^NODE_ECDSA_KEY_PASSWORD=.*$/NODE_ECDSA_KEY_PASSWORD=$password/" $ENV_FILE

    echo -e "\033[1;32mNODE_ECDSA_KEY_PASSWORD has been updated successfully in .env!\033[0m"
}

# Memanggil fungsi untuk membuat dan memperbarui file .env
create_and_update_env
