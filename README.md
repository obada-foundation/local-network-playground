# local-network
OBADA network simulation to run locally

1. IPSF for metadata
2. Fauset to obtain tokens
3. OBD token name - aobd / atto obd 1 power 18. **OBT**
4. Nft creation
5. Nft execution from rd project

# Setup

## Setup validation network

```
docker-compose up -d testnet-init
```

## Run the network
```sh
docker-compose up -d
```

## Attach new node to the network

Copy genesis from the master file

```sh
cp nodes/node0/ethermintd/config/genesis.json nodes/node/ethermintd/config
```

Copy peers from the masterfile

```sh
PEERS=$(cat nodes/node0/ethermintd/config/config.toml | grep 'persistent_peers =')
sed -i '' "s/persistent_peers = \"\"/$PEERS/" ./nodes/node/ethermintd/config/config.toml
```

Restart node

```sh
docker restart node

```

## Deploy smart contract

Deploy Remix, Truffe etc

## Export keys

```sh

docker exec -it node0 sh -c ""
```
