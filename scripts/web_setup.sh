#! /bin/bash

# This loop gets all the web server names from ALTO, then
# finds each IP for the web servers
echo "Gathering necessary IPs and machine names"
webServers=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}' | grep $webServerName`)
ipList=()
webNames=()
for vm in ${webServers[@]}; do
    ip=$(openstack server show $vm | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
    ipList+=("$ip")
    webNames+=(`echo $vm | sed -E s/$webServerName-/$webServerHostName/g`)
done

# All commands that will be executed over paralell ssh
# Commands have all the installs that is needed on all the webservers
# It also have premision regulation to /var/www
commands=("
sudo apt-get install nginx -y;
sudo systemctl start nginx.service;
sudo adduser ubuntu www-data;
sudo chown -R www-data:www-data /var/www;
sudo chmod -R g+rw /var/www;
sudo apt-get install php-fpm -y;
sudo apt-get install php-mysql -y
")

# Parallel-ssh excecution
parallel-ssh -i -H "${ipList[*]}" \
        -l $username \
        -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
        "$commands"

# Replacing server_name in the nginx config file with looking up how many web servers that is running and tha itterating over them.
# Constrain: will only work if all the web servers have the same name just with a integer increment after.

# Template for nginx config with a placeholer
nginxTemplate=("server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index AVAILABLESITES index.html index.htm index.nginx-debian.html;

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

nginxTemplate=`echo "$nginxTemplate" | sed "s/AVAILABLESITES/$CUSTOMAVAILABLESITES/g"`

# Dynamic itteration for each webserv created, getting the amount off webservers from parameter file.
# Setting up nginx config for each web server with specified name by using a template shown over and replaceing "PLACEHOLDER".
# Then restarts the nginx service
echo "Setting up nginx on all webservers"
for i in ${!webNames[@]}; do
    nginxConfig=`echo "$nginxTemplate" | sed "s/PLACEHOLDER/${webNames[$i]}/g"`
    ssh -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" $username@${ipList[$i]} \
    "sudo bash -c 'echo \"$nginxConfig\" > /etc/nginx/sites-available/default'; sudo service nginx restart"
done

# rsync script that will be injected to the first web server
rsyncScript=('#!/bin/bash
webs=""
cd /var/www/html
git pull
for web in $webs; do
    rsync -chavz --delete --exclude ".*" -e "ssh -i ~/.ssh/KEY.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" /var/www/html ubuntu@$web:/var/www/
done
')

# Finding the main web server
temp=()
for i in ${!webNames[@]}; do
    if [[ ! ${webNames[$i]} = $webServerHostName"1" ]]; then
        temp+=(${webNames[$i]})
    else
        primary=${webNames[$i]}
        primaryIP=${ipList[$i]}
    fi
done

# incerting the other web server names into the rsync script
# then replaces the KEY placeholer
rsyncScript=`echo "$rsyncScript" | sed "/webs=/ s/^\(.*\)\(\"\)/\1${temp[*]}\2/"`
rsyncScript=`echo "$rsyncScript" | sed "s/KEY/$keyPairName/g"`

# Copying the ssh key so that the main web server is able to authorize while rsyncing to the other web servers
scp -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="$sshProxyCommand" "$sshKeyLocation" $username@$primaryIP:

# Commands that will be executed on the main web server
commands=("
mv $keyPairName.pem .ssh/;
echo '$rsyncScript' > rsyncScript.sh;
sudo apt-get install cron -y;
sudo apt-get install git -y;
sudo rm -r /var/www/html;
git clone $GITPHPDEPLOYMENT /var/www/html;
(crontab -l ; echo \"*/3 * * * * /bin/sh /home/ubuntu/rsyncScript.sh\") | crontab -;
")

# executing the commands above on the main web server
echo "Setting up the main web server"
ssh -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" $username@$primaryIP \
  "$commands"
