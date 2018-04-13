#!/bin/bash

#yum -y update
#yum -y install epel-release
#yum -y install http://software.internet2.edu/rpms/el7/x86_64/main/RPMS/perfSONAR-repo-0.8-1.noarch.rpm
#yum clean all
#yum -y install perfsonar-toolkit

#sleep 2

#systemctl start pscheduler-scheduler
#systemctl start pscheduler-runner
#systemctl start pscheduler-archiver
#systemctl start pscheduler-ticker
#systemctl start perfsonar-lsregistrationdaemon
#systemctl start bwctl-server
#systemctl start owamp-server

x=0

while getopts s: option; do
  case $option in
    s)
      x=1
      SERVER=${OPTARG}
      ;;
  esac
done

ip="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

if [ $x -eq 1 ] ; then
if [[ $SERVER =~ $ip ]] ; then
  if ping -c 1 $SERVER &> /dev/null ; then 
    echo "Success"
  else
    echo "Le serveur n'est pas disponible. Veulliez vérifier l'addresse ou essayez plus tard."
  fi
else
  echo "Addresse IP invalide. Veulliez en entrer une autre"
  exit 2
fi
else
  echo "Vous devez entrer l'addresse du serveur MESH. Usage : $0 -s address"
fi

