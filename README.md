# local-network
OBADA network simulation to run locally

1. IPSF for metadata
2. Fauset to obtain tokens
3. OBD token name - aobd / atto obd 1 power 18. **OBT**
4. Nft creation
5. Nft execution from reference design application

# Installation

For running this playground please use **Ubuntu 20.04**. Please check [this video](https://drive.google.com/file/d/1SczfTTY3blGGh-48BafwRX1UqJS6G-1R/view?usp=sharing) if you need more installation details.

## Install required packages

```bash
sudo apt install docker.io docker-compose make
```

## Configure SSH key for cloning project from GitHub

Check [this](https://www.inmotionhosting.com/support/server/ssh/how-to-add-ssh-keys-to-your-github-account/) tutorial.

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

| Component name        | Description                                                  | Browser access URL                                           |
| --------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Demo Wallet | The application that interacts with OBADA application node, creates NFTs and allows to transfer OBD. | http://localhost:8090                                        |
| IPFS                  | Interplanetary filesystem node is used to store NFT metadata in a decentralized way. | http://localhost:8084 ([Example url](http://bafybeidl5jj24us4huf6wvyijbiwzjge3uwkgvtl7sbwoe64mz5dnam3sq.ipfs.localhost:8084/)) |
| Application Node      | Node that do not participate in validation but it used by applications such as "Block explorer" and "Demo Wallet" | http://localhost:26656-26657 |
| Query API             | The list of all available REST endpoints is available as a Swagger specification file. | http://localhost:1317 |
| Block explorer        | UI tool that allows to search records in blockchain by block id, transaction and address. Shows blockchain updates in realtime. | http://localhost:3000 |
| Validation node       | The core of the system. The network of validation nodes creates "OBADA Network" | Does not allow access from the browser.                      |
| Trust Anchor          |  -  | http://localhost:8071  |

## Installation troubleshooting

### Container is restarting, wait until the container is running
This error can mean that you have a slow docker environment, you can increase **INITIALIZE_TIMEOUT** (default value is 10 seconds). After failed installation run:
```bash
sudo make clean
INITIALIZE_TIMEOUT=15 make install
```

