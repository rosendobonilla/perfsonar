#!/usr/bin/env python
# -*- coding: utf-8 -*-

print "\n*******************************************************************\nExecution du script de mise à jour ..."
print "\nCréation de la configuration de la nouvelle sonde : \n"

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys

fich = sys.argv[1]

config_data = yaml.load(open('./data.yaml'))

env = Environment(loader = FileSystemLoader('./'), trim_blocks=True, lstrip_blocks=True)
template = env.get_template('template.jinja2')

print(template.render(config_data))

print "\n******************************************************************\nConfiguration complète"
print "\n******************************************************************\nModification du fichier mesh-central.json"

file = open("mesh_tmp.conf","wb") 

for line in open(fich).readlines():
    file.write(line)
    if line.startswith("#add_sonde"):
        for line2 in open("template.jinja2").readlines():
            file.write(line2)
        file.write("#add_sonde\n")

file.close

os.system('sed -i "0,/#add_sonde/ s/#add_sonde//" fich')


