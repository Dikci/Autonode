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
rm -rf seda-chain
git clone https://github.com/sedaprotocol/seda-chain.git
cd seda-chain
git checkout v0.0.7

make build

mkdir -p $HOME/.sedad/cosmovisor/genesis/bin
mv build/sedad $HOME/.sedad/cosmovisor/genesis/bin/
rm -rf build

sudo ln -s $HOME/.sedad/cosmovisor/genesis $HOME/.sedad/cosmovisor/current -f
sudo ln -s $HOME/.sedad/cosmovisor/current/bin/sedad /usr/local/bin/sedad -f

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

sedad config chain-id seda-1-testnet
sedad config keyring-backend test
sedad config node tcp://localhost:17357

echo -e Your Node Name
read MONIKER
sedad init "$MONIKER" --chain-id seda-1-testnet

curl -Ls https://snapshots.kjnodes.com/seda-testnet/genesis.json > $HOME/.sedad/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/seda-testnet/addrbook.json > $HOME/.sedad/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@seda-testnet.rpc.kjnodes.com:17359\"|" $HOME/.sedad/config/config.toml

sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"100000000000aseda\"|" $HOME/.sedad/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.sedad/config/app.toml

#CHECK PORTS
PORT=333
if ss -tulpen | awk '{print $5}' | grep -q ":26656$" ; then
    echo -e "\e[31mPort 26656 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:26656\"|:${PORT}56\"|g" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 26656 changed to ${PORT}56.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":26657$" ; then
    echo -e "\e[31mPort 26657 already in use\e[39m"
    sleep 2
    sed -i -e "s|:26657\"|:${PORT}57\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 26657 changed to ${PORT}57.\e[0m\n"
    sleep 2
    $DAEMON_NAME config set client node tcp://localhost:${PORT}57
fi
if ss -tulpen | awk '{print $5}' | grep -q ":26658$" ; then
    echo -e "\e[31mPort 26658 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:26658\"|:${PORT}58\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 26658 changed to ${PORT}58.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":6060$" ; then
    echo -e "\e[31mPort 6060 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:6060\"|:${PORT}60\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 6060 changed to ${PORT}60.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":1317$" ; then
    echo -e "\e[31mPort 1317 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:1317\"|:${PORT}17\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 1317 changed to ${PORT}17.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":9090$" ; then
    echo -e "\e[31mPort 9090 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:9090\"|:${PORT}90\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 9090 changed to ${PORT}90.\e[0m\n"
    sleep 2
fi

curl -L https://snapshots.kjnodes.com/seda-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.sedad
[[ -f $HOME/.sedad/data/upgrade-info.json ]] && cp $HOME/.sedad/data/upgrade-info.json $HOME/.sedad/cosmovisor/genesis/upgrade-info.json

sudo tee /etc/systemd/system/seda.service > /dev/null << EOF
[Unit]
Description=seda node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.sedad"
Environment="DAEMON_NAME=sedad"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.sedad/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable seda.service

sudo systemctl start seda.service
sudo journalctl -u seda.service -f --no-hostname -o cat
