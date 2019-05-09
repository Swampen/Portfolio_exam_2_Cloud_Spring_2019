#! /bin/bash

webServers=()
webs=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}' | grep $webServerName | sed s/$webServerName-/$webServerHostName/g`)
HAProxyEntry=""
for i in ${!webs[@]}; do
    let n=$i+1
    HAProxyEntry="    server $webServerHostName-$n ${webs[$i]}:80 check weight 10 \\n$HAProxyEntry"
done

lbvm=`openstack server list -c Name | awk '!/^$|Name/ {print $2;}' | grep $LBName`
lbIP=`openstack server show $lbvm | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}"`

lbConfigTemplate=('
frontend web-frontend
    bind *:80
    mode http
    default_backend web-backend

backend web-backend
    balance roundrobin
    mode http
    option httpchk HEAD / HTTP/1.1\r\nHost:\ localhost
PLACEHOLDER

    # Monitoring
    stats enable
    stats refresh 30s
    stats uri /stats
    stats realm Haproxy\ Statistics
    stats auth USER:\"PASS\"
')

lbConfig=`echo "$lbConfigTemplate" | sed "s/PLACEHOLDER/$HAProxyEntry/g" | sed "s/PASS/$LBSTATPASSWD/g" |  sed "s/USER/$LBSTATUSER/g"`

commands=("
sudo apt-get install haproxy -y;
sudo sed -i '$ a ENABLED=1' /etc/default/haproxy;
sudo sed -i 's/.*CONFIG=.*/CONFIG=\"\/etc\/haproxy\/haproxy.cfg\"/g' /etc/default/haproxy;
sudo bash -c 'echo \"$lbConfig\" >> /etc/haproxy/haproxy.cfg';
sudo service haproxy restart;
")

ssh -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" $username@$lbIP \
"$commands"
