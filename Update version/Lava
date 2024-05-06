#!/bin/bash

sudo systemctl stop lavad
cd && rm -rf lava
git clone https://github.com/lavanet/lava
cd lava
git checkout v2.0.0
make install-all

sudo systemctl restart lavad

sudo systemctl stop lavad

cp $HOME/.lava/data/priv_validator_state.json $HOME/.lava/priv_validator_state.json.backup

lavad tendermint unsafe-reset-all --home $HOME/.lava --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/lava-testnet/lava-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.lava

mv $HOME/.lava/priv_validator_state.json.backup $HOME/.lava/data/priv_validator_state.json

sudo systemctl restart lavad
