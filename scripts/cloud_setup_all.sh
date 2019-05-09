#! /bin/bash

# Sourcing parameter file given as argument
source $1;

# Running script for building instances
echo "DEPLOYING VMs"
#./vm_setup.sh
./test.sh

# Running script for configuring webserver loadbalancer
echo "DEPLOYING LOADBALANCER"
./lb_setup.sh

# Running script for configuring webservers
echo "DEPLOYING WEBSERVERS"
./web_setup.sh

# Running script for configuring database proxy and db servers
echo "DEPLOYING DATABASES"
./hadb_setup.sh


