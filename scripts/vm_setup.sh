#! /bin/bash
# Creates the security group
openstack security group create dats06-security-1
sleep 4
#Adds appropriate rules to the security group
#Permitting ssh from the outside
openstack security group rule create \
	--protocol tcp \
	--dst-port 22 \
	--remote-group dats06-security-1 dats06-security-1
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
#Creates key-pair
if [ -d "$HOME/.ssh/" ]
then
	echo "/.ssh exists"
else
	mkdir ~/.ssh
	chmod 755 ~/.ssh
fi

openstack keypair create dats06-1-key > ~/.ssh/dats06-1-key.pem
chmod 400 ~/.ssh/dats06-1-key.pem
sleep 4

while [[ $WebOK = false ]] || [[ $DBPOK = false ]] || [[ $DBOK = false ]]
do
	if [[ $WebOK = false ]]
	then
		#Create VM going here
	fi

	if [[ $DBPOK = false ]]
	then
		#Create VM going here
	fi

	if [[ $DBOK = false ]]
	then
		#Create VM going here
	fi

	sleep 5

	failed=`openstack server list --status ERROR -c Name | awk '!/^$|Name/ {print $2;}'`
	for i in $failed
	do
		if [[ $i = "dats06-db*" ]] 
		then
			openstack delete $i
		else
			$DBOK = true
		fi

		if [[ $i = "dats06-web*" ]]
		then
			openstack delete $i
		else
			$WebOK = true
		fi

		if [[ $i = "dats06-dbproxy" ]]
		then
			openstack delete $i
		else
			$DBPOK = true
		fi



done


#Creates 3 VMs to be used as web servers using Ubuntu16.04 and the m1.512MB4GB flavor
openstack server create \
	--image 'Ubuntu16.04' \
	--flavor m1.512MB4GB \
	--security-group dats06-security-1 \
	--key-name dats06-key \
	--nic net-id=BSc_dats_network\
       	--min 1 --max 3 --wait dats06-web
#Creates 1 VM to be used as a database proxy
openstack server create \
	--image 'Ubuntu16.04' \
	--flavor m1.512MB4GB \
	--security-group dats06-security-1 \
	--key-name dats06-key \
	--nic net-id=BSc_dats_network \
	--min 1 --max 1 --wait dats06-dbproxy
#Creates 3 VMs to be used as databases
openstack server create \
	--image 'Ubuntu16.04' \
	--flavor m1.512MB4GB \
	--security-group dats06-security-1 \
	--key-name dats06-key \
	--nic net-id=BSc_dats_network \
	--min 1 --max 3 --wait dats06-db
