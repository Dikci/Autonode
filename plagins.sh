#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

#Remove fuck windows
sudo apt-mark hold linux-image-generic linux-headers-generic

sudo apt install needrestart


echo "[Unit]
Description=needrestart service
Documentation=man:needrestart

[Service]
Type=simple
ExecStart=/usr/bin/needrestart --noexec

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/needrestart.service

sudo systemctl daemon-reload
sudo systemctl enable needrestart.service
sudo systemctl start needrestart.service

sudo sed -i 's/.*DISABLE_RESTART_ON_UPDATE.*/DISABLE_RESTART_ON_UPDATE=yes/' /etc/needrestart/needrestart.conf

echo "DISABLE_RESTART_ON_UPDATE=yes" | sudo tee -a /etc/needrestart/needrestart.conf

echo 'export NEEDRESTART_ON_UPDATE=0' >> ~/.bashrc
source ~/.bashrc

sudo sed -i 's/.*NEEDRESTART_ON_RECOMMENDED.*/NEEDRESTART_ON_RECOMMENDED=no/' /etc/needrestart/needrestart.conf


echo 'NEEDRESTART=no' | sudo tee -a /etc/environment

sudo systemctl start needrestart.service
sudo systemctl  restart needrestart.service

export DEBIAN

# Обновление списка пакетов
sudo apt -qy update

# Установка необходимых пакетов
sudo apt install -qy screen tar wget curl libcurl4 git jq bsdmainutils make ncdu gcc chrony net-tools iotop nload clang lz4 build-essential unzip libpq-dev libssl-dev pkg-config openssl ocl-icd-opencl-dev libopencl-clang-dev libgomp1 speedtest-cli sysstat protobuf-compiler
sudo apt -qy install curl git jq lz4 build-essential
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y
sudo apt install ncdu -y

# Обновление установленных пакетов
sudo apt -qy upgrade

# Клонирование и установка последней версии Go
git clone --depth 1 https://github.com/udhos/update-golang
cd update-golang
git fetch --unshallow
sudo ./update-golang.sh
cd
rm -rf update-golang

# Установка Docker
if ! command -v docker &> /dev/null
then
 sudo apt install docker.io -y
 sudo apt install docker-compose -y
fi

# Установка Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Установка NVM и Node.js
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 21.7.1

# Установка Python
sudo apt install python3 -y
