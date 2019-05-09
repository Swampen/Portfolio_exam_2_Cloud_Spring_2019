#! /bin/bash

echo "Updating VMs"
# Optains the name of all the VMs
vmnames=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}'`)
names=()
ipList=()
hostsfileEntry=""
for vm in ${vmnames[@]}; do
	name=$vm
	echo -n "Getting IP for $name: "
	# Obtaining the IP of the current vm in the loop
	ip=$(openstack server show $name | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
	echo "$ip"
	# Adding the IP address to the list
	ipList+=("$ip")
	name2=""
	# In these if statements, the program generates the "simplified" name to each VM
	if [[ $name = $DBProxyName ]]; then
        	name2=`echo $name | sed s/$DBProxyName/$DBProxyHostName/g`
	elif [[ $name =~ $DBName-[0-9]* ]]; then
        	name2=`echo $name | sed -E s/$DBName-/$DBHostName/g`
	elif [[ $name =~ $webServerName-[0-9]* ]]; then
        	name2=`echo $name | sed -E s/$webServerName-/$webServerHostName/g`
	elif [[ $name = $LBName ]]; then
        	name2=`echo $name | sed s/$LBName/$LBHostName/g`
					lbIP="$ip"
	else
        	echo not found
	fi

	# Adding the entry for the vm to the hostsfile entry
	hostsfileEntry="$ip $name $name2 \\n$hostsfileEntry"
done


# Updates and upgrades the VMs using a parallel ssh
update=("
sudo apt-get update -y;
sudo apt-get upgrade -y;
")
parallel-ssh -t 600 -i -H "${ipList[*]}" \
        -l $username \
	 -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
	"$update"

# The commands that will execute over paralell ssh
# Will do an entry in the hosts file with the required hosts
# Change locale to what's specified in the parameter file
# Set timezone to what's specified in the parameter file
# Set keyboard layout to what's what's specified in the parameter file
script=("
sudo sed -i '1 i\\$hostsfileEntry' /etc/hosts;
sudo sed -i '$ a LANGUAGE=\"$userLocale\"\nLC_ALL=\"$userLocale\"' /etc/default/locale;
sudo unlink /etc/localtime;
sudo ln -s /usr/share/zoneinfo/$timezone /etc/localtime;
sudo locale-gen $userLocale;
sudo sed -i s/XKBLAYOUT=.*/XKBLAYOUT=\"$keyboard\"/g /etc/default/keyboard;
")
# Executing all of the commands over parallel-ssh
parallel-ssh -i -H "${ipList[*]}" \
	-l $username \
	-x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
	"$script"

ssh -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" $username@$lbIP \
"sudo sed -i 's/.*/$LBHostName/g' /etc/hostname"

# Rebooting all the VMs
echo "Rebooting the VMs"
for i in ${!vmnames[@]}; do
	let n=i+1
	echo -n "$n/${#vmnames[@]} - rebooting ${vmnames[$i]} - "
	openstack server reboot --wait ${vmnames[$i]}
done
