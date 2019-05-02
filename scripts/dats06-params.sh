################# Instance Naming Parameters ###############
# Security group to use
export securityGroup="dats06-security"
export securityGroupLB="dats06-securityLB"

# Names in cloud setup
export DBName="dats06-db"
export numberOfDBs=3
export DBProxyName="dats06-dbproxy"
export webServerName="dats06-web"
export numberOfWebServers=3

# Naming of hosts
export DBHostName="db"
export DBProxyHostName="maxscale"
export webServerHostName="web"
export loadBalancerHostName="lb"



################# VM setup paremeters #################
# Locale parameter
export userLocale="nb_NO.UTF-8"

################# dbSetup Parameters ######################



# This is the name to be used for creation of the keypair used for authentication
export keyPairName="dats06-key"

# This is the loctation for the private-key to be used for accessing the vm
export keyLocation="~/.ssh/$KEYPAIRNAME.pem"

# Usename for logging into vms
export user="ubuntu"

# Proxycommand for ssh into vms
export proxyCommand="ssh dats06@dats.vlab.cs.hioa.no -W %h:%p"
