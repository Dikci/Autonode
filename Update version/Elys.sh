#!/bin/bash

sudo systemctl stop elysd
cd && rm -rf elys
git clone https://github.com/elys-network/elys
cd elys
git checkout v0.30.0
make install

sudo systemctl restart elysd

sudo systemctl stop elysd

cp $HOME/.elys/data/priv_validator_state.json $HOME/.elys/priv_validator_state.json.backup

elysd tendermint unsafe-reset-all --home $HOME/.elys --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/elys-testnet/elys-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.elys

mv $HOME/.elys/priv_validator_state.json.backup $HOME/.elys/data/priv_validator_state.json

sudo systemctl restart elysd
