#! /bin/bash

# This script configures MariadB in a multi master setup configured via galeracluster. 
# The  script takes a single config file as parameter
# DEPENDENCIES
#	Parallel-SSH:	sudo apt-get install pssh


# TODO: THE PARAMETER FILE IS TO BE SOURCED BY THE SETUP-SCRIPT REMOVE THIS WHEN TESTING IS COMPLETE!!!!
PARAM_FILE=$@
source $PARAM_FILE

# Extracting dbServer host IPs from hostnames
echo "Getting dbServer IPs"
for host in ${!DBHOSTNAMES[@]}
do
	#Getting IP-address of instance
   	hostIP=$(openstack server show ${DBHOSTNAMES[$host]} | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
	DBHOSTS="$DBHOSTS $hostIP"
done

# Extracting MaxScale host IP from hostname
SCALEHOST=$(openstack server show $DBPROXYNAME | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')


############### SETUP COMMANDS TO BE RUN ON DB SERVERS###############
SCRIPT=("
echo Hello Test;
echo Hopes and prayers;
hostname;
")

############## SETUP COMMANDS TO BE RUN ON MAXSCALE SERVER #################


echo "Running parallel ssh commands"

#parallell-ssh --askpass -i -H "$DBHOSTS" -l "$USERNAME" -x "-i $sshkey -o StrictHostKeyChecking=no "  < mkdir TEST
parallel-ssh -i  -H "$DBHOSTS" -l "$USER" -x "-i $keyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$PROXYCOMMAND'" "$SCRIPT" 

echo "Done running parallel ssh commands"

#ssh -i 




# Command for getting ip of instance if we know the name
#nova list --name dbtest-1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'

