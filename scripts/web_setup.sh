#! /bin/bash

#! installation off nginx
sudo apt update
sudo apt install nginx

#! starting nginx
sudo systemctl start nginx.service

#! mariaDB installation
#! STOP: sudo systemctl stop nginx.service
#! ENABLE: sudo systemctl enable nginx.service
sudo apt-get install mariadb-server mariadb-client

#! starting database
#! STOP: sudo systemctl stop mysql.service
#! ENABLE: sudo systemctl enable mysql.service
sudo systemctl start mysql.service

#! creating a root password and disallowing remote root access
sudo mysql_secure_installation


