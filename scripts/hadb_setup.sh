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

# Generating host configstring for galeraserver
galerahoststring=$( echo wsrep_cluster_address=gcomm://${DBHOSTNAMES[*]} | tr " " ",")



############### SETUP COMMANDS TO BE RUN ON DB SERVERS###############
dbSetupCommands=("
sudo apt-get --purge remove "mysql*"
sudo rm -rf /etc/mysql/
sudo apt-get install software-properties-common;
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,i386] http://sgp1.mirrors.digitalocean.com/mariadb/repo/10.1/ubuntu xenial main'
sudo apt-get update -q;
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password PASS'
sudo debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password PASS'
sudo apt-get install -y -q mariadb-server
sudo bash -c 'echo \"[galera]
binlog_format=row
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-adress=0.0.0.0

#Galera provider information
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
$galerahoststring

# Galera Synchronization Configuration
wsrep_sst_method=rsync\" >> /etc/mysql/my.cnf'


echo "great success"
")

############## SETUP COMMANDS TO BE RUN ON MAXSCALE SERVER #################


echo "Starting dbServer setup"

#parallell-ssh --askpass -i -H "$DBHOSTS" -l "$USERNAME" -x "-i $sshkey -o StrictHostKeyChecking=no "  < mkdir TEST
parallel-ssh -i  -H "$DBHOSTS" -l "$USER" -x "-i $keyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$PROXYCOMMAND'" "$dbSetupCommands" 

echo "Done running parallel ssh commands"

#ssh -i 




# Command for getting ip of instance if we know the name
#nova list --name dbtest-1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'

