#!/bin/bash

optSRV="0" ; optFICH="0"
path_SRV="/var/www/html"

aide () { 
   echo ""
   echo "Usage : $0 -s <address> -f <fichier.JSON>" 1>&2; 
   echo ""
   echo "-s : L'addresse du serveur perfSONAR. IP ou hostname."
   echo "-f : Chemin du fichier mesh-config"
   echo ""
}   

#Message appelé avec chaque erreur

die () {
   echo -e "\n+-----------------------------------------------------------------+\n"
   echo -e "Le script à echoué à cause de l'erreur suivante : \n$1\n"
   echo -e "\n+-----------------------------------------------------------------+\n"
   exit "$2"
}

#D'abord assurer que le script est lancé en tant que superutilisateur

assurer_root () {
   if [ "$EUID" -ne "0" ] ; then
      return 1
   fi
   return 0
}

#Le script a besoin de certains paquets pour fonctionner correctement. C'est le cas de 'whiptail' et 'python-yaml'. Le premier sert à créer une interface graphique en terminal, utilisé pour demander les informations nécessaires pour la création de la nouvelle sonde. Le paquet 'python-yaml' est nécessaire pour pouvoir traiter des fichiers .yaml, les importer dans et avec un template jinja2 créer un nouveau fichier de configuration.

dependences_script () {
   if [[ -e "/etc/debian_version" ]]; then
      echo "Systeme Debian"
      if ! command -v whiptail>/dev/null 2>&1 ; then apt-get -y install whiptail; fi
   elif [[ -e "/etc/centos-release" ]]; then
      echo "Systeme CentOS"
      if ! command -v whiptail>/dev/null 2>&1 ; then yum -y install newt; fi
      if [ -z $(rpm -qa | grep yaml) ] ; then yum -y install python-yaml; fi
   fi
   return 0
}

#Il faut vérifier que le script a les paramètres requis

assurer_entres () {
   if [ $optSRV == "1" ] && [ $optFICH == "1" ]; then
      return 0
   fi
   return 1
}

#Vérifier que tous les fichiers qui comportent le script sont dans les répertoire courant

fichiers_script_presents () {
   if [ ! -f "./maj_mesh-config.py" ] || [ ! -f "./template.jinja2" ]; then
      return 1
   fi
   return 0
}

#Vérifier que le serveur perfSONAR est joignable

verifier_ping_reponse () {
   if ping -c 1 $SERVER &> /dev/null ; then 
      return 0
   fi
   return 1
}

#Vérifier la présence du fichier entré en paramètre

ver_fichier_conf () {
   if [ -f "$FICHIER" ]; then
      echo -e "\n+-----------------------------------------------------------------+\nFichier de conf MESH trouvé ..."
      return 0
   fi
   return 1
}

#Demander les informations concernant la sonde

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
    
   id=$(whiptail --inputbox "Entrez un identifient pour la sonde." 8 78 --title "Information" 3>&1 1>&2 2>&3)
                        
   exitstatus=$?
   if [ $exitstatus = 0 ]; then
      echo "Identifient établie."
   else
      echo "Installation interrompue."
      return 1
   fi
   return 0
}

#Création du fichier data.yaml pour remplir le template

creation_data_yaml () {
   echo "Etape creation du fichier data.yaml"
   echo "id: "$id"" >> ./data.yaml
   echo "desc: "$descr"" >> ./data.yaml
   echo "add: "$addr"" >> ./data.yaml
   return 0
}

#Création du nouveau fichier JSON

creation_json () {
   /usr/lib/perfsonar/bin/build_json -o $path_SRV/mesh_central.json $FICHIER
   if [ $? != "0" ] ; then
      return 1
   fi
   return 0
}

#Sauvegarde du fichier de conf actuel pour le restaurer en cas d'echec 

backup_fichiers () {
   cp $FICHIER $FICHIER.bak
}

#Essayez de revenir à l'état anterieur au lancement du script

recuperation () {
   mv $FICHIER.bak $FICHIER
   if creation_json ; then
      echo "Recupération de la config precédente réussite."
      return 0
   else
      return 1
   fi
}

#Rédemarrer les services perfSONAR nécessaires pour prendre en compte la nouvelle configuration

redemarrer_serv_perfsonar () {
   systemctl restart perfsonar-meshconfig-agent
   if [ $? != "0" ] ; then
      return 1
   fi
   systemctl restart perfsonar-meshconfig-guiagent
   if [ $? != "0" ] ; then
      return 1
   fi
   return 0
}

#Affichage des derniers logs pour vérifier si tous s'est bien passé

recuperer_logs () {
   clear
   echo -e "\n+-------------------------------------------------------------------------------------+\n"
   echo -e "+----------------------DERNIERS LOGS MESHConfig AGENT---------------------------------+"
   echo -e "\n+-------------------------------------------------------------------------------------+\n"
   tail -15 /var/log/perfsonar/meshconfig-agent.log
   echo -e "\n+-------------------------------------------------------------------------------------+\n"
   echo -e "+----------------------DERNIERS LOGS MESHConfig GUIAGENT------------------------------+"
   echo -e "\n+-------------------------------------------------------------------------------------+\n"
   tail -15 /var/log/perfsonar/meshconfig-guiagent.log
}

#Appel au script en Python qui fera tous les modifications dans les fichiers correspondants

appel_script_modif () {
   echo -e "\nAppel au script de modification du fichier mesh config : $FICHIER ..."
   sleep 1
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
         die "Une erreur s'est produite pendant la récuperation de la configuration précedente. Vous avez le fichier $FICHIER.bak comme backup. Là dedans, vous avez toute votre configuration MESH precédente à la MàJ esssayée." 1
      fi
      die "Erreur dans la création de la nouvelle configuration pour le fichier JSON." 1
   fi
   rm -f $FICHIER.bak
   return 0
}

#Valider les arguments passés en paramètres

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

#Lancement de chaque étape en vérifiant les erreurs qui peuvent apparaitre

echo -e "\n\nScript pour l'ajout de nouvelles sondes perfSONAR à l'Observatoire ...\n"

if ! assurer_root ; then
   die "Vous devez être superutilisateur pour exécuter ce script" 1
fi

if ! fichiers_script_presents ; then
   die "Manque de fichiers nécessaires pour le script. Veuilliez vérifier qu'ils sont dans le répertoire courant. Fichiers: add_sonde.sh / maj_mesh-config.py / template.jinja2" 1
fi

if ! assurer_entres ; then
   aide
   die "Il manque des paramètres pour le script" 1
else
   dependences_script
fi

if ! verifier_ping_reponse ; then
   die "Le serveur n'est pas disponible. Veuilliez vérifier l'addresse ou ressayez plus tard." 1
fi

if ! ver_fichier_conf ; then
   die "Le fichier spécifié n'a pas été trouvé dans le chemin indiqué." 1
fi

if ! information ; then
   die "L'installation a été interrompue." 1
fi

if ! creation_data_yaml ; then
   die "Erreur inconnue." 1
fi
    
if ! appel_script_modif ; then
   die "Un erreur s'est produite pendant l'exécution de l'appel au script de modification du fichier JSON." 1
fi

if ! redemarrer_serv_perfsonar ; then
   die "Un erreur s'est produite pendant le rédemarrage des services perfSONAR." 1
else
   recuperer_logs
fi

exit 0
