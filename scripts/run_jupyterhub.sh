#!/bin/bash
cd /usr/local/srv
export PATH=/usr/local/texlive/2016/bin/x86_64-linux:$PATH:/usr/local/bin:/opt/nodejs-6.5.0/bin

if [ ! -e /mnt/jupyterusers/ramseyst ]
then
    echo "need to run:  mount /dev/sdf /mnt/jupyterusers"
    exit
fi

if [ -e /usr/local/var/log/jupyterhub.log ]
then
    sudo cp /usr/local/var/log/jupyterhub.log /usr/local/var/log/jupyterhub-`date +"%Y-%m-%d"`
fi

exec /usr/local/bin/jupyterhub -f /usr/local/etc/jupyterhub_config.py >/usr/local/var/log/jupyterhub.log 2>&1



