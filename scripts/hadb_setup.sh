#! /bin/bash

# This script configures MariadB in a multi master setup configured via galeracluster.
# The  script takes a single config file as parameter
# DEPENDENCIES
# Parallel-SSH:	sudo apt-get install pssh


# TODO: THE PARAMETER FILE IS TO BE SOURCED BY THE SETUP-SCRIPT REMOVE THIS WHEN TESTING IS COMPLETE!!!!
PARAM_FILE=$@
source $PARAM_FILE

# Generating array of dbServer Hostnames
echo "Generating hostname array"
for ((i = 1; i <= $numberOfDBs; i++))
do
	hostName="$DBHostName$i"
	DBHOSTS="$DBHOSTS$hostName "
done

# Generating host configstring for galeraserver
echo "Generating galera configstring"
galerahoststring=$( echo wsrep_cluster_address=gcomm://${DBHOSTS[*]} | tr " " ",")


############### SETUP COMMANDS TO BE RUN ON DB SERVERS###############

dbSetupCommands=("
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8;
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.utexas.edu/mariadb/repo/10.1/ubuntu xenial main';
sudo apt-get update -y;
sudo DEBIAN_FRONTEND=noninteractive apt-get install mariadb-server rsync -y;
")
echo "Paralell ssh mariadb setup"
parallel-ssh -i -H "$DBHOSTS" -l "$username" -x "-i $sshKeyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "$dbSetupCommands"

################ WRITING CONFIG FILES ON DBSERVERS #####################

echo "Generating configstrings for dbServers"
for ((i = 1; i <= $numberOfDBs; i++))
do

# Generating config string for each dbServer
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

# Writing settings to /etc/mysql/conf.d/galera.cnf
galeraConfCommand=("
sudo echo '$dbConfigString' > ~/tmpfile
sudo cp /home/ubuntu/tmpfile /etc/mysql/conf.d/galera.cnf
sudo rm ~/tmpfile
")

echo "Writing settings to all servers"
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$DBHostName$i" "$galeraConfCommand"
if [[ $i = 1 ]]
then
	firstDB="$DBHostName$i"
fi
done

# Stopping sql service on all servers
parallel-ssh -i -H "$DBHOSTS" -l "$username" -x "-i $sshKeyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "sudo systemctl stop mysql"

# Starting new cluster
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$firstDB" "sudo galera_new_cluster"

# Commands for creating maxsclae user
dbCommand=("
mysql -u root -e "create user '$username'@'$DBProxyHostName' identified by 'mypwd';";
mysql -u root -e "grant select on mysql.user to '$username'@'$DBProxyHostName';";
mysql -u root -e "grant select on mysql.db to '$username'@'$DBProxyHostName';";
mysql -u root -e "grant select on mysql.tables_priv to '$username'@'$DBProxyHostName';";
mysql -u root -e "grant show databases on *.* to '$username'@'$DBProxyHostName';";
")

# Creating maxscale user and granting permissions
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$firstDB" "$dbCommand"

# Restarting mariaDB service on all servers
parallel-ssh -i -H "$DBHOSTS" -l "$username" -x "-i $keyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "sudo systemctl restart mysql"

################### SETUP COMMANDS TO BE RUN ON MAXSCALE SERVERS #####################

# Installing maxscale on dbProxy Server
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$DBProxyHostName" "sudo apt-get -y install maxscale"

for ((i = 1; i <= $numberOfDBs; i++))
do
	serverBlock=("[server$i]\ntype=server\naddress=$DBHostName$i\nport=3306\nprotocol=MySQLBackend\n\n")
	serverArr="$serverArr$serverBlock"
done

maxscaleHostString=$(echo ${DBHOSTS[*]} | tr " " ",")


proxyConfigString=("
# Globals\n
[maxscale]\n
threads=4\n
 \n
# Servers\n
$serverArr
 \n
# Monitoring for the servers\n
[Galera Monitor]\n
type=monitor\n
module=galeramon\n
servers=$maxscaleHostString\n
user=myuser\n
passwd=mypwd\n
monitor_interval=1000\n
 \n
# Galera router service\n
[Galera Service]\n
type=service\n
router=readwritesplit\n
servers=$maxscaleHostString\n
user=myuser\n
passwd=mypwd\n
 \n
# MaxAdmin Service\n
[MaxAdmin Service]\n
type=service\n
router=cli\n
 \n
# Galera cluster listener\n
[Galera Listener]\n
type=listener\n
service=Galera Service\n
protocol=MySQLClient\n
port=3306\n
 \n
# MaxAdmin listener\n
[MaxAdmin Listener]\n
type=listener\n
service=MaxAdmin Service\n
protocol=maxscaled\n
socket=default\n
")

proxyConfCommand=("
sudo echo -e '$proxyConfigString' > ~/tmpfile
sudo cp /home/ubuntu/tmpfile /etc/maxscale.cnf
sudo rm ~/tmpfile
")

ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$DBProxyHostName" "$proxyConfCommand"
