#!/bin/bash

#-----------------------------------------------------------------------------------------------#
# Ce script est le script principal, ici on valide toutes les entrées, les erreurs qui peuvent  #
# apparaitre, les dependences et les appels aux scripts Python                                  #
#-----------------------------------------------------------------------------------------------#
#Corriger certaines functions

ACTION="" ; DIR="" ; path_SRV="/var/www/html" ; jour=$(date "+%d-%m-%Y") ; heure=$(date "+%H:%M") ; nomBack="meshconfig-$jour-$heure.bak" ; TYPE="" ; MEMBRE=""
bold=$(tput bold) ; normal=$(tput sgr0) ; italic=$(tput sitm) ; under=$(tput smul) ; tests_mesh="" ; tests_disj=""

arborescence () {
  echo """
EXAMPLE DES FICHIERS REQUIS PAR LE SCRIPT ET DE L'ARBORESCENCE DU REPERTOIRE

REPERTOIRE SCRIPT

.
├── manage_sonde.sh
├── creation_meshconfig.py
├── sonde_conf.py
└── template.jinja2

REPERTOIRE MESHCONFIG

../mesh
├── backup
│   ├── meshconfig-02-05-2018-09:20.bak
│   ├── meshconfig-02-05-2018-11:07.bak
├── groupes
│   ├── disjoint
│   │   ├── a_member
│   │   │   ├── mar.fr -> ../mesh/sites/mar.fr.cfg
│   │   │   ├── mex.fr -> ../mesh/sites/mex.fr.cfg
│   │   └── b_member
│   │       ├── arg.fr -> ../mesh/sites/arg.fr.cfg
│   │       └── col.fr -> ../mesh/sites/col.fr.cfg
│   └── mesh
│       ├── can.ops.fr -> ../mesh/sites/can.ops.fr.cfg
│       └── ops.est.fr -> ../mesh/sites/ops.est.fr.cfg
├── meshconfig.conf
├── sites
│    ├── arg.fr.cfg
│    ├── can.ops.fr.cfg
│    ├── col.fr.cfg
│    ├── mar.fr.cfg
│    ├── mex.fr.cfg
│    └── ops.est.fr.cfg
└── tests
    ├── actives
    │   └── actives.cfg
    ├── test_bw_tcp.cfg
    ├── test_bw_udp.cfg
    ├── test_latence.cfg
    ├── test_ping.cfg
    └── test_traceroute.cfg

"""
}

aide()
{
    echo ""
    echo "${bold}USAGE${normal}"
    echo "      $0 ${italic}--action=[list,add,delete,conftest] --dir=[répertoire] [-h] [--help]${normal}" 1>&2
    echo ""
    echo "${bold}ARGS${normal}"
    echo "${normal}${bold}      --action${normal}      spécifie quelle type de tache on veut réaliser."
    echo ""
    echo "          ${under}list${normal}      affiche la liste des sondes définies dans le fichier meshconfig"
    echo "          ${under}add${normal}       permet d'ajouter une nouvelle sonde"
    echo "          ${under}delete${normal}    permet de supprimer une sonde"
    echo "          ${under}conftest${normal}  permet de modifier les relations entre les groupes et les tests"
    echo ""
    echo "${bold}      --dir${normal}         spécifie le chemin vers le répertoire où se trouve toute la configuration MESH."
    echo "${bold}      -h, --help${normal}    usage."
    echo ""
    echo ""
}

#Message appelé lors de chaque erreur

die () {
   echo -e "\n+-----------------------------------------------------------------+\n"
   echo -e "Le script à echoué à cause de l'erreur suivante : \n$1\n"
   echo -e "\n+-----------------------------------------------------------------+\n"
   if [[ $2 == "5" ]] ; then arborescence ; fi
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
   if [ ! -f "./creation_meshconfig.py" ] || [ ! -f "./template.jinja2" ] || [ ! -f "./sonde_conf.py" ] ; then
      return 1
   fi
   if [ ! -d "$DIR/sites" ] || [ ! -d "$DIR/backup" ] || [ ! -d "$DIR/groupes" ] || [ ! -d "$DIR/tests" ] || [ ! -f "$DIR/meshconfig.conf" ]  ; then
      return 1
   fi

   return 0
}

