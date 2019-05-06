#! /bin/bash
# Assigning "booleans"
WebOK=false
DBPOK=false
DBOK=false
SecGrExist=false
SecGrLBExist=false

# Creates an array of all existing security groups
Securitygroups=`openstack security group list --c Name | awk '!/^$|Name/ {print $2;}'`

# Checks if a security group of the same name as the parameter exists andd if so changes
# the boolean to true causing no new security group to be made
for x in $Securitygroups
do
	if [[ $x = $securityGroup ]]
	then
		SecGrExist=true
	fi
done

for x in $Securitygroups
do
	if [[ $x = $securityGroupLB ]]
	then
		SecGrExistLB=true
	fi
done
# Creates the security group if it doesn't exist
if [[ $SecGrExist = false ]]
then
	openstack security group create $securityGroup
fi

if [[ $SecGrLBExist = false ]]
then
	openstack security group create $securityGroupLB
fi
# sleeps for a little while so that the script will register that the SecGroup has been made
sleep 4
# Adds appropriate rules to the security group
# Permitting ssh internally
openstack security group rule create \
	--protocol tcp \
	--dst-port 22 \
	--description "Allows ssh inside the cloud" \
	--remote-group $securityGroup $securityGroup
	
# Permits ssh from the outside
openstack security group rule create \
       	--protocol tcp \
       	--remote-ip 0.0.0.0/0 \
	--description "Allows ssh from outside systems into the cloud" \
	--dst-port 22 $securityGroup

# Permitting HTTP from the outside
openstack security group rule create \
	--protocol tcp \
	--remote-ip 0.0.0.0/0 \
	--description "Allows HTTP access from the outside" \
	--dst-port 80 $securityGroup

openstack security group rule create \
	--protocol tcp \
	--remote-ip 0.0.0.0/0 \
	--description "Allows HTTP access from the outside" \
	--dst-port 80 $securityGroupLB
# Permits MySQL client connection
openstack security group rule create --protocol tcp \
	--dst-port 3306 \
	--description "Allows a MySQL client connection" \
	--remote-group $securityGroup $securityGroup
# Permits State Snapshot Transfer (SST)
openstack security group rule create \
	--protocol tcp \
	--description "Allows State Snapshot Transfer" \
	--dst-port 4444 \
	--remote-group $securityGroup $securityGroup
# Permits Galera cluster replication traffic
openstack security group rule create \
	--protocol tcp \
	--description "Allows Galera cluster replication traffic" \
	--dst-port 4567 \
	--remote-group $securityGroup $securityGroup
# Permits Incremental State Transfer (IST)
openstack security group rule create \
	--protocol tcp \
	--description "Allows Incremental State Transfer" \
	--dst-port 4568 \
	--remote-group $securityGroup $securityGroup

# Permits Munin to run for monitoring purposes
openstack security group rule create \
	--protocol tcp
	--description "Allows Munin" \
	--dst-port 4949
	--remote-ip  0.0.0.0/0 $securityGroup

openstack security group rule create \
	--protocol tcp \
	--description "Allows Munin" \
	--dst-port 4949 \
	--remote-group $securityGroup $securityGroup

# Checks if the .ssh directory exists and if it doesn't make it and gives it permissions 755
if [ -d "$HOME/.ssh/" ]
then
	echo "Folder exists"	
else
	mkdir ~/.ssh
	chmod 755 ~/.ssh
fi

# Creates keypair and puts it in the .ssh folder and gives it permission 400 so that no one except the owner can read it
#openstack keypair create $KEYPAIRNAME > $KEYLOCATION
#chmod 400 $KEYLOCATION
# Sleep to let the system get some time to register that the key has been made
sleep 4

