#!/bin/bash

read -p "Do you wish to install this program? (y / n)? " yn
    if [[ "$yn" =~ 'n' ]]; then exit; fi

echo 'Server must have x86_64 architecture to continue!!'
echo 'No Ampere(Arm\aarch64) and x86 servers supported at the moment!!'
echo 'Enter the domain for FRONTED-MEEK-OSSH (Fastly Endpoint) (Fastly,azure and other CDNs)! (Example: somedomain.com.global.prod.fastly.net)'
read fastly_endpoint
echo 'Enter the domain for FRONTED-WSS-OSSH (Cloudflare\Gcore mainly, websocket)! (Example: cf.somedomain.com)'
read cf_url
echo 'Enter the domain for local caching ! (Example: 1.somedomain.com)'
read local_cache
echo 'Enter the domain for 80 port psiphon ! (Example: 80.somedomain.com)'
read eightyport
#ifconfig
#echo 'Enter your interface name (Enter only one)! (Example: venet0, esp0s3)'
#read interf

cd /root
apt update
apt install unzip cmake openssl screen wget nginx curl jq ufw python2 -y
mkdir -p /etc/ssl/v2ray/ && sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/v2ray/priv.key -out /etc/ssl/v2ray/cert.pub -subj "/C=US/ST=Oregon/L=Portland/O=TranSystems/OU=ProVPN/CN=cosmos.com"

curl https://raw.githubusercontent.com/mukswilly/psicore-binaries/master/psiphond/psiphond -o psiphond
chmod +x psiphond
./psiphond -ipaddress 127.0.0.1 -protocol FRONTED-MEEK-OSSH:2052 -protocol FRONTED-WSS-OSSH:2053 -protocol FRONTED-MEEK-HTTP-OSSH:2054 generate

#jq -c '.RunPacketTunnel = true' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
#jq -c '.PacketTunnelEgressInterface = "'${interf}'"' psiphond.config  > tmp.$$.json && mv tmp.$$.json psiphond.config
entry=$(cat server-entry.dat | xxd -r -p)
echo ${entry:8} > entry.json
entry=$(cat server-entry.dat | xxd -r -p)
echo ${entry:8} > entry2.json
cf_url=$(echo '"'${cf_url}'"')
fastly_endpoint=$(echo '"'${fastly_endpoint}'"')
jq -c ".meekFrontingHosts = ["${fastly_endpoint}"]" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.meekFrontingAddresses = ["speedtest.net","image-sandbox.tidal.com","f.cloud.github.com","docs.github.com","linktr.ee","www.paypal.com"]' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c ".wsFrontingHosts = ["${cf_url}"]" entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.wsFrontingAddresses = ["cdnhealth.www.tinkoff.ru","mm.tinkoff.ru"]' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.meekServerPort = 443' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c '.wsServerPort = 443' entry.json  > tmp.$$.json && mv tmp.$$.json entry.json
jq -c ".meekFrontingHosts = ["${fastly_endpoint}"]" entry2.json  > tmp.$$.json && mv tmp.$$.json entry2.json
jq -c '.meekFrontingAddresses = ["speedtest.net","image-sandbox.tidal.com","f.cloud.github.com","docs.github.com","linktr.ee","www.paypal.com"]' entry2.json  > tmp.$$.json && mv tmp.$$.json entry2.json
jq -c ".wsFrontingHosts = ["${cf_url}"]" entry2.json  > tmp.$$.json && mv tmp.$$.json entry2.json
jq -c '.wsFrontingAddresses = ["cdnhealth.www.tinkoff.ru","mm.tinkoff.ru"]' entry2.json  > tmp.$$.json && mv tmp.$$.json entry2.json
jq -c '.meekServerPort = 80' entry2.json  > tmp.$$.json && mv tmp.$$.json entry2.json
jq -c '.wsServerPort = 80' entry2.json  > tmp.$$.json && mv tmp.$$.json entry2.json
#jq -c ".wsFrontingSNI = "${cf_url}"" entry2.json  > tmp.$$.json && mv tmp.$$.json entry2.json
entry1=$(cat entry.json | xxd -p)
entry2=$(echo 3020302030203020${entry1} | tr -d '[:space:]')
entry3=${entry2::-2}
echo ${entry3} > psi_443.html

