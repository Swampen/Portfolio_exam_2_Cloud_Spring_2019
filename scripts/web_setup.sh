#! /bin/bash

webServers=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}' | grep $webServerName`)
ipList=()
webNames=()
for vm in ${webServers[@]}; do
    ip=$(openstack server show $vm | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
    ipList+=("$ip")
    webNames+=(`echo $vm | sed -E s/$webServerName-/$webServerHostName/g`)
done

# All commands that will be executed over paralell ssh
commands=("
sudo apt-get install nginx -y;
sudo systemctl start nginx.service;
sudo adduser ubuntu www-data;
sudo chown -R www-data:www-data /var/www;
sudo chmod -R g+rw /var/www;
sudo apt-get install php-fpm -y;
sudo apt-get install php-mysql -y
")

parallel-ssh -i -H "${ipList[*]}" \
        -l $username \
        -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
        "$commands"

# Replacing server_name in the nginx config file with looking up how maney web servers that is running and tha itterating over them.
# Constrain: will only work if all the web servers have the same name just with a integer increment after.

# Template for nginx config with a placeholer
nginxTemplate=("server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php ting.php test.php index.html index.htm index.nginx-debian.html;

    server_name PLACEHOLDER;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}")

for i in ${!webNames[@]}; do
    nginxConfig=`echo "$nginxTemplate" | sed "s/PLACEHOLDER/${webNames[$i]}/g"`
    ssh -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" $username@${ipList[$i]} \
    "sudo bash -c 'echo \"$nginxConfig\" > /etc/nginx/sites-available/default'; sudo service nginx restart"
done

rsyncScript=('#!/bin/bash
webs=""
cd /var/www/html
git pull
for web in $webs; do
    rsync -avz --delete --exclude ".*" -e "ssh -i ~/.ssh/KEY.pem" /var/www/html ubuntu@$web:/var/www/html
done
')

temp=()
for i in ${!webNames[@]}; do

    if [[ ! ${webNames[$i]} = $webServerHostName"1" ]]; then
        temp+=(${webNames[$i]})
    else
        primary=${webNames[$i]}
        primaryIP=${ipList[$i]}
    fi
done

rsyncScript=`echo "$rsyncScript" | sed "/webs=/ s/^\(.*\)\(\"\)/\1${temp[*]}\2/"`
rsyncScript=`echo "$rsyncScript" | sed "s/KEY/$keyPairName/g"`

scp -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$sshProxyCommand" "$sshKeyLocation" $username@$primaryIP:

commands=("
mv $keyPairName.pem .ssh/;
echo '$rsyncScript' > rsyncScript.sh;
sudo apt-get install cron
sudo apt-get install git-all
sudo rm -r /var/www/html
git clone https://github.com/JakobSimonsen/Portfolio_exam_deployment.git /var/www/html;
")
#(crontab -l ; echo \"*/3 * * * * /bin/sh /home/ubuntu/rsyncScript.sh\") | crontab -;

ssh -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" $username@$primaryIP \
"$commands"
