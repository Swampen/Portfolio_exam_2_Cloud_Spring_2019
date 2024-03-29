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
export keyPairName="key"
# This is the loctation for the private-key to be used for accessing the vm
export sshKeyLocation=~/.ssh/$keyPairName.pem
# Usename for logging into vms
export username="ubuntu"
# Name of master host
export masterHost="master.host"
# Name of user on master host
export masterUser="uname"
# Proxycommand for ssh into vms
export sshProxyCommand="ssh -i \"$sshKeyLocation\" -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $masterUser@$masterHost -W %h:%p"
# Locale parameter
export userLocale="nb_NO.UTF-8"
# Timezone parameter
export timezone="Europe/Oslo"
# Keyboard layout parameter
export keyboard="no"

################# Load Balancer Parameters #################
export LBSTATUSER="uname"
export LBSTATPASSWD="pwd"

################# Web Setup Parameters ######################
export GITPHPDEPLOYMENT="https://github.com/JakobSimonsen/Portfolio_exam_deployment.git"
export CUSTOMAVAILABLESITES="index.php test.php students-grades.php"

################# Databace Setup Parameters ######################
export maxscalePass="pwd"
export maxscaleUser="mxuname"
export webServerUser="uname"
export webServerPass="pwd"
export dbSetupScript="database-init-script.txt"
