#!/bin/bash

read -p "Do you wish to install this program? (y / n)? " yn
    if [[ "$yn" =~ 'n' ]]; then exit; fi

echo 'Server must have x86_64 architecture to continue!!'
echo 'No Ampere(Arm\aarch64) and x86 servers supported at the moment!!'
echo 'Enter the domain for FRONTED-MEEK-OSSH (Fastly Endpoint) (Fastly,azure and other CDNs)! (Example: somedomain.com.global.prod.fastly.net)'
read fastly_endpoint
echo 'Enter the domain for FRONTED-WSS-OSSH (Cloudflare mainly, websocket)! (Example: cf.somedomain.com)'
read cf_url
ifconfig
echo 'Enter your interface name (Enter only one)! (Example: venet0, esp0s3)'
read interf

cd /root
apt update
apt install unzip cmake openssl screen wget nginx curl jq ufw -y
mkdir -p /etc/ssl/v2ray/ && sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/v2ray/priv.key -out /etc/ssl/v2ray/cert.pub -subj "/C=US/ST=Oregon/L=Portland/O=TranSystems/OU=ProVPN/CN=${url}"

curl https://raw.githubusercontent.com/mukswilly/psicore-binaries/master/psiphond/psiphond -o psiphond
chmod +x psiphond
./psiphond -ipaddress 127.0.0.1 -protocol FRONTED-MEEK-OSSH:2052 -protocol FRONTED-WSS-OSSH:2053 generate
jq -c '.RunPacketTunnel = "true"' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
jq -c '.PacketTunnelEgressInterface = "${interf}"' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
entry=$(cat server-entry.dat | xxd -r -p)
echo ${entry:8} > entry.json
cf_url=$(echo '"'${cf_url}'"')
fastly_endpoint=$(echo '"'${fastly_endpoint}'"')
jq -c ".meekFrontingHosts = ["${fastly_endpoint}"]" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.meekFrontingAddresses = ["speedtest.net","image-sandbox.tidal.com","f.cloud.github.com","docs.github.com","linktr.ee","www.paypal.com"]' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c ".wsFrontingHosts = ["${cf_url}"]" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.wsFrontingAddresses = ["ru.music-lord.com","who.int","discord.com"]' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c ".wsFrontingSNI = ["${cf_url}"]" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
entry1=$(cat entry.json | xxd -p)
entry2=$(echo 3020302030203020${entry1} | tr -d '[:space:]')
entry3=${entry2::-2}
echo ${entry3} > psi.html
mv psi.html /var/www/html/psi.html
screen -dmS psiphon ./psiphond run
chmod 777 /var/www/html/psi.html

echo 'server {
        listen 443 ssl;
        listen 80;

        #sslka
        ssl_certificate /etc/ssl/v2ray/cert.pub;
        ssl_certificate_key /etc/ssl/v2ray/priv.key;

        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        server_name _;
		
		location /psi {
            default_type "text/html";
            alias /var/www/html/psi.html;
        }

        location / {
                proxy_redirect off;
                proxy_pass https://127.0.0.1:2052;
                proxy_http_version 1.1;
        }
}' > /etc/nginx/sites-available/default

echo 'server {
        listen 443 ssl;
        listen 80;

        #sslka
        ssl_certificate /etc/ssl/v2ray/cert.pub;
        ssl_certificate_key /etc/ssl/v2ray/priv.key;

        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        server_name '${cf_url}';
		
        location /psi {
            default_type "text/html";
            alias /var/www/html/psi.html;
        }

        location / {
                proxy_redirect off;
                proxy_pass https://127.0.0.1:2053;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $host;
        }
}' > /etc/nginx/sites-available/wss

sudo ln -s /etc/nginx/sites-available/wss /etc/nginx/sites-enabled/

echo 'Include /etc/ssh/sshd_config.d/*.conf
Port 777
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

echo "@reboot root screen -dmS psiphon ./psiphond run" | sudo tee -a /etc/crontab
echo "0 */12 * * * root /sbin/shutdown -r" | sudo tee -a /etc/crontab
rm entry.json
clear
echo Work is done!
echo Reboot activated!
history -c
sleep 5
reboot now
