#!/bin/bash

sudo systemctl stop galacticad
cd $HOME
rm -rf galactica
git clone https://github.com/Galactica-corp/galactica
cd galactica
git checkout v0.1.2
make build
cp $HOME/.galactica/config/priv_validator_key.json $HOME/.galactica/priv_validator_key.json.backup
galacticad config chain-id galactica_9302-1
wget https://raw.githubusercontent.com/Galactica-corp/networks/main/galactica_9302-1/genesis.json -O ~/.galactica/config/genesis.json
wget https://raw.githubusercontent.com/Galactica-corp/networks/main/galactica_9302-1/seeds.txt -O ~/.galactica/config/seeds.txt
seeds=$(cat ~/.galactica/config/seeds.txt | tr '\n' ',' | sed 's/,$//')
sed -i '' "s/seeds = \"\"/seeds = \"$seeds\"/" ~/.galactica/config/config.toml
# create service file
sudo tee /etc/systemd/system/galacticad.service > /dev/null <<EOF
[Unit]
Description=Galactica node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.galactica
ExecStart=$(which galacticad) start --home $HOME/.galactica --chain-id galactica_9302-1
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
echo '{"height":"0","round":0,"step":0}' > ~/.galactica/data/priv_validator_state.json
sudo mv $HOME/galactica/build/galacticad $(which galacticad)
sudo systemctl restart galacticad
