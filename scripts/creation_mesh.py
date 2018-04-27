#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys
import glob

reper = sys.argv[1]
nomFich = reper + "/meshconfig.conf"
print nomFich

##print "\n+-----------------------------------------------------------------+\nExecution du script de mise à jour ..."
print "\nCréation de la configuration de la nouvelle sonde : \n"

entete = """description PerfSONAR Observatoire Mesh Config

<organization>
    description     Observatoire Astronomique de Strasbourg

"""

file = open(nomFich,"wb") 

file.write(entete)

liste = glob.glob(reper + '/sites/*.cfg')

for fich in liste:
    for line in open(fich).readlines():
        file.write(line)

file.write("</organization>\n\n")        

for line in open("../conf/body.cfg").readlines():
    print line
    file.write(line)

print "\n+-----------------------------------------------------------------+\nConfiguration complète"

file.close


