

curl -O https://gitlab.com/shardeum/validator/dashboard/-/raw/main/installer.sh && chmod +x installer.sh && ./installer.sh

cd .shardeum
./shell.sh
operator-cli gui start
operator-cli start

exit

cd $HOME

screen -d -m -S monitor bash -c 'wget -q -O node_control.sh https://raw.githubusercontent.com/mesahin001/shardeum/main/node_control.sh && chmod +x node_control.sh && sudo /bin/bash node_control.sh'
