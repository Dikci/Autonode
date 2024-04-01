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
rm -rf okp4d
git clone https://github.com/okp4/okp4d.git
cd okp4d
git checkout v7.0.0

make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

echo -e Your Node Name
read MONIKER
okp4d init "$MONIKER" --chain-id=okp4-nemeton-1

curl -Ls https://ss-t.okp4.nodestake.org/genesis.json > $HOME/.okp4d/config/genesis.json 
curl -Ls https://ss-t.okp4.nodestake.org/addrbook.json > $HOME/.okp4d/config/addrbook.json

seed="2098d88a57215e89b776179f66e369c453e90141@rpc-t.okp4.nodestake.org:666"
sed -i.bak -e "s/^seed *=.*/seed = \"$seed\"/" ~/.okp4d/config/config.toml

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

SNAP_NAME=$(curl -s https://ss-t.okp4.nodestake.org/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
curl -o - -L https://ss-t.okp4.nodestake.org/${SNAP_NAME}  | lz4 -c -d - | tar -x -C $HOME/.okp4d

sudo tee /etc/systemd/system/okp4d.service > /dev/null <<EOF
[Unit]
Description=okp4d Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which okp4d) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable okp4d

sudo systemctl start okp4d
