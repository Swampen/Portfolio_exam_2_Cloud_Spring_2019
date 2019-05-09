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
export LBName="dats06-lb"

# Naming of hosts
export DBHostName="db"
export DBProxyHostName="maxscale"
export webServerHostName="web"
export LBHostName="lb"

################# Network parameters #################
# Subnet parameters
export ipSubnet="10\.10"

################# VM setup paremeters #################
# ssh parameters
# This is the name to be used for creation of the keypair used for authentication
export keyPairName="dats06-key"
# This is the loctation for the private-key to be used for accessing the vm
export sshKeyLocation=~/.ssh/$keyPairName.pem
# Usename for logging into vms
export username="ubuntu"
# Name of master host
export masterHost="dats.vlab.cs.hioa.no"
# Name of user on master host
export masterUser="dats06"
# Proxycommand for ssh into vms
export sshProxyCommand="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $masterUser@$masterHost -W %h:%p"
# Locale parameter
export userLocale="nb_NO.UTF-8"
# Timezone parameter
export timezone="Europe/Oslo"
# Keyboard layout parameter
export keyboard="no"

################# Load Balancer Parameters #################
export LBSTATUSER="dats06"
export LBSTATPASSWD="thrown similar river"

################# dbSetup Parameters ######################
export maxscalePass="thrown similar river"
export maxscaleUser="maxScaleUsr"
export webServerUser="dats06"
export webServerPass="thrown similar river"
