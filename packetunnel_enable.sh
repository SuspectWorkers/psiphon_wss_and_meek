#!/bin/bash

read -p "Do you want to enable PacketTunnel? (y / n)? " yn
    if [[ "$yn" =~ 'n' ]]; then exit; fi

ifconfig
echo 'Enter your interface name (Enter only one)! (Example: venet0, esp0s3)'
read interf

cd /root
apt update
apt install jq -y
jq -c '.RunPacketTunnel = true' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
jq -c '.PacketTunnelEgressInterface = "'${interf}'"' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
clear
echo 'Done!'
