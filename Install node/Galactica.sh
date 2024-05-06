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
rm -rf galactica
git clone https://github.com/Galactica-corp/galactica
cd galactica
git checkout v0.1.2
make build
mv $HOME/galactica/build/galacticad $HOME/go/bin

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

galacticad config node tcp://localhost:${GALACTICA_PORT}657
galacticad config keyring-backend os
galacticad config chain-id galactica_9302-1

echo -e Your Node Name
read MONIKER
galacticad init "$MONIKER" --chain-id galactica_9302-1

wget -O $HOME/.galactica/config/genesis.json https://testnet-files.itrocket.net/galactica/genesis.json
wget -O $HOME/.galactica/config/addrbook.json https://testnet-files.itrocket.net/galactica/addrbook.json

SEEDS="52ccf467673f93561c9d5dd4434def32ef2cd7f3@galactica-testnet-seed.itrocket.net:46656"
PEERS="c9993c738bec6a10cfb8bb30ac4e9ae6f8286a5b@galactica-testnet-peer.itrocket.net:11656,6b846b316d704d78f3f9ca46d86cebc5a22de8ae@161.97.111.249:26656,d572caf3a63d6c730fe0a5c586fd93e70683b727@167.86.127.19:656,e926f2e20568e61646558a2b8fd4a4e46d77903f@141.95.110.124:26656,7d8c640a24a1f15e98d45982bfd02dd0316c46e8@213.136.85.27:26656,f3cd6b6ebf8376e17e630266348672517aca006a@46.4.5.45:27456,9990ab130eac92a2ed1c3d668e9a1c6e811e8f35@148.251.177.108:27456,8949fb771f2859248bf8b315b6f2934107f1cf5a@168.119.241.1:26656,dc4ed6e614725dffc41874e762a1b1ce4cdc3304@161.97.74.20:46656,e38c22e44893e75e388f3bcea2a075124d75ccd3@89.110.89.244:26656,c722e6dc5f762b0ef19be7f8cc8fd67cdf988946@49.12.96.14:26656,3afb7974589e431293a370d10f4dcdb73fa96e9b@157.90.158.222:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.galactica/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.galactica/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.galactica/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.galactica/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "10agnet"|g' $HOME/.galactica/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.galactica/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.galactica/config/config.toml


galacticad tendermint unsafe-reset-all --home $HOME/.galactica
if curl -s --head curl https://testnet-files.itrocket.net/galactica/snap_galactica.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/galactica/snap_galactica.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.galactica
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/uniond.service > /dev/null <<EOF
[Unit]
Description=Union node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.union
ExecStart=$(which uniond) start --home $HOME/.union
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable galacticad
sudo systemctl start galacticad
