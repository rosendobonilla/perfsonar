#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys

print "\n+-----------------------------------------------------------------+\nExecution du script de mise à jour ..."
print "\nCréation de la configuration de la nouvelle sonde : \n"

rep = sys.argv[1]
idSonde = sys.argv[2]

entete = """description PerfSONAR Observatoire Mesh Config

<organization>
    description     Observatoire Astronomique de Strasbourg

</organization>

"""

nomFich = rep + idSonde

config_data = yaml.load(open('./data.yaml'))

env = Environment(loader = FileSystemLoader('./'), trim_blocks=True, lstrip_blocks=True)
template = env.get_template('template.jinja2')

config = template.render(config_data)

print "\n+-----------------------------------------------------------------+\nConfiguration complète"
print "\n+-----------------------------------------------------------------+\nModification du fichier " + fich

file = open(idSonde,"wb") 

file.write()

file.close


