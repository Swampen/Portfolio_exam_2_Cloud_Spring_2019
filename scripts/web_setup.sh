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

# nginx config for php init
sudo bash -c "echo 'server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/Portfolio_exam_deployment;
    index index.php index.html index.htm index.nginx-debian.html;

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
sudo reboot

hs=`hostname`

if [ $hs = web1 ];
then

    #initing all the needed config and setting keygen for github repo
    cd .ssh
        touch config
            sudo bash -c "echo 'host github.com
            IdentityFile ~/.ssh/id_rsa' > config"
        touch id_rsa
            sudo bash -C "echo '
                -----BEGIN RSA PRIVATE KEY-----
                MIIEpAIBAAKCAQEAyr6tYT1+2Aiq1YL3V9XWq3BrYIsYGgg5Pwp8XBhvWEnydi/s
                OAdJnTMBi015mYCTQcVrIG0+FHsCK+wSsz0SxOVxqDK/h7M7c43EpQyzvPs3nbBk
                V3oJsT3/rERnW0HxhBdxWJSnhLpkIVH9/5geTeeVwddTR+odxhcddVYmw25HPksM
                cHSaz7NAJQUs3imFF64fu12CgefndLzQyqO0xHimPObsYZrihaq7FaNYKRpFMP57
                PKYCpmH/ZAceRQWZLPULWG+wkjQL4PpRaZO37rhyVxwDwW2n3fQo5Xr78pngYsHK
                D1da4QeIegIBXpIoV9OxVw7xRh9rteYuxfK35QIDAQABAoIBAHHrIdB5lUQd2p+N
                rx0TckNyL2NXxHscE85wPeAheq7JHgt6cegpcBt8BWoYZjLyI8vY+ZCG0VMAqv+y
                7e74agtoQKyZlzTQaJ9NESkMMhIFtgJMkpT0ZW3JwFczOD/2lZX69h0nqdjSQmDW
                iTmMZ7quXV9Fde36hjA/3LWJas5zsB7mmrDENxWeGQDUK3HnhGY+PuCyXTN/sFHK
                oxs6SJjwHsJW+PMGwOphasy65YnTkaKQ+Y2SeAL/PJM/wHT+YIq57Jm9SknC++1S
                RQq5v4Id7WVZkgQE2IXBgoPl7sab3W1d0xFMlxjTk3mfYKgBDtZZNmY4MFEqbllb
                iY4FeCECgYEA7hsbSlXWyZC1SKdrD1a14VN2XCqRveY2TQLpJ7gYzUHn3YJk0me1
                dGVWLrnlasFKtZyBEXHkz5K0IVJpzgRFrMAmj26kR9EkOTIg0qke+TVSQ5zRQFkX
                MWenKY42QhoGAH0IbbORyR6z4yWHQ5gxI0pitGfqjgVRUqlJqzFoeH8CgYEA2ftD
                YSt5x4AjS2wohJlIqRDIVGWS4zY3Y3xfjlYF2DF4+4tcl+6p8wpYhEBW2va8Z6kp
                LqB1aW5k2MScrQr6K6cTLKKX00PjrhXrG+M5cWQoZYrNocbWSskZRdMCvzWMj5RV
                3GRzQU0Do+dJHbd2ReefSHbpDkM7qh/z3cdEvZsCgYAJWvlMh2jkDJKC40kali6Z
                Rt08q9OEIZp6liWxENOwpOlGU8xAVCDWDPFA7r7r3eJglmCf3di+qyX2tTVBCfvu
                2LHrKs67n6ULtkOB43E7G3Q7Adta6uU1ZLw1rsfE+x7HQCJnpQmSXGl3AE97QWyU
                1WRhcD/QCrdyRwKE/nD7YwKBgQCg9mOY+0ufv8VQSnvY/n+jKFtlxuOimERqWEsP
                hgIm1NFrnksvffNNHtSiRAhfBFe3jDh2z9IjmnspfnXbagG1/lewXBgUz0rvIAxO
                uYmPa9BQuyCBV5yh+MGKx/h9TYOP+o80gZCCJeaMP5vEL9dMY29BSV1rRMZoJ9Qi
                bqUaBQKBgQCGS8nso1u6oGoGvJ9Jz7mXwMUkymGv2Tqiw0YCjJYQTSlQ0YEYDm2D
                /ZhVrlVzh2yq/X97wqfaXKX8sSyb5jqgMzLXl2hKoH+WnHJ0Rv7PB90DnFd8SYLs
                sOnJUJQ+qkS0cWXL7S0iaEPBKTgLEo7JpcQXTRJqxmRY3ZfaMyNCBQ==
                -----END RSA PRIVATE KEY-----' > id_rsa"
        touch id_rsa.pub
            sudo bash -C "echo 
                'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKvq1hP
                X7YCKrVgvdX1darcGtgixgaCDk/CnxcGG9YSfJ2L+w4B0mdMwGLTXmZgJNBxWsgbT
                4UewIr7BKzPRLE5XGoMr+HsztzjcSlDLO8+zedsGRXegmxPf+sRGdbQfGEF3FYlKe
                EumQhUf3/mB5N55XB11NH6h3GFx1$' > id_rsa.pub"
    
    #Going to production directory
    cd /var/www/
        #git init and pulling down the files used in this project
        git clone https://github.com/JakobSimonsen/Portfolio_exam_deployment.git
        #sleep function to ensure that the github repo is cloned down before going to the next task.
        sleep 10

fi

#for loop for iterating over the web servers to push to so if we scale up we dont duplicate alot off code.
for i in 2 3
do

#pushing from "main web server to webserver - 2"
*/3 * * * * rsync -avz -e 'ssh -i dats06-key.pem' /var/www ubuntu@web$i: /var/www
done
