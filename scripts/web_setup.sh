#! /bin/bash


#Hostname File

#! installation off nginx
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

                # Need to be changed dynamically by the script
    server_name server_name_or_IP;

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

# Reboot to activate config
sudo service nginx restart

hs=`hostname`

if [[ $hs = "web1" ]];
then

    #Going to production directory
        #git init and pulling down the files used in this project
        git clone https://github.com/JakobSimonsen/Portfolio_exam_deployment.git /var/www/html
        

fi

# Script that get executed by the crontab command under.
# Since we itterate over the webservers and push to each one we needed to make a script file for it.
cd ~/
    sudo bash -c "echo '#!/bin/sh
cd /var/www/html
git pull
for i in 2 3
do
    rsync -avz -e ssh -i dats06-key.pem /var/www/html ubuntu@web\$i:/var/www/html
done' > rsyncScript.sh"

# Initial pull down from git repo
cd /var/www/html
    git pull


hs=`hostname`

if [[ $hs = "web1" ]];
then
sudo apt-get install cron
(crontab -l ; echo "*/3 * * * * /bin/bash /home/ubuntu/rsyncScript.sh")| crontab -
fi