#!/bin/bash

groupe=$(whiptail --title "Manage groups" --menu "Choisissez le groupe pour la nouvelle sonde" 16 78 5 \
        "Interne" "Groupe sondes internes ObAS"\
        "Exterieur" "Groupe sondes publiques" 3>&2 2>&1 1>&3) 
         
opt=$(echo $groupe | tr '[:upper:]' '[:lower:]')


if [[ $opt == "interne" ]] ; then
   TYPE="mesh"
elif [[ $opt == "exterieur" ]] ; then
   TYPE="disjoint"
fi


if [[ $TYPE == "disjoint" ]] ; then
   tipo=$(whiptail --title "Manage groups" --menu "Choisissez le type de membre. Par défaut TYPE B" 16 78 5 \
        "Membre A" "Membre sur l'observatoire"\
        "Membre B" "Membre à l'exterieur" 3>&2 2>&1 1>&3) 
fi

opt2=$(echo $tipo | tr '[:upper:]' '[:lower:]')

echo "Vous avez choisi $opt et $opt2"
