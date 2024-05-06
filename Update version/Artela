#!/bin/bash

sudo systemctl stop artelad

cd $HOME
rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.7-rc6
make install

sed -E 's/^pool-size[[:space:]]*=[[:space:]]*[0-9]+$/apply-pool-size = 10\nquery-pool-size = 30/' ~/.artelad/config/app.toml > ~/.artelad/config/temp.app.toml && mv ~/.artelad/config/temp.app.toml ~/.artelad/config/app.toml

sudo systemctl start artelad

sudo systemctl stop artelad

cp $HOME/.artelad/data/priv_validator_state.json $HOME/.artelad/priv_validator_state.json.backup

artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/artela-testnet/artela-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad

mv $HOME/.artelad/priv_validator_state.json.backup $HOME/.artelad/data/priv_validator_state.json

sudo systemctl restart artelad
