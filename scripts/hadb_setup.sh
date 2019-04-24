#! /bin/bash

# This script configures MariadB in a multi master setup configured via galeracluster. 
# The  script takes a single config file as parameter
# DEPENDENCIES
#	Parallel-SSH:	sudo apt-get install pssh

PARAM_FILE=$@
source PARAM_FILE

# Extracting dbServer host IPs from hostnames
for host in $DBHOSTNAMES
do
	#Getting IP-address of instance
   	hostIP=$(openstack server list --name $host | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
	DBHOSTS="$HOSTS $hostIP"
done

# Extracting MaxScale host IP from hostname
SCALEHOST=$(openstack server list --name $MAXSCALEHOSTNAME | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')


SCRIPT=("mkdir Test; whoami;")


echo "Running parallel ssh commands"

parallell-ssh --askpass -i -H "$HOSTS" -l "$USERNAME" -x "-i $sshkey -o StrictHostKeyChecking=no "  < mkdir TEST

echo "Done running parallel ssh commands"
#USERNAME="s325853"
#HOST="studssh.cs.hioa.no"




# Command for getting ip of instance if we know the name
#nova list --name dbtest-1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'