# While loop which checks if the web servers, databases and database proxy are up and running correctly
while [[ $WebOK = false ]] || [[ $DBPOK = false ]] || [[ $DBOK = false ]]
do
	# If the web servers aren't running make them
	if [[ $WebOK = false ]]
	then
		echo "Creating Web Servers ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group $securityGroup \
			--key-name $keyPairName \
			--nic net-id=BSc_dats_network\
       			--min 1 --max $numberOfWebServers --wait $webServerName
	fi

	# If the database proxy isn't up and running make it
	if [[ $DBPOK = false ]]
	then
		echo "Creating Database Proxy ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group $securityGroup \
			--key-name $keyPairName \
			--nic net-id=BSc_dats_network \
			--min 1 --max 1 --wait $DBProxyName
	fi

	# If the databases aren't up and running make them
	if [[ $DBOK = false ]]
	then
		echo "Creating Databases ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group $securityGroup \
			--key-name $keyPairName \
			--nic net-id=BSc_dats_network \
			--min 1 --max $numberOfDBs --wait $DBName
	fi

	# Puts the name of all the servers which failed to start in an array
	failed=`openstack server list --status ERROR -c Name | awk '!/^$|Name/ {print $2;}'`

	# Checks if the array is empty, and if it does set all booleans to true
	if [[ ${#failed} = 0 ]]
	then
		WebOK=true
		DBOK=true
		DBPOK=true
	fi

	# Goes through the list and deletes the VMs that are not running correctly so that they can be relaunched, if not then set the corresponding boolean to true
	for i in $failed
	do
		if [[ $i =~ ($DBName-)([1-9]) ]]
		then
			echo "Deleting Databases ..."
			openstack server delete --wait $i
		else
			DBOK=true
		fi

		if [[ $i =~ ($webServerName-)([1-9]) ]]
		then
			echo "Deleting Web Servers ..."
			openstack server delete --wait $i
		else
			WebOK=true
		fi

		if [[ $i = "$DBProxyName" ]]
		then
			echo "Deleting Database Proxy ..."
			openstack server delete --wait $i
		else
			DBPOK=true
		fi
	done

done
echo "Setup complete!"
echo "Updating VMs"

#Updates and upgrades the VMs using a parallel ssh
update=("
sudo apt-get update -y;
sudo apt-get upgrade -y;
")
parallel-ssh -i -H "${ipList[*]}" \
        -l $username \
	 -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
	"$update"

o "##### Editing /etc/hosts files #####"
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
		echo $
		hostfileEntry=`echo $hostfileEntry | sed s/$DBProxyName/$DBProxyHostName/g`
		ip=${ipList[$i]}
		ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "sudo bash -c 'echo $hostname > /etc/hostname'"
	elif [[ ${vmnames[$i]} =~ $DBName-[0-9]* ]]; then
		hostname=`echo ${vmnames[$i]} | sed -E s/$DBName-/$DBHostName/g`
		echo $hostname
		hostfileEntry=`echo $hostfileEntry | sed -E s/$DBName-/$DBHostName/g`
		ip=${ipList[$i]}
		ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "sudo bash -c 'echo $hostname > /etc/hostname'"
	elif [[ ${vmnames[$i]} =~ $webServerName-[0-9]* ]]; then
	 	hostname=`echo ${vmnames[$i]} | sed -E s/$webServerName-/$webServerHostName/g`
		echo $hostname
		hostfileEntry=`echo $hostfileEntry | sed -E s/$webServerName-/$webServerHostName/g`
		ip=${ipList[$i]}
		ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "sudo bash -c 'echo $hostname > /etc/hostname'"
	elif [[ ${vmnames[$i]} = $LBName ]]; then
		hostname=`echo ${vmnames[$i]} | sed s/$LBName/$LBHostName/g`
		echo $hostname
		hostfileEntry=`echo $hostfileEntry | sed s/$LBName/$LBHostName/g`
		ip=${ipList[$i]}
		ssh -i $sshKeyLocation $username@$ip -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" "sudo bash -c 'echo $hostname > /etc/hostname'"
	else
	        echo not found
	fi
done

script=("
sudo sed -i '1 i\\$hostfileEntry' /etc/hosts;
sudo sed -i '$ a LANGUAGE=\"$userLocale\"\nLC_ALL=\"$userLocale\"' /etc/default/locale;
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
	-x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
	"$script"

echo "Rebooting the VMs"

for i in ${!vmnames[@]}; do

	let n=i+1
	echo -n "$n/${#vmnames[@]} - rebooting ${vmnames[$i]} - "
	openstack server reboot --wait ${vmnames[$i]}
done
