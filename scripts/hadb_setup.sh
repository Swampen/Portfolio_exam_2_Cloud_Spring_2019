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
   	#hostIP=$(openstack server show $DBName-$i | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
	hostName="$DBHostName$i"
	DBHOSTS="$DBHOSTS$hostName "
done

# Extracting MaxScale host IP from hostname
#SCALEHOST=$(openstack server show $DBProxyName | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

# Generating host configstring for galeraserver
galerahoststring=$( echo wsrep_cluster_address=gcomm://${DBHOSTS[*]} | tr " " ",")


############### SETUP COMMANDS TO BE RUN ON DB SERVERS###############

dbSetupCommands=("
sudo locale-gen "nb_NO.UTF-8";
sudo apt-get update -y;
sudo apt-get upgrade -y;
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8;
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.utexas.edu/mariadb/repo/10.1/ubuntu xenial main';
sudo apt-get update -y;
sudo DEBIAN_FRONTEND=noninteractive apt-get install mariadb-server rsync -y;
")

for ((i = 1; i <= $numberOfDBs; i++))
do
dbConfigString=("
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
nwsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
nwsrep_cluster_name="galera_cluster"
wsrep_cluster_address="$galerahoststring"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="$DBHostName$i"
wsrep_node_name="$DBHostName$i"
")

command=("
sudo echo '$dbConfigString' > ~/tmpfile
sudo cp /home/ubuntu/tmpfile /etc/mysql/conf.d/galera.cnf
")
echo $dbConfigString
#parallel-ssh -i -H "$DBHostName$i" -l "$username" -x "-i $sshKeyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "$command"
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$DBHostName$i" "$command"
exit 0
done

#export DEBIAN_FRONTEND=noninteractive;
#sudo debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password PASS';
#sudo debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password PASS';


echo "Starting dbServer setup"
#parallell-ssh --askpass -i -H "$DBHOSTS" -l "$username" -x "-i $sshkey -o StrictHostKeyChecking=no "  < mkdir TEST
parallel-ssh -i -H "$DBHOSTS" -l "$username" -x "-i $keyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "dbSetupCommands"

echo "Done running parallel ssh commands"

#ssh -i

# Command for getting ip of instance if we know the name
#nova list --name dbtest-1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'

################### SETUP COMMANDS TO BE RUN ON MAXSCALE SERVERS #####################


