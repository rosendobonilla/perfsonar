#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

fich = "./origen.txt"
dest = "./dest/dest.txt"

cmd = "ln -s "+fich+ " " + dest
os.system(cmd)
