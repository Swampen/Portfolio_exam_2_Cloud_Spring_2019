#! /bin/bash

source dats06-params.sh

echo "##### Editing /etc/hosts files #####"
vmnames=(`openstack server list -c Name | awk '!/^$|Name/ {print $2;}'`)

ipSubnet="10\.10"
names=()
ipList=()
hostfileEntry=""
for vm in ${vmnames[@]}; do
       name=$vm
       echo -n "Getting IP for $name: "
       ip=$(openstack server show $name | grep -o "$ipSubnet\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
       echo "$ip"
       ipList+=("$ip")
       name2=""
      if [[ $name = $DBProxyName ]]; then
          name2=`echo $name | sed s/$DBProxyName/$DBProxyHostName/g`
      elif [[ $name =~ $DBName-[0-9]* ]]; then
          name2=`echo $name | sed -E s/$DBName-/$DBHostName/g`
      elif [[ $name =~ $webServerName-[0-9]* ]]; then
          name2=`echo $name | sed -E s/$webServerName-/$webServerHostName/g`
      elif [[ $name = $LBName ]]; then
          name2=`echo $name | sed s/$LBName/$LBHostName/g`
      else
          echo not found
      fi
      hostfileEntry="$ip $name $name2 \\n$hostfileEntry"
done
echo rip
sleep 10

# sed s/dats06-db-/db/g
# sed s/dats06-web-/web/g
# sed s/dats06-dbproxy/maxscale/



script=("
sudo sed -i '1 i\\$hostfileEntry' /etc/hosts;
sudo sed -i '$ a LANGUAGE=\"$userLocale\"\nLC_ALL=\"$userLocale\"' /etc/default/locale;
sudo unlink /etc/localtime;
sudo ln -s /usr/share/zoneinfo/$timezone /etc/localtime;
sudo locale-gen $userLocale;
sudo sed -i s/XKBLAYOUT=.*/XKBLAYOUT=\"$keyboard\"/g /etc/default/keyboard;
")

test=("
echo Hello World;
hostname;
")

parallel-ssh -i -H "${ipList[*]}" \
        -l $username \
        -x "-i '$sshKeyLocation' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='$sshProxyCommand'" \
        "$script"

echo "Rebooting the VMs"
for i in ${!vmnames[@]}; do
  let n=i+1
	echo -n "$n/${#vmnames[@]} - rebooting ${vmnames[$i]} - "
  openstack server reboot --wait ${vmnames[$i]}
done
