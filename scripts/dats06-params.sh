################# Instance Naming Parameters ###############
DBHOSTNAMES=("db1" "db2" "db3")
DBPROXYNAME="MaxScale"
WEBSERVERNAMES=("web1" "web2" "web3")
LOADBALANCERNAME="lb"



################# dbSetup Parameters ######################


# This is the name to be used for creation of the keypair used for authentication
keypairName="dats06-key"

# This is the loctation for the private-key to be used for accessing the vm. 
keyLocation="~/.ssh/$keypairName.pem"

#Usename for logging into vms
USER="ubuntu"

#Proxycommand for ssh into vms
PROXYCOMMAND="ssh dats06@dats.vlab.cs.hioa.no -W %h:%p"
