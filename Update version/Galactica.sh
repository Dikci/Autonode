#!/bin/bash

sudo systemctl stop galacticad
cd $HOME
rm -rf galactica
git clone https://github.com/Galactica-corp/galactica
cd galactica
git checkout v0.1.2
make build

sudo systemctl start galacticad

galacticad tendermint unsafe-reset-all --home $HOME/.galactica
if curl -s --head curl https://testnet-files.itrocket.net/galactica/snap_galactica.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/galactica/snap_galactica.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.galactica
    else
  echo no have snap
fi

sudo systemctl restart galacticad