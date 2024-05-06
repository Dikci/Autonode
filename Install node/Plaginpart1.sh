#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

#Remove fuck windows
sudo apt-mark hold linux-image-generic linux-headers-generic

sudo apt install needrestart -y


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

# Обновление списка пакетов
sudo apt -qy update

# Установка необходимых пакетов
sudo apt install -qy screen tar wget curl libcurl4 git jq bsdmainutils make ncdu gcc chrony net-tools iotop nload clang lz4 build-essential unzip libpq-dev libssl-dev pkg-config ocl-icd-opencl-dev libopencl-clang-dev libgomp1 speedtest-cli sysstat protobuf-compiler