SHELL := /bin/bash
.DEFAULT_GOAL := run
NODE_VERSION ?= develop

GENESIS_VERSION ?= https://raw.githubusercontent.com/obada-foundation/testnet/main/testnets/testnet-2/genesis.json
NODES := val-node1'\n'val-node2'\n'sentry-node1'\n'sentry-node2'\n'node'\n'faucet
NODES_WITH_BALANCE := val-node1'\n'val-node2'\n'faucet


ifndef INITIALIZE_TIMEOUT
	override INITIALIZE_TIMEOUT = 10
endif

install: create_folders_and_files pull_containers initialize_network configure_application_node run_application explorer/run explorer/database/migrate explorer/bdjuno/genesis  explorer/bdjuno/run explorer/hasura/run explorer/hasura/cli ipfs/cors wallet/print-seed

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

	# Network interface mapping 
	docker exec -it node sh -c "sed -i 's/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/' /home/obada/.cored/config/config.toml"
	docker exec -it node sh -c "sed -i 's/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/' /home/obada/.cored/config/app.toml"

	# CORS (only for playground)
	docker exec -it node sh -c "sed -i 's/cors_allowed_origins = \[\]/cors_allowed_origins = \[\"\*\"\]/' /home/obada/.cored/config/config.toml"
	docker exec -it node sh -c "sed -i '125s/enabled-unsafe-cors = false/enabled-unsafe-cors = true/' /home/obada/.cored/config/app.toml"

	#Enables application node REST API on port 1317
	docker exec -it node sh -c "sed -i '104s/enable = false/enable = true/' /home/obada/.cored/config/app.toml"

	docker restart node

run_application:
	docker-compose --env-file .env up -d --force-recreate trust-anchor rd

explorer/database/run:
	docker-compose up -d --force-recreate bdjuno_db

explorer/database/migrate:
	sleep 5
	docker exec -t bdjuno_db sh -c "while ! pg_isready; do sleep 20; done && psql -Ubdjuno -hlocalhost -dbdjuno_db < /root/schema/schema.sql"

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

wallet/print-seed:
	cat nodes/node0/cored/key_seed.json

ipfs/cors:
	docker exec -t ipfs ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
	docker exec -t ipfs ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET","POST"]'
	docker exec -t ipfs ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["X-Requested-With"]'
	docker restart ipfs

run:
	docker-compose up -d

clean:
	docker-compose down
	rm -rf ipfs
	rm -rf nodes
	rm -rf bdjuno/data
	docker system prune -f


docker/build:
	docker build -t obada/node-sim:$(NODE_VERSION) --build-arg NODE_VERSION=$(NODE_VERSION) -f Dockerfile .


init: init/dirs init/nodes init/genesis init/val-keys init/balances

init/dirs:
	echo -e $(NODES) | xargs -I {}\
		mkdir -p nodes/{}

init/nodes:
	echo -e $(NODES) | xargs -I {}\
		docker run --rm -t \
		-v $$(pwd)/nodes/{}:/home/obada/.fullcore \
		obada/fullcore:develop \
		fullcored init {} --chain-id obada-testnet

init/genesis:
	echo -e $(NODES) | xargs -I {}\
		docker run --rm -t \
		-v $$(pwd)/nodes/{}:/home/obada/.fullcore \
		obada/fullcore:develop \
		wget $(GENESIS_VERSION) -O /home/obada/.fullcore/config/genesis.json

	echo -e $(NODES) | xargs -I {}\
		docker run --rm -t \
		-v $$(pwd)/nodes/{}:/home/obada/.fullcore \
		obada/fullcore:develop \
		sed -Ei 's/([0-9]+)stake/\1rohi/g' /home/obada/.fullcore/config/app.toml

init/val-keys:
	echo -e $(NODES) | grep val | xargs -I {}\
		docker run --rm -t \
		-v $$(pwd)/nodes/{}:/home/obada/.fullcore \
		obada/fullcore:develop \
		fullcored keys --keyring-backend test --keyring-dir /home/obada/.fullcore/keys add {}

init/balances:
	echo -e $(VALIDATOR_NODES) | xargs -I {}\
		docker run --rm -t \
		-v $$(pwd)/nodes/{}:/home/obada/.fullcore \
		obada/fullcore:develop \
		sh -c "fullcored keys --keyring-backend test --keyring-dir ~/.fullcore/keys show "{}" --address > ~/.fullcore/keys/"{}

	echo -e $(VALIDATOR_NODES) | xargs -I {}\
		docker run --rm -t \
		-v $$(pwd)/nodes/{}:/home/obada/.fullcore \
		-e NODE_ADDRESS=cat nodes/{}/keys/address) \
		obada/fullcore:develop \
		sh -c 'fullcored add-genesis-account $$NODE_ADDRESS 100000000000000000rohi'
