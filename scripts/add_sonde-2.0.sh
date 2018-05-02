#!/bin/bash

ACTION="" ; DIR="" ; path_SRV="/var/www/html" ; jour=$(date "+%d-%m-%Y") ; heure=$(date "+%H:%M") ; nomBack="meshconfig-$jour-$heure.bak" ; TYPE="" ; MEMBRE=""

aide()
{
    echo ""
    echo "Usage : $0 --action=[list,add,delete] --dir=[répertoire]" 1>&2
    echo ""
    echo "--action : spécifie quelle type de tache on veut faire."
    echo ""
    echo "    list : affiche la liste des sondes créees"
    echo "     add : permet d'ajouter une nouvelle sonde"
    echo "  delete : permet de supprimer une sonde"
    echo ""
    echo "--dir    : spécifie le chemin vers le répertoire où se trouve toute la configuration MESH."
}

#Message appelé lors de chaque erreur

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
      if ! command -v whiptail>/dev/null 2>&1 ; then apt-get -y install whiptail; fi
   elif [[ -e "/etc/centos-release" ]]; then
      if ! command -v whiptail>/dev/null 2>&1 ; then yum -y install newt; fi
      if [ -z $(rpm -qa | grep yaml) ] ; then yum -y install python-yaml; fi
   fi
   return 0
}

#Il faut vérifier que le script a les paramètres requis

assurer_entres () {
   if [[ $ACTION == "" ]] || [[ $DIR == "" ]] ; then
      return 1
   fi

   return 0
}

#Vérifier que tous les fichiers qui comportent le script sont dans les répertoire courant

fichiers_script_presents () {
   if [ ! -f "./maj_meshconfig.py" ] || [ ! -f "./template.jinja2" ]; then
      return 1
   fi
   if [ ! -d "$DIR/sites" ] || [ ! -d "$DIR/backup" ] || [ ! -d "$DIR/groupes" ] || [ ! -f "$DIR/meshconfig.conf" ]  ; then
      return 1
   fi

   return 0
}


#Vérifier la présence du fichier entré en paramètre

ver_fichier_conf () {
   if [ -f "$DIR/meshconfig.conf" ]; then
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

   groupe=$(whiptail --title "Manage groups" --menu "Choisissez le groupe pour la nouvelle sonde" 16 78 5 \
        "Interne" "Groupe sondes internes ObAS"\
        "Exterieur" "Groupe sondes publiques" 3>&2 2>&1 1>&3)

   opt=$(echo $groupe | tr '[:upper:]' '[:lower:]')


   if [[ $opt == "interne" ]] ; then
      TYPE="mesh"
   elif [[ $opt == "exterieur" ]] ; then
      TYPE="disjoint"

      tipo=$(whiptail --title "Manage groups" --menu "Choisissez le type de membre. Par défaut TYPE B" 16 78 5 \
              "Member A" "Membre sur l'observatoire"\
              "Member B" "Membre à l'exterieur" 3>&2 2>&1 1>&3)

      opt2=$(echo $tipo | tr '[:upper:]' '[:lower:]' | sed 's/ //g')
      if [[ $opt2 == "membera" ]] ; then
         MEMBRE="a_member"
      elif [[ $opt2 == "memberb" ]] ; then
         MEMBRE="b_member"
 	 echo $MEMBRE
      fi
   fi
   return 0
}

#Création du fichier data.yaml pour remplir le template

creation_data_yaml () {
   echo "Etape creation du fichier data.yaml"
   echo "desc: "$descr"" >> ./data.yaml
   echo "add: "$addr"" >> ./data.yaml
   return 0
}

#Création du nouveau fichier JSON

creation_json () {
   /usr/lib/perfsonar/bin/build_json -o $path_SRV/mesh_central.json "$REP/meshconfig.conf"
   if [ $? != "0" ] ; then
      return 1
   fi
   return 0
}

#Sauvegarde du fichier de conf actuel pour le restaurer en cas d'echec

backup_fichiers () {
   mv "$REP/meshconfig.conf" $REP/backup/$nomBack
}

#Essayez de revenir à l'état anterieur au lancement du script

