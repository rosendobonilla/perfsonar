print "Execution du script de mise à jour ..."

fichier=open("template.conf","r")

for line in fichier.readlines():
    print line

fichier.close()
