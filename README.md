```
source <(curl -s https://raw.githubusercontent.com/ryzwan29/chainbase-node-validator/main/script/quick-installation.sh)
```
```
source <(curl -s https://raw.githubusercontent.com/ryzwan29/chainbase-node-validator/main/script/wallet.sh)
```
```
eigenlayer operator config create
```
operator address: Your Eigenlayer ETH address
earnings address: press Enter
ETH rpc url     : https://ethereum-holesky-rpc.publicnode.com
network         : holesky
signer type     : local_keystore
ecdsa key path  : /root/.eigenlayer/operator_keys/opr.ecdsa.key.json
```
nano metadata.json
```
example : [https://github.com/ryzwan29/chainbase-node-validator/blob/main/metadata.json](https://github.com/ryzwan29/chainbase-node-validator/blob/main/metadata.json)
```
nano operator.yaml
```
Add your metadata.json raw url in github in front of ***metadata-url***
```
eigenlayer operator register operator.yaml
eigenlayer operator status operator.yaml
```
```
source <(curl -s https://raw.githubusercontent.com/ryzwan29/chainbase-node-validator/main/script/main-script.sh)
```
```
source .env && mkdir -pv ${EIGENLAYER_HOME} ${CHAINBASE_AVS_HOME} ${NODE_LOG_PATH_HOST}
chmod +x ./chainbase-avs.sh
./chainbase-avs.sh register
./chainbase-avs.sh run
docker compose logs chainbase-node -f
export PATH=$PATH:~/bin
eigenlayer operator status operator.yaml
curl -i localhost:8080/eigen/node/health
```

