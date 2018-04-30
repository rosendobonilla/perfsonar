#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys
import glob

reper = sys.argv[1]
nomFich = reper + "/meshconfig.conf"



##print "\n+-----------------------------------------------------------------+\nExecution du script de mise à jour ..."
print "\nCréation de la configuration de la nouvelle sonde : \n"

entete = """description PerfSONAR Observatoire Mesh Config

<organization>
    description     Observatoire Astronomique de Strasbourg

"""

file = open(nomFich,"wb") 

file.write(entete)

sites = glob.glob(reper + '/sites/*.cfg')
types = [os.path.basename(x) for x in glob.glob(reper + "/groupes/disjoint/*")]

for fich in sites:
    for line in open(fich).readlines():
        file.write(line)


file.write("</organization>\n\n")        

file.write("<group obas_interne_mesh>\n")
file.write("   type mesh\n\n")
for mem in glob.glob(reper + "/groupes/mesh/*"):
    dirname, filename = os.path.split(mem) 
    file.write("   member " + filename)
file.write("\n</group>")

file.write("\n\n<group obas_exterieur_disjoint>\n")
file.write("   type disjoint\n\n")

for tipo in types:
    for mem in glob.glob(reper + "/groupes/disjoint/" + tipo + "/*"):
        dirname, filename = os.path.split(mem) 
        file.write("   " + tipo + " " + filename + "\n")

file.write("\n</group>\n\n")

for line in open("../conf/body.cfg").readlines():
    file.write(line)

print "\n+-----------------------------------------------------------------+\nConfiguration complète"

file.close


