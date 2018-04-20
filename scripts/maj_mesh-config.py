#!/usr/bin/env python
# -*- coding: utf-8 -*-
print "\n*******************************************************************\nExecution du script de mise à jour ..."
print "\nCréation de la configuration de la nouvelle sonde : \n"

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import commands

config_data = yaml.load(open('./data.yaml'))

env = Environment(loader = FileSystemLoader('./'), trim_blocks=True, lstrip_blocks=True)
template = env.get_template('template.jinja2')

print(template.render(config_data))

