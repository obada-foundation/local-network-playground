SHELL := /bin/bash
.DEFAULT_GOAL := run

ifndef INITIALIZE_TIMEOUT
	override INITIALIZE_TIMEOUT = 10
endif

build_contracts:
	docker build -t obada/contracts -f docker/contracts/Dockerfile .

install: create_folders_and_files pull_containers initialize_network configure_application_node run_application

install_contracts: clone_contracts install_deps

install_deps:
	cd contracts && npm install

pull_containers:
	#docker-compose pull

create_folders_and_files:
	mkdir -p  nodes/node/cored
	touch .env

initialize_network:
	docker-compose up testnet-init
	docker-compose up -d ipfs obs-node
	sleep $(INITIALIZE_TIMEOUT)

PEERS=$$(cat nodes/obs-node/cored/config/config.toml | grep 'persistent_peers =')
configure_application_node:
	mkdir nodes/node/cored/config
	cp nodes/obs-node/cored/config/genesis.json nodes/node/cored/config
	docker-compose up -d node
	sleep 5
	docker exec -it node sh -c "sed -i 's/persistent_peers = \"\"/${PEERS}/' /home/cored/.core/config/config.toml"
	docker restart node

PRIVATE_KEY=$$(docker exec -it obs-node sh -c "cored keys unsafe-export-eth-key node1 --keyring-backend test" | cut -c1-64)
run_application:
	docker-compose --env-file .env up -d --force-recreate rdgo trust-anchor

run:
	docker-compose up -d

clean:
	docker-compose down
	rm -rf ipfs
	rm -rf nodes
