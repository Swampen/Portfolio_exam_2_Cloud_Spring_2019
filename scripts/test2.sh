#!/bin/bash

# Assigning "booleans"
WebOK=true
DBPOK=true
DBOK=true

echo "$WebOK, $DBPOK, $DBOK"


exists=`openstack server list --status ACTIVE -c Name | awk '!/^$|Name/ {print $2;}'`

for vm in $exists; do
    if [[ $vm =~ ($webServerName-)([1-9]) ]]
    then
      echo "$vm already exists"
      WebOK=true
    fi

    # If i corresponds with the database proxy name
    # delete said server, if i does not match then set corresponding boolean to true
    if [[ $vm = "$DBProxyName" ]]
    then
      echo "$vm already exists"
      DBPOK=true
    fi

    # If i corresponds with the database name with a - and a number at the end
    # delete said server, if i does not match then set corresponding boolean to true
    if [[ $vm =~ ($DBName-)([1-9]) ]]
    then
      echo "$vm already exists"
      DBOK=true
    fi
done

echo "$WebOK, $DBPOK, $DBOK"
