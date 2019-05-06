#! /bin/bash

sudo apt-get update
sudo apt-get install haproxy -y
sudo sed -i '$ a ENABLED=1' /etc/default/haproxy
sudo sed -i "s/.*CONFIG=.*/CONFIG=\"\/etc\/haproxy\/haproxy.cfg\"/g" /etc/default/haproxy

config"frontend web-frontend
        bind *:80
	mode http
	default_backend web-backend

backend web-backend
    balance roundrobin
    mode http
    option httpchk HEAD / HTTP/1.1\r\nHost:\ localhost
    server web-1 web1:80 check weight 10
    server web-2 web2:80 check weight 10
    server web-3 web3:80 check weight 10
    stats enable
    stats refresh 30s
    stats uri /stats
    stats realm Haproxy\ Statistics
    stats auth dats06:\"thrown similar river\""



sudo apt-get install -y apache2 munin
sudo sed -i 's/.*htmldir.*/htmldir \/var\/www\/html\/munin/g' /etc/munin/munin.conf
sudo mkdir /var/www/html/munin
sudo chown munin:munin /var/www/html/munin
sudo sed -i 's/localhost.localdomain/MuninMonitor/g' /etc/munin/munin.conf
sudo sed -i 's/\/var\/cache\/munin\/www/\/var\/www\/html\/munin/g' /etc/munin/apache24.conf
sudo sed -i '0,/Require/{s/Require.*/Require all granted/}' /etc/munin/apache24.conf
