#!/bin/bash

echo -e "Script pour l'ajout de nouvelles sondes perfSONAR à l'Observatoire ...\n"
optSRV="0" ; optFICH="0"

function aide { 
   echo ""
   echo "Usage : $0 -s <address> -f <fichier.JSON>" 1>&2; 
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
      optSRV="1"
      SERVER=${OPTARG}
      ;;
    f)
      optFICH="1"
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

  for s in "${startServices[@]}" ; do
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


if [ $optSRV == "1" ] && [ $optFICH == "1" ]; then

if (whiptail --title "Image CentOS perfSONAR" --yesno "Ce système a-t-il installé à partir de l'image CentOS Full Install ISO ?" 8 78) then
    echo -e "\nAucun paquet à installer.\n"
else
    paquets
fi

if ping -c 1 $SERVER &> /dev/null ; then 
  if curl -f http://$SERVER/$FICHIER ; then
    echo -e "\n*******************************************************************\nFichier JSON trouvé ..."
    sleep 2
    
    descr=$(whiptail --inputbox "Entrez une description pour identifier la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                        
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      echo "Description établie."
    else
      echo "Installation interrompue."
      exit 1
    fi
    
    addr=$(whiptail --inputbox "Entrez l'addresse de la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                                                            
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      echo "Addresse établie."
    else
      echo "Installation interrompue."
      exit 1
    fi
    
    echo "$descr $addr"
    #echo "desc: "$descr"" >> ./data.yaml
    #echo "add: "$addr"" >> ./data.yaml

    #echo -e "\nAppel au script de modification du fichier mesh config : $FICHIER ..."
    #sleep 2
    #./maj_mesh-config.py
    #echo -e "\n***********************************************************************\nNettoyage ..."
    #rm -f ./data.yaml
    #sleep 1
  else
    echo -e "\nLe fichier entré n'existe pas dans le serveur !"
  fi
else
  echo "Le serveur n'est pas disponible. Veulliez vérifier l'addresse ou essayez plus tard."
fi

else
   aide
fi

