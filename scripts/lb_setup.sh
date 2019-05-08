#! /bin/bash

webServers=()
webs=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}' | grep $webServerName | sed s/$webServerName-/$webServerHostName/g`)
HAProxyEntry=""
for i in ${!webs[@]}; do
    HAProxyEntry="server $webServerHostName-$i ${webs[$i]}:80 check weight 10 \\n$HAProxyEntry"
done

setup=("
sudo apt-get install haproxy -y
sudo sed -i '$ a ENABLED=1' /etc/default/haproxy
sudo sed -i "s/.*CONFIG=.*/CONFIG=\"\/etc\/haproxy\/haproxy.cfg\"/g" /etc/default/haproxy

echo bash -c 'frontend web-frontend
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

    # Monitoring
    stats enable
    stats refresh 30s
    stats uri /stats
    stats realm Haproxy\ Statistics
    stats auth dats06:\"thrown similar river\"'
")
