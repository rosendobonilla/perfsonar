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
   echo -e "\n+-----------------------------------------------------------------+\n"
   echo -e "Le script à echoué du à l'erreur suivante : \n$1\n"
   echo -e "\n+-----------------------------------------------------------------+\n"
   exit "$2"
}

assurer_root () {
   if [ "$EUID" -ne "0" ] ; then
      return 1
   fi
   return 0
}

dependences_script () {
   if [[ -e "/etc/debian_version" ]]; then
      echo "Systeme Debian"
      if ! command -v whiptail>/dev/null 2>&1 ; then apt-get -y install whiptail; fi
   elif [[ -e "/etc/centos-release" ]]; then
      echo "Systeme CentOS"
      if ! command -v whiptail>/dev/null 2>&1 ; then yum -y install newt; fi
      yum -y install python-yaml
   fi
}
assurer_entres () {
   if [ $optSRV == "1" ] && [ $optFICH == "1" ]; then
      return 0
   fi
   return 1
}

verifier_ping_reponse () {
   if ping -c 1 $SERVER &> /dev/null ; then 
      return 0
   fi
   return 1
}

ver_fichier_conf () {
   if [ -f "$FICHIER" ]; then
      return 0
   fi
   return 1
}

information () {
   descr=$(whiptail --inputbox "Entrez une description pour la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                        
   exitstatus=$?
   if [ $exitstatus = 0 ]; then
      echo "Description établie."
   else
      echo "Installation interrompue."
      return 1
   fi
    
   addr=$(whiptail --inputbox "Entrez l'addresse de la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                                                            
   exitstatus=$?
   if [ $exitstatus = 0 ]; then
      echo "Addresse établie."
   else
      echo "Installation interrompue."
      return 1
   fi
    
   id=$(whiptail --inputbox "Entrez une identifient pour la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                        
   exitstatus=$?
   if [ $exitstatus = 0 ]; then
      echo "Identifient établie."
   else
      echo "Installation interrompue."
      return 1
   fi
   return 0
}

creation_data_yaml () {
   echo "id: "$id"" >> ./data.yaml
   echo "desc: "$descr"" >> ./data.yaml
   echo "add: "$addr"" >> ./data.yaml
   return 0
}

creation_json () {
   path_SRV = "/var/www/html"
   /usr/lib/perfsonar/bin/build_json -o $path_SRV/mesh_central.json $FICHIER
   if [ $? != "0" ] ; then
      return 1
   fi
   return 0
}

backup_fichiers () {
   cp $FICHIER $FICHIER.bak
}

recuperation () {
   mv $FICHIER.bak $FICHIER
   if creation_json ; then
      echo "Recupération de la config precédente réussite."
      return 0
   else
      return 1
   fi
}

appel_script_modif () {
   echo -e "\nAppel au script de modification du fichier mesh config : $FICHIER ..."
   sleep 2
   if [ ! -f "./maj_mesh-config.py" ]; then
      return 1
   else
      ./maj_mesh-config.py "${FICHIER}"
      sed -i "0,/#add_sonde/ s/#add_sonde//" mesh_tmp.conf
      echo -e "\n+-----------------------------------------------------------------+\n"
      echo -e "Nettoyage...\n"
      echo -e "\n+-----------------------------------------------------------------+\n"
      rm -f ./data.yaml
      rm -f $path_SRV/mesh_central.json
      backup_fichiers
      rm -f $FICHIER
      mv ./mesh_tmp.conf $FICHIER
      if ! creation_json ; then
         if ! recuperation ; then
            die "Une erreur s'est produite pendant la récuperation de la configuration précedente." 1
         fi
         die "Erreur dans la création de la nouvelle config pour le fichier JSON." 1
      fi
      rm -f $FICHIER.bak
      return 0
   fi
   return 0
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
   aide
   die "Il manque des paramètres pour le script" 1
fi

if ! verifier_ping_reponse ; then
   die "Le serveur n'est pas disponible. Veuilliez vérifier l'addresse ou ressayez plus tard." 1
fi

if ! ver_fichier_conf ; then
   die "Le fichier spécifié n'a pas été trouvé dans le chemin indiqué." 1
else
   echo -e "\n*******************************************************************\nFichier de conf MESH trouvé ..."
   sleep 2
fi

if ! information ; then
   die "L'installation a été interrompue." 1
fi

if ! creation_data_yaml ; then
   die "Erreur inconnue." 1
fi
    
if ! appel_script_modif ; then
   die "Le script de modification maj_mesh-config.py n'existe pas dans le répertoire actuel." 1
fi
