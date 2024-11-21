#!/bin/bash

# Fungsi untuk mencetak teks dengan warna
green_echo() {
    echo -e "\e[32m$1\e[0m"
}

blue_echo() {
    echo -e "\e[34m$1\e[0m"
}

# Fungsi untuk membuat file .env
green_echo "Membuat file .env..."
echo "Masukkan password Eigenlayer yang akan digunakan untuk NODE_ECDSA_KEY_PASSWORD: "
read -s PASSWORD

# Menulis ke file .env
cat > .env <<EOL
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
NODE_ECDSA_KEY_PASSWORD=$PASSWORD
EOL

blue_echo "File .env telah berhasil dibuat."

# Menanyakan port yang ingin digunakan, dengan pengaturan default
green_echo "Sekarang kita akan mengatur port yang digunakan untuk layanan."
green_echo "Jika Anda ingin menggunakan port default, cukup tekan ENTER."

# Default ports
DEFAULT_FLINK_JOB_PORT=8081
DEFAULT_PROMETHEUS_PORT=9091
DEFAULT_CHAINBASE_NODE_PORT=8080
DEFAULT_METRICS_PORT=9092

# Menanyakan port dengan fallback ke default jika tidak diisi
echo "Masukkan port untuk Flink Job Manager (default: $DEFAULT_FLINK_JOB_PORT): "
read FLINK_JOB_PORT
FLINK_JOB_PORT=${FLINK_JOB_PORT:-$DEFAULT_FLINK_JOB_PORT}

echo "Masukkan port untuk Prometheus (default: $DEFAULT_PROMETHEUS_PORT): "
read PROMETHEUS_PORT
PROMETHEUS_PORT=${PROMETHEUS_PORT:-$DEFAULT_PROMETHEUS_PORT}

echo "Masukkan port untuk Chainbase Node (default: $DEFAULT_CHAINBASE_NODE_PORT): "
read CHAINBASE_NODE_PORT
CHAINBASE_NODE_PORT=${CHAINBASE_NODE_PORT:-$DEFAULT_CHAINBASE_NODE_PORT}

echo "Masukkan port untuk Metrics (default: $DEFAULT_METRICS_PORT): "
read METRICS_PORT
METRICS_PORT=${METRICS_PORT:-$DEFAULT_METRICS_PORT}

blue_echo "Membuat file docker-compose.yml..."

# Membuat atau mengupdate file docker-compose.yml
cat > docker-compose.yml <<EOL
version: '3'
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
      - "$PROMETHEUS_PORT:9090"
    networks:
      - chainbase
    restart: unless-stopped

  flink-jobmanager:
    image: \${FLINK_JOBMANAGER_IMAGE}
    container_name: \${FLINK_JOBMANAGER_NAME}
    env_file:
      - .env
    ports:
      - "$FLINK_JOB_PORT:8081"
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
      - "$CHAINBASE_NODE_PORT:8080"
      - "$METRICS_PORT:9092"
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

blue_echo "File docker-compose.yml telah berhasil dibuat."
