# local-network
OBADA network simulation to run locally

1. IPSF for metadata
2. Fauset to obtain tokens
3. OBD token name - aobd / atto obd 1 power 18. **OBT**
4. Nft creation
5. Nft execution from rd project

# Installation

For running this playground please use Ubuntu 20.04

## Install required packages

```bash
sudo apt install docker.io docker-compose make
```

## Clone the project

```bash
git clone -b develop git@github.com:obada-foundation/local-network-playground
cd local-network-playground
```

## Configure and run OBADA network

```
make install
```

## Network components

| Component name        | Description                                                  | Browser access URL                      |
| --------------------- | ------------------------------------------------------------ | --------------------------------------- |
| Reference design (Go) | The application that inreracts with OBADA network and creates NFTs. | http://localhost:8585                   |
| IPFS                  | Interplanetary filesystem node is used to store NFT metadata in a decentrilized way. |                                         |
| Application Node      | Node that do not participate in validation but it used by applications such as "Reference design" and "Block explorer" | http://localhost:8545                   |
| Block explorer        | UI tool that allows to search records in blockchain by block id, transaction and address. Shows blockchain updates in realtime. | http://localhost                        |
| Validation node       | The core of the system. The network of validation nodes creates "OBADA Network" | Does not allow access from the browser. |