recuperation () {
   rm -f "$REP/meshconfig.conf"
   cp "$REP/backup/$nomback" "$REP/meshconfig.conf"
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

#Affichage des derniers logs pour vérifier si tout s'est bien passé

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

#Appel aux scripts en Python qui feront toutes les modifications dans les fichiers correspondants

appel_script_modif () {
   echo -e "\nAppel au script de modification du fichier mesh config : $REP ..."

   #Cette partie permet  d'envoyer les paramètres selon le type de groupe, le groupe disjoint nécessite d'un paramètre en plus
   if [[ $TYPE == "disjoint" ]] ; then
      ./maj_meshconfig.py "${REP}" "${addr}" "${TYPE}" "${MEMBRE}"
   else
      ./maj_meshconfig.py "${REP}" "${addr}" "${TYPE}"
   fi
   echo -e "\n+-----------------------------------------------------------------+\n"
   echo -e "Nettoyage...\n"
   echo -e "\n+-----------------------------------------------------------------+\n"
   rm -f ./data.yaml
   #rm -f $path_SRV/mesh_central.json
   backup_fichiers
   ./creation_mesh.py "${REP}"
   #if ! creation_json ; then
   #   if ! recuperation ; then
   #      die "Une erreur s'est produite pendant la récuperation de la configuration précedente. Vous avez le fichier $REP.bak comme backup. Là dedans, vous avez toute votre configuration MESH precédente à la MàJ esssayée." 1
   #   fi
   #   die "Erreur dans la création de la nouvelle configuration pour le fichier JSON." 1
   #fi
   return 0
}

tache_list () {
   echo ""
   echo "TACHE LISTER LES SONDES"
   echo ""
   find $DIR/sites  -printf "%f\n"
   echo ""
}


#Valider les arguments passés en paramètre

# while getopts "u:" opts; do
#   case $opts in
#     u)
#       optREP="1"
#       REP=$(echo ${OPTARG} | sed -e 's/\/$//')
#       ;;
#     \?)
#       aide
#       exit 1
#       ;;
#   esac
# done
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`

    case $PARAM in
        -h | --help)
            aide
            exit
            ;;
        --action)
            ACTION=$VALUE
            ;;
        --dir)
            DIR=$VALUE
            ;;
        *)
            echo "Parametre inconnu."
            aide
            exit 1
            ;;
    esac
    shift
done


#Lancement de chaque étape en vérifiant les erreurs qui peuvent apparaitre

echo -e "\n\nSCRIPT POUR L'ADMINISTRATION DES SONDES perfSONAR À L'OBSERVATOIRE ...\n"

if ! assurer_root ; then
   die "Vous devez être superutilisateur pour exécuter ce script" 1
fi

if ! assurer_entres ; then
   aide
   die "Manque des paramètres pour le script" 1
else
   dependences_script
fi

if ! fichiers_script_presents ; then
   die "Manque de fichiers nécessaires pour le script. Veulliez vérifier qu'ils sont dans le répertoire correspondant. \nFichiers script (repertoire courant) : add_sonde.sh | maj_mesh-config.py | template.jinja2 | creation_mesh.py \
        \nFichiers et repertoires MESH nécessaires (repertoire que vous avez définit) : REP groupes, sites et backup | FICH meshconfig.conf" 1
fi

if ! ver_fichier_conf ; then
   die "Aucun fichier de configuration MESH n'a pas été trouvé dans le chemin indiqué." 1
fi

if [ $ACTION == "list" ] ; then
   tache_list
elif [ $ACTION == "add" ] ; then
    echo "TACHE AJOUTER UN SONDE"
    if ! information ; then
       die "L'installation a été interrompue." 1
    fi

    if ! creation_data_yaml ; then
       die "Erreur inconnue." 1
    fi

    if ! appel_script_modif ; then
       die "Un erreur s'est produite pendant l'exécution de l'appel au script de modification du fichier JSON." 1
    fi

    #if ! redemarrer_serv_perfsonar ; then
    #   die "Un erreur s'est produite pendant le rédemarrage des services perfSONAR." 1
    #else
    #   recuperer_logs
    #fi
elif [ $ACTION == "delete" ] ; then
    echo "TACHE SUPRIMER UN SONDE"
else
    aide
fi
exit 0
