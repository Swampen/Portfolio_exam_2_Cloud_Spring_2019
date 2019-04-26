#! /bin/bash
#Assigning "booleans"
WebOK=false
DBPOK=false
DBOK=false
# Creates the security group
openstack security group create dats06-security-1
#sleeps for a little while so that the script will register that the SecGroup has been made
sleep 4
#Adds appropriate rules to the security group
#Permitting ssh internally
openstack security group rule create \
	--protocol tcp \
	--dst-port 22 \
	--remote-group dats06-security-1 dats06-security-1
#Permits ssh from the outside
openstack security group rule create \
       	--protocol tcp \
       	--remote-ip 0.0.0.0/0 \
	--dst-port 22 dats06-security-1
#Permitting HTTP from the outside
openstack security group rule create \
	--protocol tcp \
	--remote-ip 0.0.0.0/0 \
	--dst-port 80 dats06-security-1
#Permits MySQL internally
openstack security group rule create --protocol tcp \
	--dst-port 3306 \
	--remote-group dats06-security-1 dats06-security-1
#Permits syncing in the galera cluster
openstack security group rule create \
	--protocol tcp \
	--dst-port 4444 \
	--remote-group dats06-security-1 dats06-security-1
openstack security group rule create \
	--protocol tcp \
	--dst-port 4567 \
	--remote-group dats06-security-1 dats06-security-1
openstack security group rule create \
	--protocol tcp \
	--dst-port 4568 \
	--remote-group dats06-security-1 dats06-security-1

#Checks if the .ssh directory exists and if it doesn't make it and gives it permissions 755
if [ -d "$HOME/.ssh/" ]
then
	echo "/.ssh exists"
else
	mkdir ~/.ssh
	chmod 755 ~/.ssh
fi

#Creates keypair and puts it in the .ssh folder and gives it permission 400 so that no one except the owner can read it
openstack keypair create dats06-1-key > ~/.ssh/dats06-1-key.pem
chmod 400 ~/.ssh/dats06-1-key.pem
#Sleep to let the system get some time to register that the key has been made
sleep 4

#While loop which checks if the web servers, databases and database proxy are up and running correctly
while [[ $WebOK = false ]] || [[ $DBPOK = false ]] || [[ $DBOK = false ]]
do
	#If the web servers aren't running make them
	if [[ $WebOK = false ]]
	then
		#Create VM going here
		echo "Creating Web Servers ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group dats06-security-1 \
			--key-name dats06-key \
			--nic net-id=BSc_dats_network\
       			--min 1 --max 3 --wait dats06-web1
	fi

	#If the database proxy isn't up and running make it
	if [[ $DBPOK = false ]]
	then
		#Create VM going here
		echo "Creating Database Proxy ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group dats06-security-1 \
			--key-name dats06-key \
			--nic net-id=BSc_dats_network \
			--min 1 --max 1 --wait dats06-dbproxy1
	fi

	#If the databases aren't up and running make them
	if [[ $DBOK = false ]]
	then
		#Create VM going here
		echo "Creating Databases ..."
		openstack server create \
			--image 'Ubuntu16.04' \
			--flavor m1.512MB4GB \
			--security-group dats06-security-1 \
			--key-name dats06-key \
			--nic net-id=BSc_dats_network \
			--min 1 --max 3 --wait dats06-db1
	fi

	#Puts the name of all the servers which failed to start in an array
	failed=`openstack server list --status ERROR -c Name | awk '!/^$|Name/ {print $2;}'`

	#Checks if the array is empty, and if it does set all booleans to true
	if [[ ${#failed} = 0 ]]
	then
		WebOK=true
		DBOK=true
		DBPOK=true
	fi

	#Goes through the list and deletes the VMs that are not running correctly so that they can be relaunched, if not then set the corresponding boolean to true
	for i in $failed
	do
		if [[ $i =~ (dats06-db1-)([1-9]) ]] 
		then
			echo "Deleting Databases ..."
			openstack server delete --wait $i
		else
			DBOK=true
		fi

		if [[ $i =~ (dats06-web1-)([1-9]) ]]
		then
			echo "Deleting Web Servers ..."
			openstack server delete --wait $i
		else
			WebOK=true
		fi

		if [[ $i = "dats06-dbproxy1" ]]
		then
			echo "Deleting Database Proxy ..."
			openstack server delete --wait $i
		else
			DBPOK=true
		fi
	done

done
echo "Setup complete!"
