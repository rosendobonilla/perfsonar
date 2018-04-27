#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys
import glob

rep = "./"
idSonde = "obas"

##print "\n+-----------------------------------------------------------------+\nExecution du script de mise à jour ..."
print "\nCréation de la configuration de la nouvelle sonde : \n"

entete = """description PerfSONAR Observatoire Mesh Config

<organization>
    description     Observatoire Astronomique de Strasbourg

</organization>

"""

nomFich = rep + idSonde

file = open(nomFich,"wb") 

file.write(entete)

listing = glob.glob('*.cfg')
for filename in listing:
    for line in open(filename).readlines():
        file.write(line)
        
for line in open("./body").readlines():
    print line
    file.write(line)
        

print "\n+-----------------------------------------------------------------+\nConfiguration complète"

file.close


