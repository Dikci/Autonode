sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y

curl https://get.ignite.com/cli | bash
sudo mv ignite /usr/local/bin/

VERSION=1.21.6
wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

rm -rf $HOME/aligned_layer_tendermint
git clone https://github.com/yetanotherco/aligned_layer_tendermint.git
cd $HOME/aligned_layer_tendermint
git checkout 98643167990f8a597b331ddd879e079bafb25b08
make build-linux

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

echo -e Your Node Name
read MONIKER
alignedlayerd init "$MONIKER" --chain-id alignedlayer

wget -O $HOME/.alignedlayer/config/genesis.json https://testnet-files.itrocket.net/alignedlayer/genesis.json
wget -O $HOME/.alignedlayer/config/addrbook.json https://testnet-files.itrocket.net/alignedlayer/addrbook.json

SEEDS="d1a8816c1c5800b352c2a1eb0e7a156bce34ae9f@alignedlayer-testnet-seed.itrocket.net:50656"
PEERS="144c2d4fbbaf54dda837bfbc88b688fb2f02c92f@alignedlayer-testnet-peer.itrocket.net:50656,2567ea5aed4bba4e3062a1072a8f1e7fb4e4497c@65.109.85.36:26656,51ca4087558ebe93a16e3f1e84a969d30e7a91f1@95.216.245.35:26656,4093bf12076818a82f9fc1c75dc974e1d93daf44@195.201.30.159:26656,df898a791ae0aa21c1e2029c90ff8275104860d8@37.60.248.171:26656,692729135ab36bf8e9fbd65ce8f1913665bed299@188.40.109.171:26656,18e1adeadb8cc596375e4212288fcd00690df067@213.199.48.195:26656,7292de855372480ae23dbcaf94d36ead187cf6a8@194.163.143.206:50656,a1d6d9569789a7a8765f0a4899439819f07755d4@213.133.103.213:26656,afeea4cd47aa80504adbdaa8aa019864e291de55@[2a03:cfc0:8000:13::b910:277f]:13356,5be66a14f474ea7c8abe6d576758fa14d1289793@154.12.228.190:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.alignedlayer/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.alignedlayer/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.alignedlayer/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.alignedlayer/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0001stake"|g' $HOME/.alignedlayer/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.alignedlayer/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.alignedlayer/config/config.toml


alignedlayerd tendermint unsafe-reset-all --home $HOME/.alignedlayer
if curl -s --head curl https://testnet-files.itrocket.net/alignedlayer/snap_alignedlayer.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/alignedlayer/snap_alignedlayer.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.alignedlayer
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/alignedlayerd.service > /dev/null <<EOF
[Unit]
Description=Alignedlayer node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.alignedlayer
ExecStart=$(which alignedlayerd) start --home $HOME/.alignedlayer
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable alignedlayerd
sudo systemctl start alignedlayerd
