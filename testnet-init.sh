#!/bin/sh

NODES_DIR=$HOME/nodes

if [ ! -d $NODES_DIR/node0 ]; then
    ethermintd testnet --v 4 -o $NODES_DIR  --keyring-backend=test --coin-denom=aobd --ip-addresses tradeloop-node,obs-node,usody-node,ascidi-node
fi
