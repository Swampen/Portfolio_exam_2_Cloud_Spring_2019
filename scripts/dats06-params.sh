################# Instance Naming Parameters ###############
# Security group to use
SECURITYGROUP="dats06-security"

# Names in cloud setup
DBNAME="dats06-db"
NUMBEROFDBS=3
DBPROXYNAME="dats06-dbproxy"
WEBSERVERNAME="dats06-web"
NUMBEROFWEBSERVERS=3

# Naming of hosts
DBHOSTNAME="db"
DBPROXYNAME="maxscale"
WEBSERVERHOSTNAME="web"
LOADBALANCERHOSTNAME="lb"



################# VM setup paremeters #################
# Locale parameter
USERLOCALE="nb_NO.UTF-8"

################# dbSetup Parameters ######################



# This is the name to be used for creation of the keypair used for authentication
KEYPAIRNAME="dats06-key"

# This is the loctation for the private-key to be used for accessing the vm
KEYLOCATION="~/.ssh/$KEYPAIRNAME.pem"

# Usename for logging into vms
USER="ubuntu"

# Proxycommand for ssh into vms
PROXYCOMMAND="ssh dats06@dats.vlab.cs.hioa.no -W %h:%p"
