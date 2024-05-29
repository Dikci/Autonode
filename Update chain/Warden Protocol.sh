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
sudo systemctl restart wardend && sudo journalctl -u wardend -f
