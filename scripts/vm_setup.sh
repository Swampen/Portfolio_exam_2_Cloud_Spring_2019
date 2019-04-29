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
	if [[ $x = $SECURITYGROUP ]]
	then
		SecGrExist=true
	fi
done
# Creates the security group if it doesn't exist
if [[ $SecGrExist = false ]]
then
	openstack security group create $SECURITYGROUP
fi
# sleeps for a little while so that the script will register that the SecGroup has been made
sleep 4
# Adds appropriate rules to the security group
# Permitting ssh internally
openstack security group rule create \
	--protocol tcp \
	--dst-port 22 \
	--description "Allows ssh inside the cloud" \
	--remote-group $SECURITYGROUP $SECURITYGROUP
# Permits ssh from the outside
openstack security group rule create \
       	--protocol tcp \
       	--remote-ip 0.0.0.0/0 \
	--description "Allows ssh from outside systems into the cloud" \
	--dst-port 22 $SECURITYGROUP
# Permitting HTTP from the outside
openstack security group rule create \
	--protocol tcp \
	--remote-ip 0.0.0.0/0 \
	--description "Allows HTTP access from the outside" \
	--dst-port 80 $SECURITYGROUP
# Permits MySQL client connection
openstack security group rule create --protocol tcp \
	--dst-port 3306 \
	--description "Allows a MySQL client connection" \
	--remote-group $SECURITYGROUP $SECURITYGROUP
# Permits State Snapshot Transfer (SST)
openstack security group rule create \
	--protocol tcp \
	--description "Allows State Snapshot Transfer" \
	--dst-port 4444 \
	--remote-group $SECURITYGROUP $SECURITYGROUP
# Permits Galera cluster replication traffic
openstack security group rule create \
	--protocol tcp \
	--description "Allows Galera cluster replication traffic" \
	--dst-port 4567 \
	--remote-group $SECURITYGROUP $SECURITYGROUP
# Permits Incremental State Transfer (IST)
openstack security group rule create \
	--protocol tcp \
	--description "Allows Incremental State Transfer" \
	--dst-port 4568 \
	--remote-group $SECURITYGROUP $SECURITYGROUP

# Checks if the .ssh directory exists and if it doesn't make it and gives it permissions 755
if [ -d "$HOME/.ssh/" ]
then
	
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
			--security-group $SECURITYGROUP \
			--key-name $KEYPAIRNAME \
			--nic net-id=BSc_dats_network\
       			--min 1 --max $NUMBEROFWEBSERVERS --wait $WEBSERVERNAME
	fi

	# If the database proxy isn't up and running make it
	if [[ $DBPOK = false ]]
	then
		echo "Creating Database Proxy ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group $SECURITYGROUP \
			--key-name $KEYPAIRNAME \
			--nic net-id=BSc_dats_network \
			--min 1 --max 1 --wait $DBPROXYNAME
	fi

	# If the databases aren't up and running make them
	if [[ $DBOK = false ]]
	then
		echo "Creating Databases ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group $SECURITYGROUP \
			--key-name $KEYPAIRNAME \
			--nic net-id=BSc_dats_network \
			--min 1 --max $NUMBEROFDBS --wait $DBNAME
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
		if [[ $i =~ ($DBNAME-)([1-9]) ]] 
		then
			echo "Deleting Databases ..."
			openstack server delete --wait $i
		else
			DBOK=true
		fi

		if [[ $i =~ ($WEBSERVERNAME-)([1-9]) ]]
		then
			echo "Deleting Web Servers ..."
			openstack server delete --wait $i
		else
			WebOK=true
		fi

		if [[ $i = "$DBPROXYNAME" ]]
		then
			echo "Deleting Database Proxy ..."
			openstack server delete --wait $i
		else
			DBPOK=true
		fi
	done

done
echo "Setup complete!"
