SHELL := /bin/bash
.DEFAULT_GOAL := run

ifndef INITIALIZE_TIMEOUT
	override INITIALIZE_TIMEOUT = 10
endif

install: create_folders_and_files pull_containers initialize_network configure_application_node run_application explorer/run explorer/database/migrate explorer/bdjuno/genesis  explorer/bdjuno/run explorer/hasura/run explorer/hasura/cli

pull_containers:
	#docker-compose pull

create_folders_and_files:
	mkdir -p  nodes/node/cored
	touch .env

initialize_network:
	docker-compose up testnet-init
	docker-compose up -d ipfs tradeloop-node obs-node usody-node ascidi-node
	sleep $(INITIALIZE_TIMEOUT)

PEERS=$$(cat nodes/node0/cored/config/config.toml | grep 'persistent_peers =')
configure_application_node:
	mkdir -p nodes/node/cored/config
	cp nodes/node0/cored/config/genesis.json nodes/node/cored/config
	docker-compose up -d node
	docker exec -it node sh -c "sed -i 's/persistent_peers = \"\"/${PEERS}/' /home/obada/.cored/config/config.toml"
	docker exec -it node sh -c "sed -i 's/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/' /home/obada/.cored/config/config.toml"
	docker exec -it node sh -c "sed -i 's/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/' /home/obada/.cored/config/app.toml"
	docker restart node

PRIVATE_KEY=$$(docker exec -it obs-node sh -c "cored keys export obs --keyring-backend test --unarmored-hex --unsafe" | cut -c1-64)
run_application:
	docker-compose --env-file .env up -d --force-recreate rdgo trust-anchor

explorer/database/run:
	docker-compose up -d --force-recreate bdjuno_db

explorer/database/migrate:
	sleep 20
	docker exec -t bdjuno_db sh -c "psql -Ubdjuno -hlocalhost -dbdjuno_db < /root/schema/schema.sql"

explorer/bdjuno/genesis:
	docker-compose up bdjuno-genesis

explorer/bdjuno/run:
	docker-compose up -d bdjuno

explorer/hasura/cli:
	docker exec -t hasura sh -c "apt update && apt install curl bash -y && curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash && cd /home/hasura/metadata && hasura metadata apply --endpoint http://hasura:8080 && exit 0"

explorer/hasura/run:
	docker-compose up -d hasura

explorer/run: explorer/database/run
	docker-compose up -d explorer

run:
	docker-compose up -d

clean:
	docker-compose down
	rm -rf ipfs
	rm -rf nodes
	rm -rf bdjuno/data
	docker system prune -f
