#!/bin/bash
set -euo pipefail

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}

. var.conf

### Install my lxd modules.
sudo mkdir -p ${LXD_HOME}

sudo cp -r ${CURDIR}/bin ${LXD_HOME}/
sudo cp -r ${CURDIR}/lib ${LXD_HOME}/
sudo cp -r ${CURDIR}/container ${LXD_HOME}/
sudo cp -r ${CURDIR}/.lxd_profile ${LXD_HOME}/

sudo chown lxd:lxd ${LXD_HOME} -R
sudo chmod 774 ${LXD_HOME} -R

sudo cp -r ${CURDIR}/conf ${LXD_SNAP_COMMON}/



# Init lxd.
cat ${LXD_SNAP_COMMON}/conf/init.yml | sudo lxd init --preseed


# Setting dnsmasq conf.
sudo lxc network set lxdbr0 raw.dnsmasq "addn-hosts=${LXD_SNAP_COMMON}/conf/lxd_hosts"


# Setting proxy.
set +u
if [ ! -z "${http_proxy}" ];then
  sudo lxc config set core.proxy_http ${http_proxy}
  sudo lxc config set core.proxy_https ${https_proxy}
  sudo lxc config set core.proxy_ignore_hosts localhost
fi
set -u


cat <<EOT | sudo tee -a /etc/security/limits.conf > /dev/null

*               soft    nofile          1048576
*               hard    nofile          1048576
root            soft    nofile          1048576
root            hard    nofile          1048576
*               soft    memlock         unlimited
*               hard    memlock         unlimited
EOT


cat <<EOT | sudo tee -a /etc/sysctl.conf > /dev/null

fs.inotify.max_queued_events = 1048576
fs.inotify.max_user_instances = 1048576
fs.inotify.max_user_watches = 1048576
vm.max_map_count = 262144
kernel.dmesg_restrict = 1
net.ipv4.ip_forward=1
EOT

set +e
sudo sysctl -p /etc/sysctl.conf
set -e


echo "Please restart system!!"

popd

pushd ${LXD_HOME}
git clone https://github.com/yyuu/pyenv.git ${LXD_HOME}/.pyenv
git clone https://github.com/pyenv/pyenv-virtualenv.git ${LXD_HOME}/.pyenv/plugins/pyenv-virtualenv

. .lxd_profile

sudo apt install zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libssl-dev sudo libmodglue1v5


sudo chown lxd:lxd ${LXD_HOME} -R
sudo chmod 774 ${LXD_HOME} -R

echo "lxd ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/poron


echo "export PATH=${LXD_HOME}/bin:${PATH}" | sudo tee /etc/profile.d/poron.sh
echo "export LXD_HOME=${LXD_HOME}" | sudo tee -a /etc/profile.d/poron.sh


sudo su - lxd --shell=/bin/bash -c bash -l << EOT
. /etc/profile.d/poron.sh

pushd ${LXD_HOME}
. .lxd_profile

pyenv install 3.6.4
pyenv virtualenv 3.6.4 lxd_python
pyenv global lxd_python

env
pip install ruamel.yaml

pushd

EOT



exec ${SHELL} -l
