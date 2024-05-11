sudo apt update
sudo apt upgrade -y
sudo apt install -y curl git jq lz4 build-essential
sudo apt install -y unzip logrotate git jq sed wget curl coreutils systemd
sudo apt install make curl tar wget jq build-essential -y
sudo apt install make clang pkg-config libssl-dev -y 

sudo apt install curl build-essential gcc make -y
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.profile
source ~/.cargo/env

cd $HOME
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile
go version

cd /root
git clone https://github.com/cometbft/cometbft.git
cd cometbft
git checkout v0.37.2
go mod tidy
go build -o cometbft ./cmd/cometbft
mv cometbft /root/cometbft/
make install
ulimit -n 4096
Apt install screen
screen -S cometbft
cometbft start --home ~/.penumbra/testnet_data/node0/cometbft

git clone https://github.com/penumbra-zone/penumbra
cd penumbra && git fetch && git checkout v0.75.0 && cargo update
cargo build --release --bin pcli
cargo build --release --bin pd
cargo run --bin pd --release -- testnet unsafe-reset-all
cargo run --bin pd --release -- testnet join
screen -S pd
cd penumbra
cargo run --bin pd --release -- start --home ~/.penumbra/testnet_data/node0/pd
