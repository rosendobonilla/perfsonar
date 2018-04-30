#!/usr/bin/env python
# -*- coding: utf-8 -*-

#----------------------------------------------------------------------------------------------#
# Ce script permet de créer la configuration finale meshconfig.conf, avec tous les bloques   #
# nécessaires (organisations, sites, tests, groupes, etc). Il va parcourir tout l'arborescence #
# du MESH pour retrouver les données requises                                                  #   
#----------------------------------------------------------------------------------------------#

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys
import glob

#On récupère le chemin du répertoire MESH grace au script BASH

reper = sys.argv[1]
nomFich = reper + "/meshconfig.conf"

##print "\n+-----------------------------------------------------------------+\nExecution du script de mise à jour ..."
print "\nCréation de la configuration de la nouvelle sonde : \n"

entete = """description PerfSONAR Observatoire Mesh Config

<organization>
    description     Observatoire Astronomique de Strasbourg

"""

file = open(nomFich,"wb")                                                            #On crée le nouveau fichier de configuration

#L'entete va etre toujours la meme, on le met donc en brute dans le fichier
file.write(entete)


sites = glob.glob(reper + '/sites/*.cfg')                                            #Le script parcours le répertoire /sites en cherchant de fichiers .cfg et met leurs noms dans un tableau
types = [os.path.basename(x) for x in glob.glob(reper + "/groupes/disjoint/*")]      #Cas particulier pour le groupe 'disjoint' ; d'abord on obtient les types (a ou b)
types.sort()                                                                         #Trier le tableau pour avoir en premier lieu les members 'a'

#On parcours le tableau
for fich in sites:
    for line in open(fich).readlines():                                              #On lit chaque fichier et écrit dans le fichier
        file.write(line)


file.write("</organization>\n\n")        

file.write("<group obas_interne_mesh>\n")
file.write("   type mesh\n")
for mem in glob.glob(reper + "/groupes/mesh/*"):
    dirname, filename = os.path.split(mem) 
    file.write("\n   member " + filename)
file.write("\n</group>")

file.write("\n\n<group obas_exterieur_disjoint>\n")
file.write("   type disjoint\n\n")

for tipo in types:
    for mem in glob.glob(reper + "/groupes/disjoint/" + tipo + "/*"):
        dirname, filename = os.path.split(mem) 
        file.write("   " + tipo + " " + filename + "\n")
    file.write("\n")

file.write("</group>\n\n")

for line in open("../conf/body.cfg").readlines():
    file.write(line)

print "\n+-----------------------------------------------------------------+\nConfiguration complète"

file.close


