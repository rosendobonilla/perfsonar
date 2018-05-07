#!/usr/bin/env python
# -*- coding: utf-8 -*-

#--------------------------------------------------------------------------------------------#
# Ce script permet de créer la configuration de chaque nouvelle sonde et la placer dans le   #
# repértoire correspondant. De plus, il crée un lien symbolique vers le répertoire groupes   #
# pour les 'lier'.                                              							 #
#--------------------------------------------------------------------------------------------#

import os
from jinja2 import Environment, FileSystemLoader    #Importer les modules nécessaires pour traiter le template
import yaml										    #Importer les modules nécessaires pour traiter le fichier YAML
import sys 										    #Importer les modules nécessaires pour pouvoir utiliser des commandes du système


#On recupére les variables envoyées par le script BASH	
rep = sys.argv[1]
idSonde = sys.argv[2]
grp = sys.argv[3]
grpPath = "/"

#Si on recoit cinq paramètres ca veut dire qu'il s'agit d'un groupe disjoint
if len(sys.argv) == 5:
    membre = sys.argv[4]
    grpPath = "/" + membre + "/"                    #On crée le chemin vers tous les fichiers du groupe disjoint


nomFich = rep + "/sites/" + idSonde + ".cfg"        #On construit le nom complet du fichier contenant la nouvelle configuration du site
dest = rep + "/groupes/" + grp + grpPath + idSonde  ## 
cmd = "ln -s " + nomFich + " " + dest               #On crée la commande pour le lien symbolique

#On obtient les données du fichier YAML
config_data = yaml.load(open('./data.yaml'))

#On utilise le template pour créer la configuration
env = Environment(loader = FileSystemLoader('./'), trim_blocks=True, lstrip_blocks=True)
template = env.get_template('template.jinja2')
config = template.render(config_data)

#On l'écrit dans le fichier
file = open(nomFich,"wr") 
file.write(config)

#On crée le lien simbolique
os.system(cmd)