#!/bin/bash

cd $HOME
wget -O entrypointd https://github.com/entrypoint-zone/testnets/releases/download/v1.3.0/entrypointd-1.3.0-linux-amd64
chmod +x entrypointd
sudo mv $HOME/entrypointd $(which entrypointd)
sudo systemctl stop entrypointd

cp $HOME/.entrypoint/data/priv_validator_state.json $HOME/.entrypoint/priv_validator_state.json.backup

entrypointd tendermint unsafe-reset-all --home $HOME/.entrypoint --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/entrypoint-testnet/entrypoint-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.entrypoint

mv $HOME/.entrypoint/priv_validator_state.json.backup $HOME/.entrypoint/data/priv_validator_state.json

sudo systemctl restart entrypointd
