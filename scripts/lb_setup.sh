#! /bin/bash

sudo apt-get update
sudo apt-get install haproxy -y
sudo sed -i '$ a ENABLED=1' /etc/default/haproxy
sudo sed -i "s/.*CONFIG=.*/CONFIG=\"\/etc\/haproxy\/haproxy.cfg\"/g" /etc/default/haproxy

