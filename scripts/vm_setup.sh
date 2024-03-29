#! /bin/bash

# Assigning "booleans"
WebOK=false
DBPOK=false
DBOK=false
SecGrExist=false

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

# Creates the security group if it doesn't exist
if [[ $SecGrExist = false ]]
then
	openstack security group create $securityGroup -f json
fi

# sleeps for a little while so that the script will register that the SecGroup has been made
# Otherwise the script will throw an error because it can't find a security group with that name
sleep 4

# Adds appropriate rules to the security group
# Permitting ssh internally
openstack security group rule create \
	--protocol tcp \
	--dst-port 22 \
	--description "Allows ssh inside the cloud" \
	--remote-group $securityGroup $securityGroup -f json

# Permits ssh from the outside
openstack security group rule create \
       	--protocol tcp \
       	--remote-ip 0.0.0.0/0 \
	--description "Allows ssh from outside systems into the cloud" \
	--dst-port 22 $securityGroup -f json

# Permitting HTTP from the outside
openstack security group rule create \
	--protocol tcp \
	--remote-ip 0.0.0.0/0 \
	--description "Allows HTTP access from the outside" \
	--dst-port 80 $securityGroup -f json

# Permits MySQL client connection
openstack security group rule create --protocol tcp \
	--dst-port 3306 \
	--description "Allows a MySQL client connection" \
	--remote-group $securityGroup $securityGroup -f json

# Permits State Snapshot Transfer (SST)
openstack security group rule create \
	--protocol tcp \
	--description "Allows State Snapshot Transfer" \
	--dst-port 4444 \
	--remote-group $securityGroup $securityGroup -f json

# Permits Galera cluster replication traffic
openstack security group rule create \
	--protocol tcp \
	--description "Allows Galera cluster replication traffic" \
	--dst-port 4567 \
	--remote-group $securityGroup $securityGroup -f json

# Permits Incremental State Transfer (IST)
openstack security group rule create \
	--protocol tcp \
	--description "Allows Incremental State Transfer" \
	--dst-port 4568 \
	--remote-group $securityGroup $securityGroup -f json


exists=`openstack server list --status ACTIVE -c Name | awk '!/^$|Name/ {print $2;}'`

for vm in $exists; do
  if [[ $vm =~ ($webServerName-)([1-9]) ]]
  then
    echo "$vm already exists"
    WebOK=true
  fi

  # If i corresponds with the database proxy name
  # delete said server, if i does not match then set corresponding boolean to true
  if [[ $vm = "$DBProxyName" ]]
  then
    echo "$vm already exists"
    DBPOK=true
  fi

  # If i corresponds with the database name with a - and a number at the end
  # delete said server, if i does not match then set corresponding boolean to true
  if [[ $vm =~ ($DBName-)([1-9]) ]]
  then
    echo "$vm already exists"
    DBOK=true
  fi
done

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
       			--min 1 --max $numberOfWebServers --wait $webServerName -f json
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
			--min 1 --max 1 --wait $DBProxyName -f json
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
			--min 1 --max $numberOfDBs --wait $DBName -f json
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

	# Goes through the list and deletes the VMs that are not running correctly
	# so that they can be relaunched, if not then set the corresponding boolean to true
	# Warning: This only works because when you launch say 3 Databases at once, if one
	# gets an error all 3 gets an error
	for i in $failed
	do

		# If it corresponds with the web server name with a - and a number at the end
		# delete said server, if i does not match then set corresponding boolean to true
		if [[ $i =~ ($webServerName-)([1-9]) ]]
		then
			echo "Deleting Web Servers ..."
			openstack server delete --wait $i
		else
			WebOK=true
		fi

		# If it corresponds with the database proxy name
		# delete said server, if i does not match then set corresponding boolean to true
		if [[ $i = "$DBProxyName" ]]
		then
			echo "Deleting Database Proxy ..."
			openstack server delete --wait $i
		else
			DBPOK=true
		fi

		# If it corresponds with the database name with a - and a number at the end
		# delete said server, if i does not match then set corresponding boolean to true
		if [[ $i =~ ($DBName-)([1-9]) ]]
		then
			echo "Deleting Databases ..."
			openstack server delete --wait $i
		else
			DBOK=true
		fi
	done

done
echo "Setup complete!"

echo "Getting all the VM IPs"
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

echo "Updating and upgrading the VMs (this may take some time, go grab a coffee in the meantime)"
# Updates and upgrades the VMs using a parallel ssh
update=("
sudo apt-get update -y;
sudo apt-get upgrade -y;
")
parallel-ssh -t 600 -i -H "${ipList[*]}" \
        -l $username \
	 -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
	"$update"

# This is to change the hostname of the load balancer.
# This is because the load balancer was created, it had a different hostname,
# so when the VM is rebuilt to the default Ubunti16.04 image, it defaults to the old hostname
ssh -i "$sshKeyLocation" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand="$sshProxyCommand" $username@$lbIP "sudo sed -i s/.*/$LBHostName/g /etc/hostname"

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

# Rebooting all the VMs
echo "Rebooting the VMs"
for i in ${!vmnames[@]}; do
	let n=i+1
	echo -n "$n/${#vmnames[@]} - rebooting ${vmnames[$i]} - "
	openstack server reboot --wait ${vmnames[$i]}
done
