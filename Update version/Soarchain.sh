#!/bin/bash
sudo systemctl stop soarchaind

curl -s https://raw.githubusercontent.com/soar-robotics/testnet-binaries/main/v0.2.9/ubuntu22.04/soarchaind > soarchaind
chmod +x soarchaind
sudo mv -f soarchaind "$(which soarchaind)"

sudo systemctl start soarchaind

sudo systemctl stop soarchaind

cp $HOME/.soarchain/data/priv_validator_state.json $HOME/.soarchain/priv_validator_state.json.backup

soarchaind tendermint unsafe-reset-all --home $HOME/.soarchain --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/soarchain-testnet/soarchain-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.soarchain

mv $HOME/.soarchain/priv_validator_state.json.backup $HOME/.soarchain/data/priv_validator_state.json

sudo systemctl restart soarchaind