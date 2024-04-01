sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y
sudo apt -qy install curl git jq lz4 build-essential
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
wget -O Cardchaind https://github.com/DecentralCardGame/Cardchain/releases/download/v0.14.2/Cardchaind
chmod +x Cardchaind
sudo mv Cardchaind /usr/local/bin

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

Cardchaind config node tcp://localhost:${CARDCHAIN_PORT}657
Cardchaind config keyring-backend os
Cardchaind config chain-id cardtestnet-10
echo -e Your Node Name
read MONIKER
Cardchaind init "$MONIKER" --chain-id cardtestnet-10

wget -O $HOME/.cardchaind/config/genesis.json https://testnet-files.itrocket.net/cardchain/genesis.json
wget -O $HOME/.cardchaind/config/addrbook.json https://testnet-files.itrocket.net/cardchain/addrbook.json

SEEDS="947aa14a9e6722df948d46b9e3ff24dd72920257@cardchain-testnet-seed.itrocket.net:31656"
PEERS="99dcfbba34316285fceea8feb0b644c4dc67c53b@cardchain-testnet-peer.itrocket.net:31656,cb9977720002f48f2130ee4b4e32bcd48e8548db@89.117.53.20:12456,646e8daa511beae341fb74ce787fe97c4352cc1e@185.249.227.91:656,d4b441e1806fdefb6011eb4417baef9972ef2195@89.117.52.33:12456,f26a4837e525b5c18790e9084e635732279c6e7b@75.119.134.140:26656,d0ac4b03425c4ca22f31ef78121b42119704b2b4@161.97.157.109:31656,feaea5cc2231ffa8f8531aab946b5d68bff18615@89.117.53.86:12456,d0e4edcdd73a7578b10980b3739a5b7218b7e86f@212.23.222.109:26256,b5c51c6284e5093fe05bdbab14422a1c58bf7526@212.22.70.9:36656,7fab831a2ae8c67badd1c7463afb7430c4f0ef05@142.132.202.86:16001,ca809647d5d73ef9247e94df133b1fd40ccce827@144.217.68.182:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.cardchaind/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.cardchaind/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.cardchaind/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.cardchaind/config/app.toml
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0ubpf"|g' $HOME/.cardchaind/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.cardchaind/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.cardchaind/config/config.toml

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


sudo tee /etc/systemd/system/Cardchaind.service > /dev/null <<EOF
[Unit]
Description=Cardchain node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.cardchaind
ExecStart=$(which Cardchaind) start --home $HOME/.cardchaind
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

Cardchaind tendermint unsafe-reset-all --home $HOME/.cardchaind
if curl -s --head curl https://testnet-files.itrocket.net/cardchain/snap_cardchain.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/cardchain/snap_cardchain.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.cardchaind
    else
  echo no have snap
fi

sudo systemctl daemon-reload
sudo systemctl enable Cardchaind
sudo systemctl start Cardchaind
