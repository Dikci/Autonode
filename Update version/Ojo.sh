#!/bin/bash
cd $HOME
rm -rf ojo
git clone https://github.com/ojo-network/ojo.git
cd ojo
git checkout  v0.3.0-rc4
make build
sudo mv $HOME/ojo/build/ojod $(which ojod)
sudo systemctl stop ojod

cp $HOME/.ojo/data/priv_validator_state.json $HOME/.ojo/priv_validator_state.json.backup

ojod tendermint unsafe-reset-all --home $HOME/.ojo --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/ojo-testnet/ojo-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.ojo

mv $HOME/.ojo/priv_validator_state.json.backup $HOME/.ojo/data/priv_validator_state.json
sudo systemctl restart ojod
