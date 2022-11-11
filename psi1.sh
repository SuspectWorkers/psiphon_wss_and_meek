#!/bin/bash

cd /root
apt update
apt install unzip openssl screen wget curl ufw cron nginx -y
mkdir -p /etc/ssl/v2ray/ && sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/v2ray/priv.key -out /etc/ssl/v2ray/cert.pub -subj "/C=US/ST=Oregon/L=Portland/O=TranSystems/OU=ProVPN/CN=cosmos.com"

curl https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/psiphond/psiphond -o psiphond
chmod +x psiphond
./psiphond -ipaddress 127.0.0.1 -protocol FRONTED-MEEK-OSSH:33190 generate
cp server-entry.dat /var/www/html/psi.html
chmod 777 /var/www/html/psi.html

echo 'server {
	listen [::]:80 default_server;
	listen [::]:443 http2 ssl default_server;
	listen 80 default_server;
	listen 443 http2 ssl default_server;
	

	#sslka
	ssl_certificate /etc/ssl/v2ray/cert.pub;
	ssl_certificate_key /etc/ssl/v2ray/priv.key;
	ssl_protocols SSLv2 SSLv3 TLSv1.2 TLSv1.3;
	ssl_prefer_server_ciphers on;
	ssl_ciphers EECDH+AESGCM:EECDH+AES256;
	add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
	
	root /var/www/html;
	index index.html index.htm index.nginx-debian.html;
	server_name _;
	
	location /psi {
			default_type "text/html";
			alias /var/www/html/psi.html;
	}
	
	location / {
			proxy_redirect off;
			proxy_http_version 1.1;
			proxy_pass https://127.0.0.1:33190;
	}

}' > /etc/nginx/sites-enabled/default

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
ufw allow 80
ufw allow 443

systemctl restart ssh
systemctl restart sshd



echo "[Unit]
Description=Psiphon
Documentation=Psiphon Fronted-MEEK
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root/
ExecStart=/bin/bash -c '/root/psiphond run'
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/psiphon.service

systemctl daemon-reload
systemctl enable psiphon


echo "0 */12 * * * root /sbin/shutdown -r" > cron
crontab cron
rm cron

clear
echo Work is done!
echo Reboot activated!
history -c
rm .bash_history
sleep 2
reboot now
