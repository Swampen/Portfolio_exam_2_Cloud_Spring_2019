#! /bin/bash

vmnames=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}'`)

ipSubnet="10\.10"
for vm in ${!vmnames[@]}; do
        name=${vmnames[$vm]}
        echo "Getting IP for $name"
        ip=$(openstack server show $name | grep -o "$subnet\.[0-9]*\.[0-9]*")
        ipList="$ipList $ip"
        ipEntry="$ip $name \\n$ipEntry"
done

username="ubuntu"
sshkey="~.ssh/dats06-key.pem"
GW_USER="dats06"
GW_HOST="dats.vlab.cs.hioa.no"
sshProxyCommand="ssh -q $GW_USER@$GW_HOST -W %h:%p"

parallel-ssh --askpass -i -H "$ipList" \
        -l $username \
        -x "-i ~/.ssh/dats06-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand=$sshProxyCommand" \
        -t 1800 "sudo sed -i '1 i\\$ipEntry' /etc/hosts;"
