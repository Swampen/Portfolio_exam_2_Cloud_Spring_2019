#! /bin/bash

# Creates the security group
openstack security group create dats06-security

#Adds appropriate rules to the security group
#Permitting ssh from the outside
openstack security group rule create --protocol tcp 
	--dst-port 22 
	--remote-group dats06-security

openstack security group rule create --protocol tcp 
	--remote-ip 0.0.0.0/0 
	--dst-port 22 dats06-security

#Permitting HTTP from the outside
openstack security group rule create --protocol tcp 
	--remote-ip 0.0.0.0/0 
	--dst-port 80 dats06-security

#Permits MySQL internally
openstack security group rule create 
	--protocol tcp 
	--dst-port 3306 
	--remote-group dats06-security dats06-security

#Permits syncing in the galera cluster
openstack security group rule create --protocol tcp 
	--dst-por 4444 
	--remote-group dats06-security dats06-security

openstack security group rule create --protocol tcp 
	--dst-port 4567 
	--remote-group dats06-security dats06-security

openstack security group rule create --protocol tcp 
	--dst-port 4568 
	--remote-group dats06-security dats06-security


#Creates key-pair
openstack keypair create --public-key dats06-key.pem.pub dats06-key 

#Creates 3 VMs to be used as web servers using Ubuntu16.04 and the m1.512MB4GB flavor
openstack server create --image 'Ubuntu16.04' 
	--flavor m1.512MB4GB 
	--security-group dats06-security 
	--key-name dats06-key 
	--nic net-id=BSc_dats_network 
	--min 1 
	--max 3 
	--wait dats06-web

#Creates 1 VM to be used as a database proxy
openstack server create --image 'Ubuntu16.04' 
	--flavor m1.512MB4GB 
	--security-group dats06-security 
	--key-name dats06-key 
	--nic net-id=BSc_dats_network 
	--min 1 
	--max 1 
	--wait dats06-dbproxy

#Creates 3 VMs to be used as databases
openstack server create --image 'Ubuntu16.04' 
	--flavor m1.512MB4GB 
	--security-group dats06-security 
	--key-name dats06-key 
	--nic net-id=BSc_dats_network 
	--min 1 
	--max 3 
	--wait dats06-db
