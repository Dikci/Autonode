#!/bin/bash

sudo systemctl stop Cardchaind

cd && rm -rf Cardchain
git clone https://github.com/DecentralCardGame/Cardchain
cd Cardchain
git checkout v0.14.2
cd cmd/Cardchaind
go mod download
go build
mkdir -p $HOME/go/bin
sudo mv Cardchaind "$(which Cardchaind)"

sudo systemctl restart Cardchaind

sudo systemctl stop Cardchaind

cp $HOME/.cardchaind/data/priv_validator_state.json $HOME/.cardchaind/priv_validator_state.json.backup

Cardchaind tendermint unsafe-reset-all --home $HOME/.cardchaind --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/cardchain-testnet/cardchain-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.cardchaind

mv $HOME/.cardchaind/priv_validator_state.json.backup $HOME/.cardchaind/data/priv_validator_state.json

sudo systemctl restart Cardchaind