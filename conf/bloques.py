#!/usr/bin/env python
# -*- coding: utf-8 -*-

def trouver_bloque(fich,bloque,name):
    rep = open(fich,"r")
    lines = rep.readlines()
    resul = ""
    
    for lin in rep:
        if lin.startswith("<" + bloque + " " + name):
            result = result + lin
            if 
        
    
