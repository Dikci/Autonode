#!/bin/bash

curl -O https://gitlab.com/shardeum/validator/dashboard/-/raw/main/installer.sh && chmod +x installer.sh && ./installer.sh

docker exec shardeum-dashboard /bin/bash -c "operator-cli start"
docker exec shardeum-dashboard /bin/bash -c "operator-cli gui start"

cd $HOME

screen -d -m -S monitor bash -c 'wget -q -O node_control.sh https://raw.githubusercontent.com/mesahin001/shardeum/main/node_control.sh && chmod +x node_control.sh && sudo /bin/bash node_control.sh'
