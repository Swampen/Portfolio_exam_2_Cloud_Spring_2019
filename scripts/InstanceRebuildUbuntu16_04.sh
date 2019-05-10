#! /bin/bash

# This script rebiulds all VMs to base ubuntu 16.04 image without deleting the VMs.

# Getting correct path to script directory
dir=$(dirname "$0")

# Sourcing openstack 
source "$dir"/dats06_project-openrc.sh

nova rebuild dats06-lb Ubuntu16.04
nova rebuild dats06-web-1 Ubuntu16.04
nova rebuild dats06-web-2 Ubuntu16.04
nova rebuild dats06-web-3 Ubuntu16.04
nova rebuild dats06-dbproxy Ubuntu16.04
nova rebuild dats06-db-1 Ubuntu16.04
nova rebuild dats06-db-2 Ubuntu16.04
nova rebuild dats06-db-3 Ubuntu16.04

echo "Rebuild done!!"