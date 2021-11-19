#!/bin/sh

DAEMON=/home/cored/cored
DENOM=obd

$DAEMON init --chain-id $CHAINID $CHAINID --home $DAEMON_HOME

VALIDATORS="tradeloop wpdi usody obs ascidi reno"

# create keys
for VALIDATOR in $VALIDATORS
do
  $DAEMON keys add $VALIDATOR --keyring-backend test --home $DAEMON_HOME
done

# create accounts
for VALIDATOR in $VALIDATORS
do
  $DAEMON add-genesis-account $VALIDATOR --keyring-backend test 1000000000000$DENOM --home $DAEMON_HOME
done

# create validator with a self-delegation
for VALIDATOR in $VALIDATORS
do
  $DAEMON gentx $VALIDATOR 90000000000$DENOM --chain-id $CHAINID  --keyring-backend test --home $DAEMON_HOME --node-id $VALIDATOR
done

# create the final genesis file:
$DAEMON collect-gentxs --home $DAEMON_HOME

sed -i 's/\"stake\"/\"obd\"/g' $DAEMON_HOME/config/genesis.json
$DAEMON validate-genesis $DAEMON_HOME/config/genesis.json

for VALIDATOR in $VALIDATORS
do
  NODE_CONFIG_PATH="$DAEMON_HOME/$VALIDATOR-node/cored/config"

  mkdir -p $NODE_CONFIG_PATH
  cp $DAEMON_HOME/config/genesis.json $NODE_CONFIG_PATH
  cp $DAEMON_HOME/config/config.toml $NODE_CONFIG_PATH
  chown -R 1000:1000 "$DAEMON_HOME/$VALIDATOR-node/cored"
done