entry1=$(cat entry2.json | xxd -p)
entry2=$(echo 3020302030203020${entry1} | tr -d '[:space:]')
entry3=${entry2::-2}
echo ${entry3} > psi_80.html

mv psi_80.html /var/www/html/
mv psi_443.html /var/www/html/
screen -dmS psiphon ./psiphond run
chmod 777 /var/www/html/psi_443.html
chmod 777 /var/www/html/psi_80.html

wget https://raw.githubusercontent.com/SuspectWorkers/testtt/main/ssh.py
screen -dmS proxy python2 ssh.py
wget https://github.com/ambrop72/badvpn/archive/refs/tags/1.999.130.zip
unzip 1.999.130.zip
cd badvpn-1.999.130
cmake ~/badvpn-1.999.130 -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
screen -dmS udp badvpn-udpgw --listen-addr 127.0.0.1:7300
cd ..

sudo adduser sshc --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --shell=/bin/false --no-create-home
echo "sshc:sshc228" | sudo chpasswd

echo 'server {
        listen 443 ssl;
        listen 80;
        #sslka
        ssl_certificate /etc/ssl/v2ray/cert.pub;
        ssl_certificate_key /etc/ssl/v2ray/priv.key;
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        server_name _;
		
	location /psi443 {
            default_type "text/html";
            alias /var/www/html/psi443.html;
        }
	
	location /psi80 {
            default_type "text/html";
            alias /var/www/html/psi80.html;
        }
	
        location / {
                proxy_redirect off;
                proxy_pass https://127.0.0.1:2052;
                proxy_http_version 1.1;
        }
		
	location /ssh {
                proxy_redirect off;
                proxy_pass http://127.0.0.1:33193;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $host;
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
        server_name '${local_cache}';
		
        location /psi443 {
            default_type "text/html";
            alias /var/www/html/psi443.html;
        }
	
	location /psi80 {
            default_type "text/html";
            alias /var/www/html/psi80.html;
        }
	
        location / {
                proxy_redirect off;
                proxy_pass https://127.0.0.1:2053;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $host;
        }
		
	location /ssh {
                proxy_redirect off;
                proxy_pass http://127.0.0.1:33193;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $host;
        }
}' > /etc/nginx/sites-available/wss

echo 'server {
        listen 443 ssl;
        listen 80;
        #sslka
        ssl_certificate /etc/ssl/v2ray/cert.pub;
        ssl_certificate_key /etc/ssl/v2ray/priv.key;
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        server_name '${local_cache}';
		
        location /psi443 {
            default_type "text/html";
            alias /var/www/html/psi443.html;
        }
	
	location /psi80 {
            default_type "text/html";
            alias /var/www/html/psi80.html;
        }
	
        location / {
                proxy_redirect off;
                proxy_pass http://127.0.0.1:2054;
                proxy_http_version 1.1;
        }
		
	location /ssh {
                proxy_redirect off;
                proxy_pass http://127.0.0.1:33193;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $host;
        }
}' > /etc/nginx/sites-available/eightyport

sudo ln -s /etc/nginx/sites-available/wss /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/eightyport /etc/nginx/sites-enabled/

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

echo "@reboot root screen -dmS psiphon ./psiphond run" | sudo tee -a /etc/crontab
echo "@reboot root screen -dmS proxy python2 ssh.py" | sudo tee -a /etc/crontab
echo "@reboot root screen -dmS udp badvpn-udpgw --listen-addr 127.0.0.1:7300" | sudo tee -a /etc/crontab
echo "0 */12 * * * root /sbin/shutdown -r" | sudo tee -a /etc/crontab

rm entry.json
rm LICENSE README.md Xray-linux-64.zip
rm -rf badvpn-1.999.130
rm 1.999.130.zip

clear
echo Work is done!
echo Reboot activated!
history -c
sleep 5
reboot now
