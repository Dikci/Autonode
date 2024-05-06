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

curl -L https://snapshots-testnet.nodejumper.io/cardchain-testnet/genesis.json > $HOME/.cardchaind/config/genesis.json

Cardchaind config chain-id cardtestnet-10

sed -i -e 's|^seeds *=.*|seeds = ""|' $HOME/.cardchaind/config/config.toml
sed -i -e 's|^persistent_peers *=.*|persistent_peers = "ab88b326851e26cf96d1e4634d08ca0b8d812032@202.61.225.157:20056"|' $HOME/.cardchaind/config/config.toml

Cardchaind tendermint unsafe-reset-all --home $HOME/.cardchaind

curl -L https://snapshots-testnet.nodejumper.io/cardchain-testnet/addrbook.json > $HOME/.cardchaind/config/addrbook.json

sudo systemctl start Cardchaind

sudo systemctl stop Cardchaind

cp $HOME/.cardchaind/data/priv_validator_state.json $HOME/.cardchaind/priv_validator_state.json.backup

Cardchaind tendermint unsafe-reset-all --home $HOME/.cardchaind --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/cardchain-testnet/cardchain-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.cardchaind

mv $HOME/.cardchaind/priv_validator_state.json.backup $HOME/.cardchaind/data/priv_validator_state.json

sudo systemctl restart Cardchaind
