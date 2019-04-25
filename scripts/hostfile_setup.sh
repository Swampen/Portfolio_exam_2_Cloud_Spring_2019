#! /bin/bash

echo "##### Editing /etc/hosts files #####"
vmnames=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}'`)

ipSubnet="10\.10"
for vm in ${!vmnames[@]}; do
        name=${vmnames[$vm]}
        echo "Getting IP for $name"
        ip=$(openstack server show $name | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
	echo "$ip"
        ipList="$ipList $ip"
        ipEntry="$ip $name \\n$ipEntry"
done

username="ubuntu"
sshkey="~/.ssh/dats06-key.pem"
MASTER_USER="dats06"
MASTER_HOST="dats.vlab.cs.hioa.no"
sshProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $MASTER_USER@$MASTER_HOST -W %h:%p"

parallel-ssh -i -H "$ipList" \
        -l $username \
        -x "-i ~/.ssh/dats06-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='$sshProxyCommand'" \
        -t 2000 "sleep 2; echo 'Hello World;'"

# "sudo sed -i '1 i\\$ipEntry' /etc/hosts; \
#	sudo sed -i 's/LANG=.*/LANGUAGE=\"nb_NO.UTF-8\"\nLC_ALL=\"nb_NO.UTF-8\"/g' /etc/default/locale; \
#	sudo unlink /etc/localtime; \
#	sudo ln -s /usr/share/zoneinfo/Europe/etc/localtime /etc/localtime; \
#	sudo locale-gen nb_NO.UTF-8; \
#	sudo reboot;"

echo "Waiting for VMs to reboot"
sleep 1
echo -n "."
sleep 1
echo -n "."
sleep 1
echo -n "."
sleep 1
echo -n "."
sleep 1
echo -n "."
sleep 1
echo -n "."
sleep 1
echo -n "."
echo ""