lister_tests () {
  for file in $(ls -p $DIR/tests/ | grep -v /) ; do
    tests[i]=$(echo ${file%.*}) ; (( i++ ))
    tests[i]="" ; (( i++ ))
    tests[i]="OFF" ; (( i++ ))
  done
}
#Cette function permet de activer les cases du checklist selon le fichier actives.cfg

sel_items_checklist () {
  declare -a listeArg=("${!1}")

  lister_tests

  for i in $(seq 0 ${#tests[@]}) ; do
        for val in "${listeArg[@]}" ; do
            if [[ ${tests[i]} == $val ]] ; then
                ac=$i+2
                tests[ac]="ON"
            fi
       done
  done
}

active_tests () {
  i=0 ; ind=0
  while IFS='' read -r linea || [[ -n "$linea" ]]; do
      div=(${linea//,/ })
      if [[ ${div[0]} == "obas_interne_mesh" ]] ; then
          mesh[i]=${div[1]}
          (( i++ ))
      else
          disj[ind]=${div[1]}
          (( ind++ ))
      fi
  done < $DIR/tests/actives/actives.cfg
  i=0

  sel_items_checklist mesh[@]

  tests_mesh=$(whiptail --title "Tests Groupe INTERNE - MESH" --checklist --separate-output "\nPar défaut, les tests qui tournent pour ce groupe sont ceux déjà selectionés :" 25 78 16 "${tests[@]}" 3>&1 1>&2 2>&3)
  if [ $? = 1 ] || [[ $tests_mesh == "" ]] ; then die "Tache interrompue." 1 ; fi

  i=0

  sel_items_checklist disj[@]

  tests_disj=$(whiptail --title "Tests Groupe EXTERIEUR - DISJOINT" --checklist --separate-output "\nPar défaut, les tests qui tournent pour ce groupe sont ceux déjà selectionés :" 25 78 16 "${tests[@]}" 3>&1 1>&2 2>&3)
  if [ $? = 1 ] || [[ $tests_disj == "" ]] ; then die "Tache interrompue." 1 ; fi

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
   echo "desc: "$descr"" >> ./data.yaml
   echo "add: "$addr"" >> ./data.yaml
   return 0
}

#Création du nouveau fichier JSON

creation_json () {
   rm -f $path_SRV/mesh_central.json
   /usr/lib/perfsonar/bin/build_json -o $path_SRV/mesh_central.json "$DIR/meshconfig.conf"
   if [ $? != "0" ] ; then
      return 1
   fi
   echo -e "\nLe fichier JSON a été bien créé."
   return 0
}

#Sauvegarde du fichier de conf actuel pour le restaurer en cas d'echec

backup_fichiers () {
   mv "$DIR/meshconfig.conf" $DIR/backup/$nomBack
}

#Essayez de revenir à l'état anterieur au lancement du script

recuperation () {
   rm -f "$DIR/meshconfig.conf"
   cp "$DIR/backup/$nomback" "$DIR/meshconfig.conf"
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

tache_add () {
   echo -e "\nAppel au script de modification du fichier mesh config : $DIR ..."

   #Cette partie permet  d'envoyer les paramètres selon le type de groupe, le groupe disjoint nécessite d'un paramètre en plus
   if [[ $TYPE == "disjoint" ]] ; then
      ./sonde_conf.py "${DIR}" "${addr}" "${TYPE}" "${MEMBRE}"
   else
      ./sonde_conf.py "${DIR}" "${addr}" "${TYPE}"
   fi
   rm -f ./data.yaml
   backup_fichiers
   ./creation_meshconfig.py "${DIR}"
   return 0
}

tache_list () {
   echo "" ; i=1
   #Formatage de l'entete
   printf "\t\t%-25s\t\t%s\n\n" "${bold}HOST" "DESCRIPTION"
   for file in $(ls $DIR/sites) ; do                                                    #Recuperer les noms des sondes
     descr=$(grep description $DIR/sites/$file | sed -e 's/^[ ]*description//')
     printf "${normal}\t[ $i ]\t%-25s %s\n" "${file%.*}" "$descr"                                #Formater chaque ligne
     (( i++ ))
   done
   echo ""
}

tache_sup_sonde () {
  i=0
  #Ce bucle sert à créer un tableu de facon qu'il puisse etre traité par whiptail
  #Pour ca on a besoin de stocker en premier lieu le nom du fichier, ensuite son description et enfin l'etat de radiolist
  for file in $(ls $DIR/sites) ; do
    sondes[i]=$(echo ${file%.*}) ; (( i++ ))
    sondes[i]=$(grep description $DIR/sites/$file | sed -e 's/^[ ]*description//') ; (( i++ ))
    sondes[i]="OFF" ; (( i++ ))
  done

  #On recupere la sonde choisie dans le radiolist
  sonde_sup=$(whiptail --title "Supprimer une sonde " --radiolist "Choisissez la sonde que vous voulez supprimer :" 25 78 16 "${sondes[@]}" 3>&1 1>&2 2>&3)

  #Si l'utilisateur n'a rien chosi, on sort du script
  if [[ $sonde_sup == "" ]] ; then echo "Rien" ; return 1 ; fi

  #Radiolist utilise le tableau crée précedement
  if (whiptail --title "Supprimer une sonde" --yesno "Vous êtes en train de supprimer la sonde $sonde_sup. Vous devez vous assurer que vous n'en avez plus besoin. Voulez-vous continuer ?" 8 78) then
    lienS=$(find $DIR/groupes/ -name $sonde_sup)
    echo "Lien symbolique à supp : $lienS"
    echo "Site a supprimer : $DIR/sites/$sonde_sup.cfg"
    rm -f $lienS ; rm -f "$DIR/sites/$sonde_sup.cfg"                                     #Si l'utilisateur confirme la suppression on ecrase le lien symbolique et le site
    echo "Mise à jour de la nouvelle configuration ..."
    backup_fichiers                                                                      #On sauvegarde le fichier meshconfig actuel
    ./creation_meshconfig.py "${DIR}"                                                          #On crée un nouveau meshconfig
    echo "La sonde a été bien supprimée."
  else
    echo "La sonde n'a pas été supprimée."
    exit 1
  fi

  return 0
}

lister_param () {
  declare -a listeArg=("${!1}")

  for file in $(ls -p $DIR/tests/ | grep -v /) ; do
    tests[i]=$(echo ${file%.*}) ; (( i++ ))
    tests[i]="" ; (( i++ ))
    tests[i]="OFF" ; (( i++ ))
  done
}

tache_avancee () {
    repAc=$(pwd)
    whiptail --title "Manage tests" --yesno --yes-button "Continuer" --no-button "Annuler" "Dans cette section, vous allez modifier les paramétres de chaque test. Assurez-vous que les nouvelles valeurs sont valides." 8 78
    if [ $? = 1 ] ; then die "Tache interrompue." 1 ; fi
    lister_tests
    select=$(whiptail --title "Tests trouvés" --radiolist --separate-output "\nChoisissez le test à modifier :" 25 78 16 "${tests[@]}" 3>&1 1>&2 2>&3)
    if [ $? = 1 ] || [[ $select == "" ]] ; then die "Tache interrompue." 1 ; fi
    pathSelect="$DIR/tests/$select.cfg"
    x=0
    for i in $(grep -E -v ">$" $pathSelect | cut -d" " -f1) ; do
       param[x]=$i ;  (( x++ ))
    done

    i=0
    for par in "${param[@]}" ; do
      val=$(grep -E "^$par" $pathSelect | cut -d" " -f2)
      params[i]=$par ; (( i++ ))
      params[i]="= $val" ; (( i++ ))
      params[i]="OFF" ; (( i++ ))
    done
    ps=$(whiptail --title "Liste de paramètres" --checklist --separate-output "\nChoisissez les paramètres à modifier :" 25 78 16 "${params[@]}" 3>&1 1>&2 2>&3)
    if [ $? = 1 ] || [[ $ps == "" ]] ; then die "Tache interrompue." 1 ; fi
    psAr=(${ps//" "/ })

    cd $DIR/tests/
    for i in "${psAr[@]}" ; do
      valAc=$(grep -E "^$i" $select.cfg | cut -d" " -f2)
      val=$(whiptail --inputbox "\nEntrez le nouveau valeur pour '$i' :" 8 78 $valAc --title "Modifier paramètre du test [$select]" 3>&1 1>&2 2>&3)
      if [ $? = 1 ] ; then die "Tache interrompue." 1 ; fi
      sed -i "/$i $valAc/ c \\$i $val" "$select.cfg"
    done
    cd $repAc
}

apercu () {
  echo  -e "Maintenant un apercu du nouveau fichier meshconfig. "
  read -n 1 -s -r -p "Appuyez sur une touche pour continuer : "
  less $DIR/meshconfig.conf
}

#Valider les arguments passés en paramètre

while [ "$1" != "" ]; do
    PARAM=$(echo $1 | awk -F= '{print $1}')
    VALUE=$(echo $1 | awk -F= '{print $2}')

    case $PARAM in
        -h | --help)
            aide
            exit
            ;;
        --action)
            ACTION=$VALUE
            ;;
        --dir)
            DIR=$(echo "$VALUE" | sed -e 's/\/$//')
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
   die "Manque de fichiers nécessaires pour le script. Veulliez vérifier qu'ils sont dans le répertoire correspondant." 5
fi

if [ $ACTION == "list" ] ; then
    tache_list
elif [ $ACTION == "add" ] ; then
    echo "TACHE AJOUTER UN SONDE"
    if ! information ; then
       die "L'installation a été interrompue." 1
    fi

    if ! creation_data_yaml ; then
       die "Erreur produite peut-être à cause d'un probleme de droits sur le répertoire courant." 1
    fi
    tache_add
    #if ! creation_json ; then
       #if ! recuperation ; then
       #   die "Une erreur s'est produite pendant la récuperation de la configuration précedente. Vous avez le fichier $DIR.bak comme backup. Là dedans, vous avez toute votre configuration MESH precédente à la MàJ esssayée." 1
       #fi
    #   die "Erreur dans la création de la nouvelle configuration pour le fichier JSON." 1
    #fi
    apercu
    # if ! redemarrer_serv_perfsonar ; then
    #    die "Un erreur s'est produite pendant le rédemarrage des services perfSONAR." 1
    #    recuperer_logs
    # else
    #    recuperer_logs
    # fi
elif [ $ACTION == "delete" ] ; then
    echo "TACHE SUPRIMER UN SONDE"
    if ! tache_sup_sonde ; then die "Vous devez choisir la sonde à supprimer" 1 ; fi
    apercu
    #if ! creation_json ; then
       #if ! recuperation ; then
       #   die "Une erreur s'est produite pendant la récuperation de la configuration précedente. Vous avez le fichier $DIR.bak comme backup. Là dedans, vous avez toute votre configuration MESH precédente à la MàJ esssayée." 1
       #fi
    #   die "Erreur dans la création de la nouvelle configuration pour le fichier JSON." 1
    #fi
    # if ! redemarrer_serv_perfsonar ; then
    #    die "Un erreur s'est produite pendant le rédemarrage des services perfSONAR." 1
    #    recuperer_logs
    # else
    #    recuperer_logs
    # fi

elif [ $ACTION == "conftest" ] ; then
  if (whiptail --title "Manage tests" --yesno --no-button "Avancée" --yes-button "Suivant" "Normalement, cette partie est déjà configurée. Appuyez sur SUIVANT si vous voulez activer ou desactiver des tests ou sur AVANCÉE pour modifier les paramètres des tests." 10 78) then
    active_tests
    #  ./creation_meshconfig.py "${DIR}" "1" Juste le parametre pour savoir s'il sagit de la tache conftes
    ./creation_meshconfig.py "${DIR}" "${tests_mesh}" "${tests_disj}" "1"
    apercu
  else
    echo "Paramètres avancés"
    tache_avancee
    # ./creation_meshconfig.py "${DIR}" Juste le parametre DIR tache conf avancee =~ add/delete
    ./creation_meshconfig.py "${DIR}" "${tests_mesh}" "${tests_disj}"
  fi
  # if ! creation_json ; then
  #    #if ! recuperation ; then
  #    #   die "Une erreur s'est produite pendant la récuperation de la configuration précedente. Vous avez le fichier $DIR.bak comme backup. Là dedans, vous avez toute votre configuration MESH precédente à la MàJ esssayée." 1
  #    #fi
  #    die "Erreur dans la création de la nouvelle configuration pour le fichier JSON." 1
  # fi
  # if ! redemarrer_serv_perfsonar ; then
  #    die "Un erreur s'est produite pendant le rédemarrage des services perfSONAR." 1
  #    recuperer_logs
  # else
  #    recuperer_logs
  # fi
else
    aide
fi

exit 0
