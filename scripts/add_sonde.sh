#!/bin/bash

echo -e "Script pour l'ajout de nouvelles sondes perfSONAR à l'Observatoire ...\n"
x=0
f=0

usage() { echo "Usage : $0 -s <address> -f <fichier.JSON>" 1>&2; exit 1;}

while getopts "s:f:" option; do
  case "${option}" in
    s)
      x=1
      SERVER=${OPTARG}
      ;;
    f)
      f=1
      FICHIER=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

function paquets {
yum -y update
yum -y install epel-release
yum -y install http://software.internet2.edu/rpms/el7/x86_64/main/RPMS/perfSONAR-repo-0.8-1.noarch.rpm
yum clean all
yum -y install perfsonar-toolkit
sleep 2
systemctl start pscheduler-scheduler
systemctl start pscheduler-runner
systemctl start pscheduler-archiver
systemctl start pscheduler-ticker
systemctl start perfsonar-lsregistrationdaemon
systemctl start bwctl-server
systemctl start owamp-server
}

ip="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"


if [ $x -eq 1 ] && [ $f -eq 1 ] ; then

if [[ $SERVER =~ $ip ]] ; then

reponse=2
while [ $reponse -ne 1 ] && [ $reponse -ne 0 ] ; do
  echo -e "Ce système a-t-il installé à partir de l'image CentOS Full Install ISO ? [1=oui/0=non]"
  read reponse
done

if [ $reponse -eq 0 ] ; then
  paquets
fi

  if ping -c 1 $SERVER &> /dev/null ; then 
    if curl -f http://$SERVER/$FICHIER ; then
      echo -e "\n*******************************************************************\nFichier JSON trouvé ..."
      sleep 2
      echo -e "\n\nINFORMATION: UBICATION DE LA SONDE. Entrez la ville :"
      read city
      echo "INFORMATION: UBICATION DE LA SONDE. Entrez l'état :"
      read state
      echo "INFORMATION: UBICATION DE LA SONDE. Entrez la latitude :"
      read lati
      echo "INFORMATION: UBICATION DE LA SONDE. Entrez la longitude :"
      read longi
      echo "INFORMATION: Entrez une description :"
      read descr
      echo "INFORMATION: Entrez l'addresse de la sonde :"
      read addr

      echo "ville: "$city"" >> ./data.yaml
      echo "etat: "$state"" >> ./data.yaml
      echo "lat: "$lati"" >> ./data.yaml
      echo "lon: "$longi"" >> ./data.yaml
      echo "dec: "$descr"" >> ./data.yaml
      echo "add: "$addr"" >> ./data.yaml

      echo -e "\nAppel au script de modification du fichier mesh config : $FICHIER ..."
      sleep 2
      ./maj_mesh-config.py
      echo -e "\n***********************************************************************\nNettoyage ..."
      rm -f ./data.yaml
      sleep 1
    else
      echo -e "\nLe fichier entré n'existe pas dans le serveur !"
    fi
  else
    echo "Le serveur n'est pas disponible. Veulliez vérifier l'addresse ou essayez plus tard."
  fi
else
  echo "Addresse IP invalide. Veulliez en entrer une autre"
  exit 2
fi
else
  echo -e "Vous devez entrer l'addresse du serveur MESH et le nom du fichier JSON.\nUsage : $0 -s <address> -f <fichier.JSON>"
fi

