#!/bin/bash

choice=$(whiptail --title "Manage groups" --menu "Choisissez le groupe pour la nouvelle sonde" 16 78 5 \
        "Interne" "Groupe sondes internes ObAS"\
        "Exterieur" "Groupe sondes à l'exterieur" 3>&2 2>&1 1>&3) 
         
option=$(echo $choice | tr '[:upper:]' '[:lower:]' | sed 's/ //g')

if [ $option == "interne" ]
   #modifier mesh-conf groupe interne
elif [ $option == "exterieur" ]
   #modifier mesh-conf groupe exterieur
fi
   
