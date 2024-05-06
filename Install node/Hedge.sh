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
mkdir -p $HOME/go/bin/
wget https://ss-t.hedge.nodestake.org/hedged
chmod +c hedged
mv hedged $HOME/go/bin/


go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

echo -e Your Node Name
read MONIKER
hedged init "$MONIKER" --chain-id=berberis-1

curl -Ls https://ss-t.hedge.nodestake.org/genesis.json > $HOME/.hedge/config/genesis.json 
curl -Ls https://ss-t.hedge.nodestake.org/addrbook.json > $HOME/.hedge/config/addrbook.json


SNAP_NAME=$(curl -s https://ss-t.hedge.nodestake.org/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
curl -o - -L https://ss-t.hedge.nodestake.top/${SNAP_NAME}  | lz4 -c -d - | tar -x -C $HOME/.hedge

sudo tee /etc/systemd/system/hedged.service > /dev/null <<EOF
[Unit]
Description=hedged Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which hedged) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable hedged

sudo systemctl start hedged
