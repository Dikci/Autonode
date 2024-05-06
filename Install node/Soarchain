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

cd $HOME
curl -s https://raw.githubusercontent.com/soar-robotics/testnet-binaries/main/v0.2.9/ubuntu22.04/soarchaind > soarchaind
chmod +x soarchaind
mkdir -p $HOME/go/bin/
mv soarchaind $HOME/go/bin/

curl -L https://snapshots-testnet.nodejumper.io/soarchain-testnet/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv libwasmvm.x86_64.so /var/lib/libwasmvm.x86_64.so

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

soarchaind config chain-id soarchaintestnet
soarchaind config keyring-backend test
soarchaind config node tcp://localhost:25257

echo -e Your Node Name
read MONIKER
soarchaind init "$MONIKER" --chain-id soarchaintestnet

curl -L https://snapshots-testnet.nodejumper.io/soarchain-testnet/genesis.json > $HOME/.soarchain/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/soarchain-testnet/addrbook.json > $HOME/.soarchain/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "3f472746f46493309650e5a033076689996c8881@soarchain-testnet.rpc.kjnodes.com:17259"|' $HOME/.soarchain/config/config.toml

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utmotus"|' $HOME/.soarchain/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.soarchain/config/app.toml


curl "https://snapshots-testnet.nodejumper.io/soarchain-testnet/soarchain-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.soarchain"


sudo tee /etc/systemd/system/soarchaind.service > /dev/null << EOF
[Unit]
Description=Soarchain node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which soarchaind) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable soarchaind.service

sudo systemctl start soarchaind.service
