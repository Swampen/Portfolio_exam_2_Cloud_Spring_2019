#! /bin/bash

source dats06-params.sh

echo "##### Editing /etc/hosts files #####"
vmnames=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}'`)

ipSubnet="10\.10"
names=()
ipList=()
hostfileEntry=""
for vm in ${vmnames[@]}; do
       name=$vm
       echo -n "Getting IP for $name: "
       ip=$(openstack server show $name | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
	echo "$ip"
       ipList+=("$ip")
       hostfileEntry="$ip $name \\n$hostfileEntry"
done
echo rip
sleep 2

# sed s/dats06-db-/db/g
# sed s/dats06-web-/web/g
# sed s/dats06-dbproxy/maxscale/

for i in ${!vmnames[@]}; do
	let n=i+1
	echo -n "$n/${#vmnames[@]} - ${vmnames[$i]} - "
  ip=""
	hostname=""
	#check=`echo "${vmnames[$i]}" | grep -E "$DBName-?[0-9]*|$DBProxyName|$LBName|$webServerName"`
  if [[ ${vmnames[$i]} = $DBProxyName ]]; then
    hostname=`echo ${vmnames[$i]} | sed s/$DBProxyName/$DBProxyHostName/g`
    echo $hostname
    hostfileEntry=`echo $hostfileEntry | sed s/$DBProxyName/$DBProxyHostName/g`
    ip=${ipList[$i]}
    ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "whoami"
	elif [[ ${vmnames[$i]} =~ $DBName-?[0-9]* ]]; then
		hostname=`echo ${vmnames[$i]} | sed -E s/$DBName-?/$DBHostName/g`
		echo $hostname
    hostfileEntry=`echo $hostfileEntry | sed -E s/$DBName-?/$DBHostName/g`
		ip=${ipList[$i]}
		ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "whoami"
    # "sudo bash -c 'echo $hostname > /etc/hostname'"
  elif [[ ${vmnames[$i]} =~ $webServerName-?[0-9]* ]]; then
		hostname=`echo ${vmnames[$i]} | sed -E s/$webServerName-?/$webServerHostName/g`
		echo $hostname
    hostfileEntry=`echo $hostfileEntry | sed -E s/$webServerName-?/$webServerHostName/g`
		ip=${ipList[$i]}
		ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "whoami"
    # "sudo bash -c 'echo $hostname > /etc/hostname'"
  elif [[ ${vmnames[$i]} = $LBName ]]; then
		hostname=`echo ${vmnames[$i]} | sed s/$LBName/$LBHostName/g`
		echo $hostname
    hostfileEntry=`echo $hostfileEntry | sed s/$LBName/$LBHostName/g`
		ip=${ipList[$i]}
		ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "whoami"
    # "sudo bash -c 'echo $hostname > /etc/hostname'"
	else
    echo not found
  fi
done

script=("
sudo sed -i '1 i\\$hostfileEntry' /etc/hosts;
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

# parallel-ssh -i -H "${ipList[*]}" \
#         -l $username \
#         -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$proxyCommand'" \
#         "$test"

# echo "Rebooting the VMs"
# for i in ${!vmnames[@]}; do
#   let n=i+1
# 	echo -n "$n/${#vmnames[@]} - rebooting ${vmnames[$i]} - "
#   openstack server reboot --wait ${vmnames[$i]}
# done

# ssh -i ~/.ssh/dats06-key.pem ubuntu@10.10.4.41 -o ProxyCommand="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $MASTER_USER@$MASTER_HOST -W %h:%p"
