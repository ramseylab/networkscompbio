#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

CLASSNAME=csx46
INSTRUCTOR_ONID=ramseyst

sudo apt-get update
sudo apt-get install -y emacs
sudo apt-get install -y python3-pip
sudo curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y npm nodejs
sudo npm install -g configurable-http-proxy
sudo -H pip3 install virtualenv
sudo adduser -c "jupyterhub administrator" jupyterhub
virtualenv ${CLASSNAME}
${CLASSNAME}/bin/pip3 install jupyterhub
${CLASSNAME}/bin/pip3 install notebook
${CLASSNAME}/bin/pip3 install bash_kernel
git clone https://github.com/letsencrypt/letsencrypt
echo "About to run letsencrypt; select (1) to spin up a temporary webserver; enter the hostname when prompted for the 
domain name"
./letsencrypt/letsencrypt-auto certonly --debug
sudo apt-get install -y mlocate
sudo updatedb
${CLASSNAME}/bin/jupyterhub --generate-config
cp jupyterhub_config.py jupyterhub_config.py.ORIG
sed -i "s|#c.JupyterHub.ssl_key = ''|c.JupyterHub.ssl_key = '/etc/letsencrypt/live/${CLASSNAME}.saramsey.org/privkey.pem'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.ssl_cert = ''|c.JupyterHub.ssl_cert = '/etc/letsencrypt/live/${CLASSNAME}.saramsey.org/fullchain.pem'|g" jupyterhub_config.py
sudo mkdir -p /etc/jupyterhub
sed -i "s|#c.JupyterHub.cookie_secret_file = 'jupyterhub_cookie_secret'|c.JupyterHub.cookie_secret_file = '/srv/jupyterhub/jupyterhub_cookie_secret'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.admin_users = set()|c.JupyterHub.admin_users = {'${INSTRUCTOR_ONID}'}|g" jupyterhub_config.py
sed -i "s|#c.Authenticator.admin_users = set()|c.Authenticator.admin_users = {'${INSTRUCTOR_ONID}'}|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.bind_url = 'http://:8000'|c.JupyterHub.bind_url = 'http://0.0.0.0:443'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.hub_bind_url = ''|c.JupyterHub.hub_bind_url = 'http://127.0.0.0:8081'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.cleanup_servers = True|c.JupyterHub.cleanup_servers = False|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.pid_file = ''|c.JupyterHub.pid_file = '/srv/jupyterhub/jupyterhub.pid'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.db_url = 'sqlite:///jupyterhub.sqlite'|c.JupyterHub.db_url = 'sqlite:///srv/jupyterhub/jupyterhub.sqlite'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.spawner_class = 'jupyterhub.spawner.LocalProcessSpawner'|c.JupyterHub.spawner_class = 'sudospawner.SudoSpawner'|g" jupyterhub_config.py
echo "c.ConfigurableHTTPProxy.pid_file = '/srv/jupyterhub/jupyterhub-proxy.pid'" >> jupyterhub_config.py
echo "SudoSpawner.sudospawner_path = '/home/ubuntu/${CLASSNAME}/bin/sudospawner'" >> jupyterhub_config.py
echo "c.PAMAuthenticator.open_sessions = False" >> jupyterhub_config.py
sudo cp jupyterhub_config.py /etc/jupyterhub
sudo chmod 755 /etc/letsencrypt/live
sudo chmod 755 /etc/letsencrypt/archive
sudo chmod 644 /etc/letsencrypt/archive/${CLASSNAME}.saramsey.org/privkey1.pem
sudo adduser -c "Stephen Ramsey" ${INSTRUCTOR_ONID}
sudo mkdir -p /srv/jupyterhub
sudo chown jupyterhub.jupyterhub /srv/jupyterhub
sudo mkdir -p /var/log
sudo apt-get install -y lynx
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/node
sudo touch /var/log/jupyterhub.log
sudo chown jupyterhub.jupyterhub /var/log/jupyterhub.log
cat <<EOT >>run-jupyterhub.sh
#!/usr/bin/env bash
nohup sudo su - jupyterhub -c "exec /home/ubuntu/${CLASSNAME}/bin/jupyterhub -f /etc/jupyterhub/jupyterhub_config.py >/var/log/jupyterhub.log 2>&1"
EOT
chmod a+x run-jupyterhub.sh
${CLASSNAME}/bin/pip3 install sudospawner
sudo groupadd jupyterhubusers
sudo usermod -a -G jupyterhubusers ramseyst
sudo usermod -a -G shadow jupyterhub
sudo cat <<EOT >> /etc/sudoers.d/jupyterhub
Cmnd_Alias JUPYTER_CMD = /home/ubuntu/csx46/bin/sudospawner
jupyterhub ALL=(%jupyterhubusers) NOPASSWD:JUPYTER_CMD
EOT
