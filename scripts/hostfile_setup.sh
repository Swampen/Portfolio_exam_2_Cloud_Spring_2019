#! /bin/bash

source dats06-params.sh

echo "##### Editing /etc/hosts files #####"
#vmnames=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}'`)

ipSubnet="10\.10"
#names=()
#ipList=()
#for vm in ${vmnames[@]}; do
#        name=$vm
#        echo -n "Getting IP for $name: "
#        ip=$(openstack server show $name | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
#	echo "$ip"
#        ipList+=("$ip")
#        ipEntry="$ip $name \\n$ipEntry"
        #names+=("$name")
#done
echo rip
sleep 2
username="ubuntu"
sshkey="~/.ssh/dats06-key.pem"
MASTER_USER="dats06"
MASTER_HOST="dats.vlab.cs.hioa.no"
sshProxyCommand="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $MASTER_USER@$MASTER_HOST -W %h:%p"

# sed s/dats06-db-/db/g
# sed s/dats06-web-/web/g
# sed s/dats06-dbproxy/maxscale/

script=("
sudo sed -i '1 i\\$ipEntry' /etc/hosts;
sudo sed -i '$ a LANGUAGE=\"$USERLOCALE\"\nLC_ALL=\"$USERLOCALE\"' /etc/default/locale;
sudo unlink /etc/localtime;
sudo ln -s /usr/share/zoneinfo/Europe/Oslo /etc/localtime;
sudo locale-gen $userLocale;
sudo sed -i s/XKBLAYOUT=.*/XKBLAYOUT=\"no\"/g /etc/default/keyboard;
")

test=("
echo Hello World;
hostname;
")

parallel-ssh -i -H "${ipList[*]}" \
        -l $username \
        -x "-i ~/.ssh/dats06-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
        "$test"

echo "Changing hostname and rebooting the VMs"

command='sudo bash -c "echo"'
for i in ${!vmnames[@]}; do
	let n=i+1
	echo -n "$n/${#vmnames[@]} - ${vmnames[$i]} - "

	check=`echo "${vmnames[$i]}" | grep -o "$DBName-\?[0-9]*"`
	ip=""
	hostname=""
	if [[ $check = $DBName-[0-9]* ]]; then
		hostname=`echo ${vmnames[$i]} | sed s/dats06-db-/db/g`
		echo $hostname
		ip=${ipList[$i]}
		ssh -i ~/.ssh/dats06-key.pem $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "sudo bash -c 'echo $hostname > /etc/hostname'"
	fi

	check=`echo "${vmnames[$i]}" | grep -o "$DBProxyName"`
	if [[ $check = $DBProxyName ]]; then
		hostname=`echo ${vmnames[$i]} | sed s/dats06-dbproxy/maxscale/g`
		echo $hostname
		ip=${ipList[$i]}
		ssh -i ~/.ssh/dats06-key.pem $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "sudo bash -c 'echo $hostname > /etc/hostname'"
	fi
	openstack server reboot --wait ${vmnames[$i]}
done
# ssh -i ~/.ssh/dats06-key.pem ubuntu@10.10.4.41 -o ProxyCommand="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $MASTER_USER@$MASTER_HOST -W %h:%p"
