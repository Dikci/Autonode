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
wget -O uniond https://testnet-files.itrocket.net/union/uniond
chmod +x uniond
mv uniond $HOME/go/bin/

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

echo -e Your Node Name
read MONIKER
uniond init "$MONIKER" --chain-id union-testnet-8

wget -O $HOME/.union/config/genesis.json https://testnet-files.itrocket.net/union/genesis.json
wget -O $HOME/.union/config/addrbook.json https://testnet-files.itrocket.net/union/addrbook.json

SEEDS="2812a4ae3ebfba02973535d05d2bbcc80b7d215f@union-testnet-seed.itrocket.net:23656"
PEERS="a05dde8737e66c99260edfd45180055fe7f8bd9d@union-testnet-peer.itrocket.net:23656,a8d328309e80ea00bb64d8061e89cca02c2efd67@65.21.134.219:17156,a3d31a626a85226999f1c59d44589309a02d0a2b@51.178.92.69:39656,d098e0c6099fec09889d70184bad4f0ac9591932@65.108.30.59:27656,d81002255435766435863fdb02d661a50e0302ab@136.243.104.103:23156,1c874e5717ef43aada2eb214deab5428916c1b4c@194.29.101.12:26656,b1dc78649a99a405dbfa30ecaa9e519b1295850b@37.27.58.171:26656,195a444e30f041ef6c53a450599ccc99e3f7bf29@37.252.184.231:26656,4761850effbd601ca6bee5f79d53aca02da4e3dc@88.99.3.158:24656,d776d9929ce0cbf12eae1deff200d07bf37a45ee@65.108.230.113:3156,706d4dcad85efc9a4399ec1107de5fc326a68268@65.21.48.199:26656,d4bf3b30d1ea83dc339b2122a68dfa4f2ce26687@135.181.134.151:24656,13fdb0522acecfda911e423327f9631980c35bc9@65.109.30.37:17656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.union/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.union/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.union/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.union/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0muno"|g' $HOME/.union/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.union/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.union/config/config.toml


uniond tendermint unsafe-reset-all --home $HOME/.union --home $HOME/.union
if curl -s --head curl https://testnet-files.itrocket.net/union/snap_union.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/union/snap_union.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.union
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
sudo systemctl enable uniond
sudo systemctl start uniond
