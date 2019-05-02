#! /bin/bash

source dats06-params.sh

echo "##### Editing /etc/hosts files #####"
#vmnames=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}'`)

ipSubnet="10\.10"
for vm in ${!vmnames[@]}; do
        name=${vmnames[$vm]}
        echo -n "Getting IP for $name: "
        ip=$(openstack server show $name | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
	echo "$ip"
        ipList="$ipList $ip"
        ipEntry="$ip $name \\n$ipEntry"
done

username="ubuntu"
sshkey="~/.ssh/dats06-key.pem"
MASTER_USER="dats06"
MASTER_HOST="dats.vlab.cs.hioa.no"
sshProxyCommand="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $MASTER_USER@$MASTER_HOST -W %h:%p"

# sed s/dats06-db-/db/g
# sed s/dats06-web-/web/g
# sed s/dats06-dbproxy/maxscale/g

# FOR TESTING #
ipList="10.10.6.147"
ipEntry="10.10.6.147 vmtest"

script=("
sudo sed -i '1 i\\$ipEntry' /etc/hosts;
sudo sed -i '$ a LANGUAGE=\"$USERLOCALE\"\nLC_ALL=\"$USERLOCALE\"' /etc/default/locale;
sudo unlink /etc/localtime;
sudo ln -s /usr/share/zoneinfo/Europe/Oslo /etc/localtime;
sudo locale-gen $USERLOACALE;
sudo sed -i s/XKBLAYOUT=.*/XKBLAYOUT=\"no\"/g /etc/default/keyboard;
")

test=("
echo Hello World;
hostname;
")

parallel-ssh -i -H "$ipList" \
        -l $username \
        -x "-i ~/.ssh/dats06-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
        "$script"

echo "Rebooting the VMs"
for vm in ${!vmnames[@]}; do
	openstack server reboot --wait ${!vmnames[$vm]}
done
