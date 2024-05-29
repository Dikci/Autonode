#!/bin/bash

cd $HOME
rm -rf ojo
git clone https://github.com/ojo-network/ojo.git
cd ojo
git checkout  v0.3.0-rc4
make build
sudo mv $HOME/ojo/build/ojod $(which ojod)
sudo systemctl restart ojod && sudo journalctl -u ojod -f
