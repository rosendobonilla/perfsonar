#!/bin/bash

optSRV="0" ; optFICH="0"

aide () { 
   echo ""
   echo "Usage : $0 -s <address> -f <fichier.JSON>" 1>&2; 
   echo ""
   echo "-s : L'addresse du serveur perfSONAR"
   echo "-f : Le nom du fichier JSON"
   echo ""
}   

die () {
    echo "Le script à echoué du à 'erreur suivante : $1"
    exit "$2"
}

assurer_root () {
   if [ "$EUID" -ne "0" ] ; then
      return 1
   fi
   return 0
}


#if [[ -e "/etc/debian_version" ]]; then

#elif [[ -e "/etc/centos-release" ]]; then
  
#fi

assurer_entres () {
   if [ $optSRV != "1" ] && [ $optFICH != "1" ]; then
      retur 1
   fi
   return 0
}

verifier_ping_reponse () {
   if ping -c 1 $SERVER &> /dev/null ; then 
      return 0
   fi
   return 1
}

fichier_json () {
   if curl -f http://$SERVER/$FICHIER ; then
      return 0
   fi
   return 1
}


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

echo -e "Script pour l'ajout de nouvelles sondes perfSONAR à l'Observatoire ...\n"

if ! assurer_root ; then
    die "Vous devez être superutilisateur pour exécuter ce script" 1
fi

if ! assurer_entres ; then
    die "Il manque des paramètres pour le script" 1
fi

if ! assurer_ping_reponse ; then
    die "Le serveur n'est pas disponible. Veuilliez vérifier l'addresse ou ressayez plus tard." 1
fi

if ! fichier_json ; then
    die "Le fichier spécifié n'a pas été trouvé dans le serveur." 1
fi


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
