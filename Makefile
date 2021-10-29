SHELL := /bin/bash
.DEFAULT_GOAL := run

ifndef INITIALIZE_TIMEOUT
	override INITIALIZE_TIMEOUT = 10
endif

build_contracts:
	docker build -t obada/contracts -f docker/contracts/Dockerfile .

install: create_folders_and_files pull_containers initialize_network configure_application_node deploy_contracts run_application

KEY=$$(docker exec -it obs-node sh -c "ethermintd keys unsafe-export-eth-key node1 --keyring-backend test" | cut -c1-64)
deploy_contracts:
	docker exec -t contracts sh -c "sed -i 's/OBADA_NODE_PRIVATE_KEY/${KEY}/g' truffle-config.js"
	docker exec -it contracts sh -c "npm run build"
	docker exec -it contracts sh -c "npm run deploy"

install_contracts: clone_contracts install_deps

install_deps:
	cd contracts && npm install

clone_contracts:
	git clone git@github.com:obada-foundation/contracts

pull_containers:
	docker-compose pull

create_folders_and_files:
	mkdir -p  nodes/node/ethermintd
	touch .env

initialize_network:
	docker-compose up testnet-init
	docker-compose up -d contracts ipfs node tradeloop-node obs-node usody-node ascidi-node explorer
	sleep $(INITIALIZE_TIMEOUT)

PEERS=$$(cat nodes/node0/ethermintd/config/config.toml | grep 'persistent_peers =')
configure_application_node:
	cp nodes/node0/ethermintd/config/genesis.json nodes/node/ethermintd/config
	docker exec -it node sh -c "sed -i 's/persistent_peers = \"\"/${PEERS}/' /home/ethermint/.ethermintd/config/config.toml"
	docker restart node

PRIVATE_KEY=$$(docker exec -it obs-node sh -c "ethermintd keys unsafe-export-eth-key node1 --keyring-backend test" | cut -c1-64)
run_application:
	docker exec -it contracts sh -c "npm run genenv"
	echo "PRIVATE_KEY=${PRIVATE_KEY}" >> .env
	docker-compose --env-file .env up -d --force-recreate rdgo

run:
	docker-compose up -d

clean:
	docker-compose down
	rm -rf ipfs
	rm -rf nodes
