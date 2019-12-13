#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

CLASSNAME=csx46
INSTRUCTOR_ONID=ramseyst

sudo apt-get update

echo "installing basic packages needed for system administration"
sudo apt-get install -y emacs
sudo apt-get install -y lynx
sudo apt-get install -y mlocate
sudo updatedb

echo "installing python3"
sudo apt-get install -y python3-pip

echo "installing node.js"
sudo curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y npm nodejs

echo "installing configurable-http-proxy"
sudo npm install -g configurable-http-proxy

echo "setting up virtualenv"
sudo -H pip3 install virtualenv
virtualenv ${CLASSNAME}
${CLASSNAME}/bin/pip3 install jupyterhub
${CLASSNAME}/bin/pip3 install notebook
${CLASSNAME}/bin/pip3 install bash_kernel
export JUPYTER_DATA_DIR=/home/ubuntu/${CLASSNAME}/share/jupyter
${CLASSNAME}/bin/python3 -m bash_kernel.install
git clone https://github.com/letsencrypt/letsencrypt
echo "About to run letsencrypt; select (1) to spin up a temporary webserver; enter the hostname when prompted for the 
domain name"
./letsencrypt/letsencrypt-auto certonly --debug

echo "creating JupyterHub config file"
${CLASSNAME}/bin/jupyterhub --generate-config
cp jupyterhub_config.py jupyterhub_config.py.ORIG
sed -i "s|#c.JupyterHub.ssl_key = ''|c.JupyterHub.ssl_key = '/etc/letsencrypt/live/${CLASSNAME}.saramsey.org/privkey.pem'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.ssl_cert = ''|c.JupyterHub.ssl_cert = '/etc/letsencrypt/live/${CLASSNAME}.saramsey.org/fullchain.pem'|g" jupyterhub_config.py
sudo mkdir -p /etc/jupyterhub
sed -i "s|#c.JupyterHub.cookie_secret_file = 'jupyterhub_cookie_secret'|c.JupyterHub.cookie_secret_file = '/srv/jupyterhub/jupyterhub_cookie_secret'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.admin_users = set()|c.JupyterHub.admin_users = {'${INSTRUCTOR_ONID}'}|g" jupyterhub_config.py
sed -i "s|#c.Authenticator.admin_users = set()|c.Authenticator.admin_users = {'${INSTRUCTOR_ONID}'}|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.bind_url = 'http://:8000'|c.JupyterHub.bind_url = 'http://0.0.0.0:8000'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.hub_bind_url = ''|c.JupyterHub.hub_bind_url = 'http://127.0.0.1:8081'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.cleanup_servers = True|c.JupyterHub.cleanup_servers = False|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.pid_file = ''|c.JupyterHub.pid_file = '/srv/jupyterhub/jupyterhub.pid'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.db_url = 'sqlite:////jupyterhub.sqlite'|c.JupyterHub.db_url = 'sqlite:///srv/jupyterhub/jupyterhub.sqlite'|g" jupyterhub_config.py
sed -i "s|#c.JupyterHub.spawner_class = 'jupyterhub.spawner.LocalProcessSpawner'|c.JupyterHub.spawner_class = 'sudospawner.SudoSpawner'|g" jupyterhub_config.py
echo "c.ConfigurableHTTPProxy.pid_file = '/srv/jupyterhub/jupyterhub-proxy.pid'" >> jupyterhub_config.py
echo "c.PAMAuthenticator.open_sessions = False" >> jupyterhub_config.py
echo "c.Spawner.cmd = '/home/ubuntu/${CLASSNAME}/bin/sudospawner'" >> jupyterhub_config.py
sudo cp jupyterhub_config.py /etc/jupyterhub

echo "setting up SSL certificates"
sudo chmod 755 /etc/letsencrypt/live
sudo chmod 755 /etc/letsencrypt/archive
sudo chmod 644 /etc/letsencrypt/archive/${CLASSNAME}.saramsey.org/privkey1.pem

echo "creating Linux accounts that are needed"
sudo adduser -c "jupyterhub daemon" jupyterhub
sudo adduser -c "JupyterHub Main Administrator" ${INSTRUCTOR_ONID}

echo "creating directories needed by JupyterHub"
sudo mkdir -p /srv/jupyterhub
sudo chown jupyterhub.jupyterhub /srv/jupyterhub
sudo mkdir -p /var/log
sudo touch /var/log/jupyterhub.log
sudo chown jupyterhub.jupyterhub /var/log/jupyterhub.log
cat <<EOT >>run-jupyterhub.sh
#!/usr/bin/env bash
nohup sudo su - jupyterhub -c "exec /home/ubuntu/${CLASSNAME}/bin/jupyterhub -f /etc/jupyterhub/jupyterhub_config.py >/var/log/jupyterhub.log 2>&1" > /tmp/nohup.out 2>&1
EOT
chmod a+x run-jupyterhub.sh
${CLASSNAME}/bin/pip3 install sudospawner
sudo groupadd jupyterhubusers
sudo usermod -a -G jupyterhubusers ramseyst
sudo usermod -a -G shadow jupyterhub
cat <<EOT >>sudoers-jupyterhub
Cmnd_Alias JUPYTER_CMD = /home/ubuntu/csx46/bin/sudospawner
jupyterhub ALL=(%jupyterhubusers) NOPASSWD:JUPYTER_CMD
EOT
sudo mv sudoers-jupyterhub /etc/sudoers.d/jupyterhub
sudo chown root.root /etc/sudoers.d/jupyterhub
sudo chmod 444 /etc/sudoers.d/jupyterhub

echo "installing and configuring nginx"
sudo apt-get install -y nginx
cp /etc/nginx/nginx.conf nginx.conf
cat <<EOF >> nginx.conf
stream {
  server {
      listen     443;
      proxy_pass 0.0.0.0:8000;
  }
}
EOF
sudo mv nginx.conf /etc/nginx/nginx.conf
rm nginx-conf-suffix
sudo service nginx stop

echo "installing R"
sudo apt install apt-transport-https software-properties-common
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -sc)/"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y r-base
Rscript -e 'install.packages("IRkernel")'
source /home/ubuntu/csx46/bin/activate
Rscript -e 'IRkernel::installspec(prefix="/home/ubuntu/csx46")'
deactivate
