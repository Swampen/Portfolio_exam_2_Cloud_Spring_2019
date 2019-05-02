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
for ((i = 1; i <= $numberOfDBs; i++))
do
	#Getting IP-address of instance
   	hostIP=$(openstack server show $DBName-$i | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
	DBHOSTS="$DBHOSTS $hostIP"
done


# Extracting MaxScale host IP from hostname
SCALEHOST=$(openstack server show $DBPROXYNAME | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

# Generating host configstring for galeraserver
galerahoststring=$( echo wsrep_cluster_address=gcomm://${DBHOSTNAMES[*]} | tr " " ",")



############### SETUP COMMANDS TO BE RUN ON DB SERVERS###############
dbSetupCommands=("
sudo locale-gen nb_NO.UTF-8;
sudo dpkg --configure -a;	
sudo apt-get -y --purge remove "mysql*"
sudo rm -rf /etc/mysql/
sudo apt-get -y install software-properties-common;
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8;
sudo add-apt-repository 'deb [arch=amd64,i386] http://sgp1.mirrors.digitalocean.com/mariadb/repo/10.1/ubuntu xenial main';
sudo apt-get update -q;
sudo apt-get install -y -q mariadb-server;

")
#export DEBIAN_FRONTEND=noninteractive;
#sudo debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password PASS';
#sudo debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password PASS';
############## SETUP COMMANDS TO BE RUN ON MAXSCALE SERVER #################


echo "Starting dbServer setup"
#parallell-ssh --askpass -i -H "$DBHOSTS" -l "$USERNAME" -x "-i $sshkey -o StrictHostKeyChecking=no "  < mkdir TEST
parallel-ssh -i  -H "$DBHOSTS" -l "$user" -x "-i $keyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$proxyCommand'" "$dbSetupCommands" 

echo "Done running parallel ssh commands"

#ssh -i 

# Command for getting ip of instance if we know the name
#nova list --name dbtest-1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'

