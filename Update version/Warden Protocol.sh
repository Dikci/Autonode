#!/bin/bash
cd $HOME
rm -rf $HOME/download
mkdir $HOME/download
cd $HOME/download
wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.3.0/wardend_Linux_x86_64.zip
unzip $HOME/download/wardend_Linux_x86_64.zip
rm -rf $HOME/download/wardend_Linux_x86_64.zip
chmod +x $HOME/download/wardend
sudo mv $HOME/download/wardend $(which wardend)
sudo systemctl stop wardend

cp $HOME/.warden/data/priv_validator_state.json $HOME/.warden/priv_validator_state.json.backup

wardend tendermint unsafe-reset-all --home $HOME/.warden --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/wardenprotocol-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.warden

mv $HOME/.warden/priv_validator_state.json.backup $HOME/.warden/data/priv_validator_state.json
sudo systemctl restart wardend
