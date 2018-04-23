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

if [ "$EUID" -ne "0" ] ; then
   echo -e "Vous devez être superutilisateur pour exécuter $0.";
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

if [[ -e "/etc/debian_version" ]]; then

elif [[ -e "/etc/centos-release" ]]; then
  
fi
  
if [ $optSRV == "1" ] && [ $optFICH == "1" ]; then

if ping -c 1 $SERVER &> /dev/null ; then 
  if curl -f http://$SERVER/$FICHIER ; then
    echo -e "\n*******************************************************************\nFichier JSON trouvé ..."
    sleep 2
    
    descr=$(whiptail --inputbox "Entrez une description pour la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                        
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
    
    id=$(whiptail --inputbox "Entrez une identifient pour la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                        
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      echo "Identifient établie."
    else
      echo "Installation interrompue."
      exit 1
    fi
    
    echo "id: "$id"" >> ./data.yaml
    echo "desc: "$descr"" >> ./data.yaml
    echo "add: "$addr"" >> ./data.yaml

    echo -e "\nAppel au script de modification du fichier mesh config : $FICHIER ..."
    sleep 2
    ./maj_mesh-config.py "${$FICHIER}"
    echo -e "\n***********************************************************************\nNettoyage ..."
    rm -f ./data.yaml
    rm -f mesh_tmp.conf
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

