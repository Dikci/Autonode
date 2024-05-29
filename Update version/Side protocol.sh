#!/bin/bash
sudo systemctl stop sided
wget https://github.com/sideprotocol/testnet/raw/main/S2-testnet-2/genesis.json -O ~/.side/config/genesis.json
SEEDS="582dedd866dd77f25ac0575118cf32df1ee50f98@202.182.119.24:26656"
PEERS="bbbf623474e377664673bde3256fc35a36ba0df1@side-testnet-peer.itrocket.net:45656,3003f4290ea8e3f5674e5d5f687ef8cd4b558036@152.228.208.164:26656,2b2ad344919d591cad2af6fe1b88e51fb02e926b@54.249.68.205:26656,d3a38688a2180658d15f6117b3e6a2771a3e650e@14.245.25.144:45656,541c500114bc5516c677f6a79a5bdfec13062e91@37.27.59.176:17456,aa3533e8c1ba70125fa62477c7fc6b9758976752@14.167.152.116:45656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.side/config/config.toml
sided config chain-id S2-testnet-2
cd $HOME
rm -rf side
git clone https://github.com/sideprotocol/side.git
cd side
git checkout v0.8.1
make build
sudo mv $HOME/side/build/sided $(which sided)
sided tendermint unsafe-reset-all --home $HOME/.side
if curl -s --head curl https://testnet-files.itrocket.net/side/snap_side.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/side/snap_side.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.side
    else
  echo no have snap
fi
sudo systemctl restart sided
