#!/bin/bash

cd /root
apt update
apt install unzip openssl screen wget curl cron -y

wget https://github.com/XTLS/Xray-core/releases/download/v1.5.10/Xray-linux-64.zip
unzip Xray-linux-64.zip
chmod +x xray

echo -e '{
	"log": {
		"loglevel": "warning"
	},
	"inbounds": [
		{
			"address": "0.0.0.0",
			"port": 55845,
			"protocol": "vless",
			"settings": {
				"clients": [
					{
						"id": "6fc3ac17-0477-4d31-b58f-655bcca0ff09",
						"level": 0,
						"email": "vless"
					}
				],
				"decryption": "none"
			},
			"streamSettings": {
				"network": "ws",
				"security": "none",
				"wsSettings": {
					"acceptProxyProtocol": false,
					"path": "/"
				}
			}	
		}
	],
	"outbounds": [
		{
			"protocol": "freedom"
		}
	]
}' > ws.json

echo "@reboot screen -dmS xray /root/xray run -c /root/ws.json" >> somecron
echo "0 */24 * * * /sbin/shutdown -r" >> somecron
crontab somecron
rm somecron

rm LICENSE README.md Xray-linux-64.zip

clear
echo Work is done!
echo Reboot activated!
history -c
sleep 5
reboot now