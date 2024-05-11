#!/bin/bash

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

cd $HOME && mkdir -p go/bin/
git clone -b v0.1.0 https://github.com/0glabs/0g-chain.git
./0g-chain/networks/testnet/install.sh

0gchaind config chain-id zgtendermint_16600-1

echo -e Your Node Name
read MONIKER
0gchaind init "$MONIKER" --chain-id=zgtendermint_16600-1

wget -O $HOME/.0gchain/config/genesis.json "https://raw.githubusercontent.com/111STAVR111/props/main/Og/genesis.json"
wget -O $HOME/.0gchain/config/addrbook.json "https://raw.githubusercontent.com/111STAVR111/props/main/Og/addrbook.json"

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025ua0gi\"/;" ~/.0gchain/config/app.toml
external_address=$(wget -qO- eth0.me) 
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.0gchain/config/config.toml
peers="f878d40c538c8c23653a5b70f615f8dccec6fb9f@54.215.187.94:26656,9d88e34a436ec1b50155175bc6eba89e7a1f0e9a@213.199.61.18:26656,da1f4985ce3df05fd085460485adefa93592a54c@172.232.33.25:26656,23b0a0624699f85062ddebf910583f70a5b9e86b@14.167.152.116:14256,a4055b828e59832c7a06d61fc51347755a160d0b@157.90.33.62:21656,d4085fd93ab77576f2acdb25d2d817061db5afe6@62.169.19.156:26656,a83f5d07a8a64827851c9f1d0c21c900b9309608@188.166.181.110:26656,b92597c5124da2a5177c1c2e11f69dfec45a721a@45.90.220.92:26656,bcfbafecc407b1cfd7737a172adda535580c62ed@62.169.19.5:26656,5d81d59e81356a33e6ccccaa3d419ff73244697e@107.173.18.103:26656,535ddcc917ab5ee6ddd2259875dac6018651da24@176.9.183.45:32656,254bbbc42bca6b7e81081a42a4993086e20e06ed@89.116.29.154:26656,0494c33335eed845a7ba1f894b54f6b31054c09d@207.180.204.179:26656,a3e6c6214805c1c068882f1981855c7a9f5926ea@213.168.249.202:26656,57588ff7b1e862e754f3cd74fc2414f03cb79da4@213.133.111.189:26656,5a69dafc859eee83b623b0c88b392337bb82eeb3@194.163.144.148:26656,9d09d391b2cf706a597d03fe8bb6700fe5cac53d@65.108.198.183:18456,f3c912cf5653e51ee94aaad0589a3d176d31a19d@157.90.0.102:31656,141dbd90d5c3411c9ba72ba03704ccdb70875b01@65.109.147.58:36656,ac9ef9840f56295916b6f9cfb1453cfef14441c1@75.119.128.23:27656,b8f8ed478f2794629fdb5cf0c01edaed80f00f84@168.119.64.172:26656,3c2ddd1e25a99bcbad08f502eca719a52465c1fd@37.60.231.42:26656,d00273ac6a2470cd4e48008d9af4d2521b134394@62.169.29.136:26656,a6ff8a651dd0a0e66dbfb2174ccadcbbcf567b29@66.94.122.224:26656,2579a86e3c4c1fabe3955d3a9ed40363bf9618f7@138.201.37.195:26656,bc4a5cccc6c5ffcc933f92f460a68b6398ba84f9@84.247.151.2:26656,91f079ccd2e0edf42e0fa57183ac92c22c525658@14.245.25.144:14256,66cfdcd92e5206e59bc507bef3f6d72ed21a149d@109.199.100.254:26656,5b2a956457b2918426b1f685fa6e3791609fb30c@84.247.165.146:26656,d0770d94946e7beb86805c6d96550734838f70c9@74.48.157.34:26656,c4b9c3a7f3651af729d73b150e714ee91e7585c1@14.176.200.133:26656,a3b0aadd7772dfb7a7e708d8a113bbba13339846@77.237.243.33:26656,bc32262de08f9129697c9b8a643804c83550a760@109.199.104.42:26656,8e1049b05fbdac9f5820d91fdc344055771851fa@37.221.195.53:26656,e095f1a8cb689257cd34b86918815e0325cc55bf@80.71.227.50:26656,cf187b69a64b137ec1f15539326a5cea7b01796e@84.46.252.97:26656,3734b9356dadb67f880dd6c2b3c54a76ec5eb182@37.60.224.149:26656,8cfe612c6bed3ea559ac656c5595683fcaef0540@213.199.53.85:16656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.0gchain/config/config.toml
seeds=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.0gchain/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.0gchain/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 50/g' $HOME/.0gchain/config/config.toml
pruning="custom"
pruning_keep_recent="1000"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.0gchain/config/app.toml
indexer="null" &&
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.0gchain/config/config.toml


cd $HOME
snap install lz4
cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
rm -rf $HOME/.0gchain/data
curl -o - -L https://og.snapshot.stavr.tech/og-snap.tar.lz4 | lz4 -c -d - | tar -x -C $HOME/.0gchain --strip-components 2
mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json
wget -O $HOME/.0gchain/config/addrbook.json "https://raw.githubusercontent.com/111STAVR111/props/main/Og/addrbook.json"

sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind
After=network-online.target

[Service]
User=$USER
ExecStart=$(which 0gchaind) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable 0gchaind 
sudo systemctl start 0gchaind
