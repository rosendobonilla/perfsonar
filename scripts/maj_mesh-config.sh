#!/bin/bash

#Script pour mettre à jour le fichier JSON
#Fichier avec de tests par défaut

echo -e "\nExecution du script de mise à jour ..."
sleep 2

#sed -e "/#add_site/ a \\$(echo "$site")" mesh-central-v2.conf

oldIFS=$IFS

for line in $(cat template.conf) ; do
  echo $line
done

IFS=$oldIFS
