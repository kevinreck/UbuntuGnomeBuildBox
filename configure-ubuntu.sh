#!/bin/bash

# print commands and arguments as they are executed
set -x

echo "starting ubuntu devbox install on pid $$"
date
ps axjf

#############
# Parameters
#############

AZUREUSER=$1
HOMEDIR="/home/$AZUREUSER"
VMNAME=`hostname`
echo "User: $AZUREUSER"
echo "User home dir: $HOMEDIR"
echo "vmname: $VMNAME"

###################
# Common Functions
###################

ensureAzureNetwork()
{
  # ensure the host name is resolvable
  hostResolveHealthy=1
  for i in {1..120}; do
    host $VMNAME
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      hostResolveHealthy=0
      echo "the host name resolves"
      break
    fi
    sleep 1
  done
  if [ $hostResolveHealthy -ne 0 ]
  then
    echo "host name does not resolve, aborting install"
    exit 1
  fi

  # ensure the network works
  networkHealthy=1
  for i in {1..12}; do
    wget -O/dev/null http://bing.com
    if [ $? -eq 0 ]
    then
      # hostname has been found continue
      networkHealthy=0
      echo "the network is healthy"
      break
    fi
    sleep 10
  done
  if [ $networkHealthy -ne 0 ]
  then
    echo "the network is not healthy, aborting install"
    ifconfig
    ip a
    exit 2
  fi
}
ensureAzureNetwork

###################################################
# Update Ubuntu and install all necessary binaries
###################################################

time sudo apt-get -y update
# kill the waagent and uninstall, otherwise, adding the desktop will do this and kill this script
sudo pkill waagent
time sudo apt-get -y remove walinuxagent
time sudo apt-get -y install curl software-properties-common apt-transport-https wget

#########################################
# Setup Custom Repositories (GCloud, Docker, VSCode)
#########################################
# Add the Cloud SDK distribution URI as a package source & Import the Google Cloud Platform public key
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Add VS Code
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"

# Add Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


#########################################
# END Setup Custom Repositories
#########################################

time sudo apt update

time sudo DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install ubuntu-desktop firefox vnc4server ntp nodejs expect gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal gnome-core gcc g++ make git vim-gnome ca-certificates curl gnupg-agent code docker-ce docker-ce-cli containerd.io docker-compose google-cloud-sdk kubectl python-pip virtualenv libmysqlclient-dev mysql-client mongodb-clients

#########################################
# Setup Azure User Account including VNC
#########################################
sudo -i -u $AZUREUSER mkdir $HOMEDIR/bin
sudo -i -u $AZUREUSER touch $HOMEDIR/bin/startvnc
sudo -i -u $AZUREUSER chmod 755 $HOMEDIR/bin/startvnc
sudo -i -u $AZUREUSER touch $HOMEDIR/bin/stopvnc
sudo -i -u $AZUREUSER chmod 755 $HOMEDIR/bin/stopvnc
echo "vncserver -geometry 1920x1080 -depth 16" | sudo tee $HOMEDIR/bin/startvnc
echo "vncserver -kill :1" | sudo tee $HOMEDIR/bin/stopvnc
echo "export PATH=\$PATH:~/bin" | sudo tee -a $HOMEDIR/.bashrc

prog=/usr/bin/vncpasswd
mypass="password"

sudo -i -u $AZUREUSER /usr/bin/expect <<EOF
spawn "$prog"
expect "Password:"
send "$mypass\r"
expect "Verify:"
send "$mypass\r"
expect eof
exit
EOF

sudo -i -u $AZUREUSER startvnc
sudo -i -u $AZUREUSER stopvnc

echo "#!/bin/sh" | sudo tee $HOMEDIR/.vnc/xstartup
echo "" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "export XKL_XMODMAP_DISABLE=1" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "unset SESSION_MANAGER" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "unset DBUS_SESSION_BUS_ADDRESS" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "xsetroot -solid grey" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "vncconfig -iconic &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "gnome-panel &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "gnome-settings-daemon &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "metacity &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "nautilus &" | sudo tee -a $HOMEDIR/.vnc/xstartup
echo "gnome-terminal &" | sudo tee -a $HOMEDIR/.vnc/xstartup

sudo -i -u $AZUREUSER $HOMEDIR/bin/startvnc

########################################
# setup the Azure CLI
########################################
time sudo npm install azure-cli -g
#time sudo update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100

########################################
# NVM Script
########################################
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | sudo -i -u $AZUREUSER bash

########################################
# Setup Chrome
########################################
cd /tmp
time wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
time sudo dpkg -i google-chrome-stable_current_amd64.deb
time sudo apt-get -y --force-yes install -f
time rm /tmp/google-chrome-stable_current_amd64.deb

########################################
# Add user to Docker Group
########################################
sudo usermod -aG docker $AZUREUSER

########################################
# First Run
########################################
sudo -i -u $AZUREUSER touch $HOMEDIR/bin/firstRun.sh
sudo -i -u $AZUREUSER chmod 755 $HOMEDIR/bin/firstRun.sh

echo "#!/bin/sh" | sudo tee $HOMEDIR/bin/firstRun.sh
echo "" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo ". ~/.nvm/nvm.sh" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo "nvm install 9.9.0" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo "mkdir repos" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo "pushd repos" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo "git clone git@github.com:Nautic-ON/deploy-gcp.git" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo "git clone git@github.com:Nautic-ON/cv-backend-documentation.git" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo "docker-compose -f cv-backend-documentation/scripts/local-docker-setup/docker-compose.yml pull" | sudo tee -a $HOMEDIR/bin/firstRun.sh

echo "popd" | sudo tee -a $HOMEDIR/bin/firstRun.sh

#echo "pip install virtualenv" | sudo tee -a $HOMEDIR/bin/firstRun.sh
echo "gcloud auth login" | sudo tee -a $HOMEDIR/bin/firstRun.sh



date
echo "completed ubuntu devbox install on pid $$ - you need to reconnect to get the new group"