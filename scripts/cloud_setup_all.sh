#! /bin/bash

# Sourcing parameter file given as argument
source $1;

# Running script for building instances
echo "DEPLOYING VMs"
./vm_setup.sh

# Sleeping to avoid problem with Alto reporting instance readiness to early
echo "Resting to let the VMs recover after reboot, pleas allow 15 seconds for a light snooze..........zzzzzzzzzzzzzZZZZZZZZZZZzzzzzzzZZZZzzzzzzz........"
sleep 15

# Running script for configuring webserver loadbalancer
echo "DEPLOYING LOADBALANCER"
./lb_setup.sh

# Running script for configuring webservers
echo "DEPLOYING WEBSERVERS"
./web_setup.sh

# Running script for configuring database proxy and db servers
echo "DEPLOYING DATABASES"
./hadb_setup.sh


