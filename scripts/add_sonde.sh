#!/bin/bash

echo -e "Script pour l'ajout de nouvelles sondes perfSONAR à l'Observatoire ...\n"
s=false ; f=false ; ver="7"
declare -A startServices=( ['0']="pscheduler-scheduler" ['1']="pscheduler-runner" ['2']="pscheduler-ticker" ['3']="pscheduler-archiver" ['4']="owamp-server" ['5']="bwctl-server" )

function aide { 
   echo ""
   echo -e "Usage : \n$0 -s <address> -f <fichier.JSON>" 1>&2; 
   echo ""
   echo "-s : L'addresse du serveur perfSONAR"
   echo "-f : Le nom du fichier JSON"
   echo ""
}   

if [ "$UID" -ne "0" ] ; then
   echo -e "Vous devez être superutilisateur pour exécuter $0. \nEssayez avec sudo $0";
   exit 9
fi

while getopts "s:f:" opts; do
  case $opts in
    s)
      s=true
      SERVER=${OPTARG}
      ;;
    f)
      f=true
      FICHIER=${OPTARG}
      ;;
    \?)
      aide
      exit 1
      ;;
  esac
done

#if [[ $(lsb_release -d | cut -f 2 | cut -d" " -f 3) =~ "\$9" ]]

function demarrerServices {

  for s in "${startServices[@]}"
    service $i start
  done
  
}

function paquets {

  repActuel=$(pwd)

  if [[ -e "/etc/debian_version" ]]; then
    cd /etc/apt/sources.list.d/
    wget http://downloads.perfsonar.net/debian/perfsonar-jessie-release.list
    wget -qO - http://downloads.perfsonar.net/debian/perfsonar-debian-official.gpg.key | apt-key add -
    cd $repActuel
    apt-get -y update
    apt-get -y install perfsonar-toolkit
  elif [[ -e "/etc/centos-release" ]]; then
    yum -y install epel-release
    yum -y install http://software.internet2.edu/rpms/el7/x86_64/main/RPMS/perfSONAR-repo-0.8-1.noarch.rpm
    yum clean all
    yum -y install perfsonar-toolkit
  fi
  demarrerServices
}

#ip="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"


if [ $x ] && [ $s ] ; then

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
    echo -e "\n\nINFORMATION: EMPLACEMENT DE LA SONDE. Entrez la ville :"
    read city
    echo "INFORMATION: EMPLACEMENT DE LA SONDE. Entrez l'état :"
    read state
    echo "INFORMATION: EMPLACEMENT DE LA SONDE. Entrez la latitude :"
    read lati
    echo "INFORMATION: EMPLACEMENT DE LA SONDE. Entrez la longitude :"
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
   aide
fi

