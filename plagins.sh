#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Обновление списка пакетов
sudo apt -qy update

# Установка необходимых пакетов
sudo apt install -qy screen tar wget curl libcurl4 git jq bsdmainutils make ncdu gcc chrony net-tools iotop nload clang lz4 build-essential unzip libpq-dev libssl-dev pkg-config openssl ocl-icd-opencl-dev libopencl-clang-dev libgomp1 speedtest-cli sysstat protobuf-compiler
sudo apt -qy install curl git jq lz4 build-essential
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y
apt install ncdu -y

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
 apt install docker.io -y
 apt install docker-compose -y
fi

# Установка Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Установка NVM и Node.js
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 21.7.1
