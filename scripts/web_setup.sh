#! /bin/bash

webServers=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}' | grep $webServerName`)
ipList=()
webNames=()
for i in ${!webServers[@]}; do
    ip=$(openstack server show ${webServers[$i]} | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
    ipList+=("$ip")
    webNames+=("$webServerHostName$i")
done

# All commands that will be executed over paralell ssh
commands=("
sudo apt install nginx -y;
sudo systemctl start nginx.service;
sudo apt-get install mariadb-client;
sudo apt get install crontab;
sudo systemctl start mysql.service;
sudo mysql_secure_installation;
sudo adduser ubuntu www-data;
sudo chown -R www-data:www-data /var/www;
sudo chmod -R g+rw /var/www;
sudo apt-get install php-fpm -y;
sudo apt install git-all
") # Is apt install git-all correct?? yas

parallel-ssh -i -H "${ipList[*]}" \
        -l $username \
        -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
        "$commands"

echo "'$sshKeyLocation'"
# installation off nginx
sudo apt update
sudo apt install nginx -y

# starting nginx
sudo systemctl start nginx.service

# MariaDB installation
# STOP: sudo systemctl stop nginx.service
# ENABLE: sudo systemctl enable nginx.service
# Adding the database client
sudo apt-get install mariadb-client

#install off crontab
sudo apt get install crontab

# starting database
# STOP: sudo systemctl stop mysql.service
# ENABLE: sudo systemctl enable mysql.service
sudo systemctl start mysql.service

# creating a root password and disallowing remote root access
sudo mysql_secure_installation

# add user
sudo adduser ubuntu www-data


# change ownership
sudo chown -R www-data:www-data /var/www

# LOOK INTO PREMISION HANDLING
# give full premision
sudo chmod -R g+rw /var/www

# PHP instalation
sudo apt-get install php-fpm -y

# Installing git to pull down repo from git
sudo apt install git-all


# nginx config for php init
sudo bash -c "echo 'server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php test.php index.html index.htm index.nginx-debian.html;

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
}' > /etc/nginx/sites-available/default"


# Template for nginx config with a placeholer
nginxTemplate="echo 'server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php test.php index.html index.htm index.nginx-debian.html;

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
}' > /etc/nginx/sites-available/default"

# Replacing server_name in the nginx config file with looking up how maney web servers that is running and tha itterating over them.
# Constrain: will only work if all the web servers have the same name just with a integer increment after.
nginxConfig=()
for i in "${webNames[@]}"; do
    echo "kom hit 123"
    nginxConfig+=(`echo $configTemplate | sed "s/PLACEHOLDER/$i/g"`)
done


echo "kom hit 12345t678"
ssh -i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand' $username@

for vm in ${webServers[@]}; do
    openstack server reboot --wait $vm
done

#### Still figuring out how to make separate configs for the different webservers
# Will be inited separatply over ssh/scp maybe?

# Script that get executed by the crontab command under.
# Since we itterate over the webservers and push to each one we needed to make a script file for it.

# Do all this on web1
if [[ $hs = "web1" ]]; then
    sudo bash -c "echo '
        #!/bin/sh
        cd /var/www/html
        git pull
        for i in 2 3; do
            rsync -avz -e ssh -i dats06-key.pem /var/www/html ubuntu@$webServerHostName$i:/var/www/html
        done' > rsyncScript.sh"
    git clone https://github.com/JakobSimonsen/Portfolio_exam_deployment.git /var/www/html
#if [[ $hs = "web1" ]]; then
    sudo apt-get install cron
    (crontab -l ; echo "*/3 * * * * /bin/sh /home/ubuntu/rsyncScript.sh") | crontab -
fi
