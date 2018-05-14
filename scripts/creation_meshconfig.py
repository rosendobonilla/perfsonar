#!/usr/bin/env python
# -*- coding: utf-8 -*-

#-----------------------------------------------------------------------------------------------#
# Ce script permet de créer la configuration finale meshconfig.conf, avec tous les bloques      #
# nécessaires (organisations, sites, tests, groupes, etc). Il va parcourir toute l'arborescence #
# du MESH pour retrouver les données requises                                                   #
#-----------------------------------------------------------------------------------------------#

import os
from jinja2 import Environment, FileSystemLoader
import yaml
import sys
import glob

#Cette function va creer tous les tests en fonction des paramètres passés
#liste = array testsDisj ou testsMesh contenant les test passes pour le script bash
#groupe = le groupe relie au test
#title = INTERNE ou EXTERIEUR cest juste pour l'affichage
#modif = 1 ou 0, 1 si on a lance directement l'action 'conftest' et 0 si on vient des taches 'add' ou 'delete' sonde
def test (liste,courants,groupe,title,modif):
    for test in liste:
        file.write("<test>\n")
        if modif == 1:
            if test in courants:
                 descrip = courants[test]
            else:
                descrip = raw_input("GROUPE " + title + " : Entrez une description pour le nouveau test : " + test + " - ")
        else:
            descrip = courants[test]
        file.write("   description    " + descrip + "\n")
        file.write("   group    " + groupe + "\n")
        file.write("   test_spec    " + test + "\n")
        file.write("</test>\n\n")
        cmd = 'echo "' + groupe + ',' + test + ',' + descrip + '" >> ' + reperTests
        os.system(cmd)

testsMeshCourants = {}
testsDisjCourants = {}
testsMeshNew = []
testsDisjNew = []

def lister_tests_courants ():
    for line in open(reper + "/tests/actives/actives.cfg").readlines():         #On lit le fichier actives.cfg pour recuperer les tests selectionés dans deux listes
        lin = line.rstrip('\n').split(',')
        print lin[0]," ",lin[1]," ",lin[2]
        if lin[0] == "obas_interne_mesh":
            #testsMeshCourants[lin[1]] = lin[2]
            testsMeshCourants[lin[1]] = lin[2]
        else:
            testsDisjCourants[lin[1]] = lin[2]

#On récupère le chemin du répertoire MESH grace au script BASH
reper = sys.argv[1]
nomFich = reper + "/meshconfig.conf"

if len(sys.argv) == 5:
    TESTS1 = sys.argv[2]
    TESTS2 = sys.argv[3]
    testsMeshNew = TESTS1.split('\n')
    testsDisjNew = TESTS2.split('\n')
    modif = 1
else:
    modif = 0

lister_tests_courants()

#Variable contenant l'entete du fichier meshconfig
entete = """description PerfSONAR Observatoire Mesh Config

<organization>
    description     Observatoire Astronomique de Strasbourg

"""

file = open(nomFich,"wb")                                                       #On crée le nouveau fichier de configuration dans le chemin spécifié

#L'entete va etre toujours la meme, on le met donc en dur dans le fichier
file.write(entete)


sites = glob.glob(reper + '/sites/*.cfg')                                       #Le script parcours le répertoire /sites en cherchant des fichiers .cfg et met leurs noms dans un tableau                                                                    #Trier le tableau pour avoir en premier lieu les members 'a'

#On parcours le tableau
for fich in sites:
    for line in open(fich).readlines():                                         #On lit chaque fichier de conf et l'écrit dans le fichier meshconfig.conf
        file.write(line)

#On ferme le bloque
file.write("</organization>\n\n")

for line in open("../conf/body-orgs.cfg").readlines():                          #Là, on récupère la partie 'fixe' (les orgs)
    file.write(line)
file.write("\n")

tests = glob.glob(reper + '/tests/*.cfg')                                         #Le script parcours le répertoire /sites en cherchant des fichiers .cfg et met leurs noms dans un tableau                                                                    #Trier le tableau pour avoir en premier lieu les members 'a'

for fich in tests:
    for line in open(fich).readlines():                                         #On lit chaque fichier de conf et l'écrit dans le fichier meshconfig.conf
        file.write(line)
    file.write("\n")

#On commence la partie des groupes
file.write("<group obas_interne_mesh>\n")                                       #On utilise la meme methode pour obtenir les informations : dans ce cas, on parcours l'arborescence en cherchant les
file.write("   type mesh\n")                                                    #les membres du groupe mesh et les écrit dans le fichier
for mem in glob.glob(reper + "/groupes/mesh/*"):
    dirname, filename = os.path.split(mem)
    file.write("\n   member " + filename)
file.write("\n</group>")

file.write("\n\n<group obas_exterieur_disjoint>\n")
file.write("   type disjoint\n\n")

types = [os.path.basename(x) for x in glob.glob(reper + "/groupes/disjoint/*")] #Cas particulier pour le groupe 'disjoint' ; d'abord on obtient les types (a ou b)
types.sort()

for tipo in types:                                                              #On utilise la meme methode pour obtenir les informations : dans ce cas, on parcours l'arborescence en cherchant les
    for mem in glob.glob(reper + "/groupes/disjoint/" + tipo + "/*"):           #les membres du groupe disjoint et les écrit dans le fichier
        dirname, filename = os.path.split(mem)
        file.write("   " + tipo + " " + filename + "\n")
    file.write("\n")

file.write("</group>\n\n")

reperTests = reper + '/tests/actives/actives.cfg'
cmd = 'rm -f ' + reperTests
os.system(cmd)

if modif == 1:
    print "\nMaintenant, vous devez entrer les descriptions pour chacun des nouveaux tests. Ces descriptions sont celles affichées dans le tableau de bord, il faut donc donner des descriptions adaptées.\n"
    test(testsMeshNew,testsMeshCourants,"obas_interne_mesh","INTERNE",1)
    test(testsDisjNew,testsDisjCourants,"obas_exterieur_disj","EXTERIEUR",1)
else:
    testsMesh = testsMeshCourants.keys()
    testsDisj = testsDisjCourants.keys()
    test(testsMesh,"obas_interne_mesh","INTERNE",0)
    test(testsDisj,"obas_exterieur_disj","EXTERIEUR",0)

print "\nConfiguration complète !\n"

file.close
