#!/usr/bin/bash

# este script se utiliza, si el resto de la Pipeline ha funcionado correctamente, para desplegar el contenido actual del repositorio a una rama de producción donde solamente aparecen los commits que superan las pruebas automáticas

# preparaciones para SSH
if [[ ! -d ~/.ssh ]]; then 
    mkdir ~/.ssh
fi

if [ `ls /contenido-ssh | wc -l` -gt 0  ]; then
    cp /contenido-ssh/* ~/.ssh
fi

chmod -R 644 ~/.ssh/ && chmod 400 ~/.ssh/clave-github

# iniciamos ssh-agent
eval `ssh-agent`

# añadimos la clave privada a ssh-agent, la clave no debe tener passphrase, de lo contrario no será automatizable
ssh-add ~/.ssh/clave-github

# congifuramos el nombre de usuario y cuenta de correo locales
git config --global user.name "tfg2asircanaveral2024"
git config --global user.email "tfg.2asir.canaveral.2024@gmail.com"

# vamos a utilizar un remoto de Git llamado 'original' para publicar el commit a la rama Produccion. Primero comprobamos si ese remoto ya ha sido creado
IFS='
'
REMOTO_EXISTE=0
for REMOTO in `git remote`; do
    if [[ $REMOTO = 'original' ]]; then
        # si en este repositorio ya se ha creado un remoto con el nombre 'original', es que la Pipeline se ha ejecutado más de una vez, y no es necesario volver a crearlo
        REMOTO_EXISTE=1
        break
    fi
done

# si el valor de $REMOTO_EXISTE sigue siendo 0, el remoto 'original' no existía, así que lo creamos
if [[ $REMOTO_EXISTE -eq 0 ]]; then
    # debes cambiar esta URL por el nombre del repositorio
    git remote add original git@github.com:tfg2asircanaveral2024/8-proyecto-powershell.git
fi

# hacemos que la rama produccion apunte al commit actual y cambiamos a ella
git branch -f produccion HEAD
git checkout produccion

# subir los cambios realizados
git push original produccion
