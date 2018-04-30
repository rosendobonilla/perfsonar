#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys

rep = sys.argv[1]
idSonde = sys.argv[2]
grp = sys.argv[3]
grpPath = "/"

if len(sys.argv) == 5:
    membre = sys.argv[4]
    print membre
    grpPath = "/" + membre + "/"

nomFich = rep + "/sites/" + idSonde + ".cfg"
dest = rep + "/groupes/" + grp + grpPath + idSonde
cmd = "ln -s " + nomFich + " " + dest

config_data = yaml.load(open('./data.yaml'))

env = Environment(loader = FileSystemLoader('./'), trim_blocks=True, lstrip_blocks=True)
template = env.get_template('template.jinja2')

config = template.render(config_data)

file = open(nomFich,"wr") 
file.write(config)

os.system(cmd)
