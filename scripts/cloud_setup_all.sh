#! /bin/bash

echo "IMPORTANT: This script needs to be executed from its own folder"
echo "IMPORTANT parallel ssh must be installed for this script to run correctly. Install with sudo apt-get -y install pssh"

if [[ ! $# = 1 ]]; then
	echo "ERROR: the file dats06-params.sh should be given as the only parameter to this script"
	exit 0
fi

# Getting correct path to script directory
dir=$(dirname "$0")

# Sourcing openstack 
source "$dir"/dats06_project-openrc.sh

# Sourcing parameter file given as argument
source $1;

# Checking for ssh key presence
if [ ! -f "$sshKeyLocation" ]; then
  echo "ERROR: The the key dats06-key.pem MUST be placed in the folder: ~/.ssh/"
  exit 0
fi

# Running script for building instances
echo "DEPLOYING VMs"
"$dir"/vm_setup.sh

# Sleeping to avoid problem with Alto reporting instance readiness to early
echo "Resting to let the VMs recover after reboot, please allow 15 seconds for a light snooze..........zzzzzzzzzzzzzZZZZZZZZZZZzzzzzzzZZZZzzzzzzz........"
sleep 15

# Running script for configuring webserver loadbalancer
echo "DEPLOYING LOADBALANCER"
"$dir"/lb_setup.sh

# Running script for configuring webservers
echo "DEPLOYING WEBSERVERS"
"$dir"/web_setup.sh

# Running script for configuring database proxy and db servers
echo "DEPLOYING DATABASES"
"$dir"/hadb_setup.sh

echo "SETUP COMPLETE"