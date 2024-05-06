sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y

VERSION=1.21.6
wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

cd $HOME && rm -rf wardenprotocol
git clone https://github.com/warden-protocol/wardenprotocol
cd  wardenprotocol
git checkout v0.3.0

make install-wardend

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

wardend config set client chain-id buenavista-1
wardend config set client keyring-backend test
wardend config set client node tcp://localhost:26657

echo -e Your Node Name
read MONIKER
wardend init "$MONIKER" --chain-id buenavista-1

curl -L https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/genesis.json > $HOME/.warden/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/addrbook.json > $HOME/.warden/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "ddb4d92ab6eba8363bab2f3a0d7fa7a970ae437f@sentry-1.buenavista.wardenprotocol.org:26656,c717995fd56dcf0056ed835e489788af4ffd8fe8@sentry-2.buenavista.wardenprotocol.org:26656,e1c61de5d437f35a715ac94b88ec62c482edc166@sentry-3.buenavista.wardenprotocol.org:26656"|' $HOME/.warden/config/config.toml

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01uward"|' $HOME/.warden/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.warden/config/app.toml

curl "https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/wardenprotocol-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.warden"

sudo tee /etc/systemd/system/wardend.service > /dev/null << EOF
[Unit]
Description=Warden Protocol node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which wardend) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable wardend.service

sudo systemctl start wardend.service
