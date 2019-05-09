#! /bin/bash

# This script configures MariadB in a multi master setup configured via galeracluster.
# The  script takes a single config file as parameter
# DEPENDENCIES
# Parallel-SSH:	sudo apt-get install pssh


# TODO: THE PARAMETER FILE IS TO BE SOURCED BY THE SETUP-SCRIPT REMOVE THIS WHEN TESTING IS COMPLETE!!!!
PARAM_FILE=$@
source $PARAM_FILE

# Generating hostname/IP array
dbServers=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}' | grep $DBName`)
ipList=()
dbNames=()
for vm in ${dbServers[@]}; do
    ip=$(openstack server show $vm | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

    if [[ $vm = $DBProxyName ]]; then
        dbProxy=`echo $vm | sed s/$DBProxyName/$DBProxyHostName/g`
        proxyIP="$ip"
    elif [[ $vm =~ $DBName-[0-9]* ]]; then
        dbNames+=(`echo $vm | sed -E s/$DBName-/$DBHostName/g`)
        ipList+=("$ip")
    fi
done

# Generating host configstring for galeraserver
echo "Generating galera configstring"
galerahoststring=$( echo ${dbNames[*]} | tr " " ",")


############### SETUP COMMANDS TO BE RUN ON DB SERVERS###############

dbSetupCommands=("
sudo locale-gen nb_NO.UTF-8
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8;
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.utexas.edu/mariadb/repo/10.1/ubuntu xenial main';
sudo apt-get update -y;
")

echo "Paralell ssh mariadb setup"
parallel-ssh -t 600 -i -H "${ipList[*]}" -l "$username" -x "-i $sshKeyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "$dbSetupCommands"

echo "sleeping.....ZZZZZZZZZzzzzzzzzzz......."
sleep 3

# Rebooting vm to avoid dpkg issues
echo "Rebooting the VMs"
for i in ${!dbServers[@]}; do
  let n=i+1
	echo -n "$n/${#dbServers[@]} - rebooting ${dbServers[$i]} - "
  openstack server reboot --wait ${dbServers[$i]}
done

echo "sleeping........ZZZZZZZZZZzzzzzzzzz........"
sleep 10

echo "Installing MariaDB on all servers"
parallel-ssh -t 600 -i -H "${ipList[*]}" -l "$username" -x "-i $sshKeyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server rsync"

################ WRITING CONFIG FILES ON DBSERVERS #####################

echo "Generating configstrings for dbServers"

# Config string template for the dbServers
dbConfigTemplate=("
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name=\"galera_cluster\"
wsrep_cluster_address=\"gcomm://$galerahoststring\"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address=\"PLACEHOLDER\"
wsrep_node_name=\"PLACEHOLDER\"
")

echo "Writing settings to all servers"
for i in ${!dbNames[@]}
do
	dbConfigString=`echo "$dbConfigTemplate" | sed "s/PLACEHOLDER/${dbNames[$i]}/g"`

	# Writing settings to /etc/mysql/conf.d/galera.cnf
	galeraConfCommand=("
	sudo echo '$dbConfigString' > ~/tmpfile
	sudo cp /home/ubuntu/tmpfile /etc/mysql/conf.d/galera.cnf
	sudo rm ~/tmpfile
")

	ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@${ipList[$i]}" "$galeraConfCommand"

	if [[ ${dbNames[$i]} = $DBHostName"1" ]]
	then
		firstDB="${ipList[$i]}"
	fi
	done

# Stopping sql service on all servers
parallel-ssh -i -H "${ipList[*]}" -l "$username" -x "-i $sshKeyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "sudo systemctl stop mysql"

# Starting new cluster
echo "Initializing new galera cluster on $firstDB"
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$firstDB" "sudo galera_new_cluster"

# Starting service on remaining servers
echo starting galera service on remaining servers
parallel-ssh -t 600 -i -H "${ipList[*]}" -l "$username" -x "-i $sshKeyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "sudo systemctl start mysql"


# Commands for creating maxsclae user
dbCommand=("
mysql -u root -e \"create user '$username'@'$DBProxyHostName' identified by '$maxscalePass';\";
mysql -u root -e \"grant select on mysql.user to '$username'@'$DBProxyHostName';\";
mysql -u root -e \"grant select on mysql.db to '$username'@'$DBProxyHostName';\";
mysql -u root -e \"grant select on mysql.tables_priv to '$username'@'$DBProxyHostName';\";
mysql -u root -e \"grant show databases on *.* to '$username'@'$DBProxyHostName';\";
")

                                     
# Creating maxscale user and granting permissions
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$firstDB" "$dbCommand"

# Restarting mariaDB service on all servers
#parallel-ssh -i -H "${ipList[*]}" -l "$username" -x "-i $keyLocation -o StrictHostKeyChecking=no -o ProxyCommand='$sshProxyCommand'" "sudo systemctl restart mysql"

################### SETUP COMMANDS TO BE RUN ON MAXSCALE SERVERS #####################

# Installing maxscale on dbProxy Server
ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$DBProxyHostName" "sudo apt-get -y install maxscale"


# Generating maxscale config file
for i in ${!dbNames[@]}
do
	let n=$i+1
	serverBlock=("[server$n]\ntype=server\naddress=${dbNames[$i]}\nport=3306\nprotocol=MySQLBackend\n\n")
	serverArr="$serverArr$serverBlock"
done

maxscaleHostString=$( echo ${dbNames[*]} | tr " " ",")

proxyConfigString=("
# Globals
[maxscale]
threads=4
 
# Servers
$serverArr
 
# Monitoring for the servers
[Galera Monitor]
type=monitor
module=galeramon
servers=$maxscaleHostString
user=$maxscaleUser
passwd=$maxscalePass
monitor_interval=1000
 
# Galera router service
[Galera Service]
type=service
router=readwritesplit
servers=$maxscaleHostString
user=$maxscaleUser
passwd=$maxscalePass
 
# MaxAdmin Service
[MaxAdmin Service]
type=service
router=cli
 
# Galera cluster listener
[Galera Listener]
type=listener
service=Galera Service
protocol=MySQLClient
port=3306
 
# MaxAdmin listener
[MaxAdmin Listener]
type=listener
service=MaxAdmin Service
protocol=maxscaled
socket=default
")

proxyConfCommand=("
sudo echo -e '$proxyConfigString' > ~/tmpfile;
sudo cp /home/ubuntu/tmpfile /etc/maxscale.cnf;
sudo rm ~/tmpfile;
sudo useradd ubuntu maxscale;
sudo systemctl start maxscale.service;
")

ssh -i "$sshKeyLocation" -o ProxyCommand="$sshProxyCommand" "$username@$DBProxyHostName" "$proxyConfCommand"
