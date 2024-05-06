#!/bin/bash
sudo systemctl stop okp4d

cd || return
rm -rf okp4d
git clone https://github.com/okp4/okp4d.git
cd okp4d || return
git checkout v7.0.0
make install
okp4d version # 7.0.0

sudo systemctl start okp4d

sudo systemctl stop okp4d

cp $HOME/.okp4d/data/priv_validator_state.json $HOME/.okp4d/priv_validator_state.json.backup

okp4d tendermint unsafe-reset-all --home $HOME/.okp4d --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/okp4-testnet/okp4-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.okp4d

mv $HOME/.okp4d/priv_validator_state.json.backup $HOME/.okp4d/data/priv_validator_state.json

sudo systemctl restart okp4d
