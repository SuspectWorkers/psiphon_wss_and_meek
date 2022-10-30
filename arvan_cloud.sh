#!/bin/bash

read -p "Do you wish to install this program? (y / n)? " yn
    if [[ "$yn" =~ 'n' ]]; then exit; fi

echo 'Enter the uuid for v2ray websocket'
read uuid

cd /root
apt update
apt install unzip openssl screen wget curl ufw cron -y
mkdir -p /etc/ssl/v2ray/ && sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/v2ray/priv.key -out /etc/ssl/v2ray/cert.pub -subj "/C=US/ST=Oregon/L=Portland/O=TranSystems/OU=ProVPN/CN=cosmos.com"

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
			"port": 443,
			"protocol": "vless",
			"settings": {
				"clients": [
					{
						"id": "'${uuid}'",
						"level": 0,
						"email": "vless"
					}
				],
				"decryption": "none"
			},
			"streamSettings": {
				"network": "ws",
				"security": "tls",
				"tlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/etc/ssl/v2ray/cert.pub",
                            "keyFile": "/etc/ssl/v2ray/priv.key"
                        }
                    ]
                },
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

echo 'Port 777
ListenAddress 0.0.0.0
PermitRootLogin yes
PasswordAuthentication yes
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem	sftp	/usr/lib/openssh/sftp-server' > /etc/ssh/sshd_config

ufw --force enable
ufw allow 777
ufw allow 443

systemctl restart ssh
systemctl restart sshd

echo "0 */12 * * * /sbin/shutdown -r" >> somecron
crontab somecron
rm somecron

echo '[Unit]
Description=Xray 443 ws
Documentation=https://nekopoi.care
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/root/xray run -c /root/ws.json
Restart=on-failure

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/xray.service

systemctl daemon-reload
systemctl enable /etc/systemd/system/xray.service
systemctl start /etc/systemd/system/xray.service

rm LICENSE README.md Xray-linux-64.zip

clear
echo Work is done!
echo Reboot activated!
history -c
sleep 5
reboot now
