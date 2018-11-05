#!/bin/bash -eu


lexec(){
  sudo lxc exec ${CT_NAME} -- /bin/bash -lc "${1}"
}


CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


CT_NAME=${1}
MAINTAIN_USER=maintain


### Setup http proxy.
proxy_tmp=$(mktemp)
env | grep -ie 'http_proxy' -ie 'https_proxy' -ie 'no_proxy' | sed -e 's/^/export /' > ${proxy_tmp}
sudo lxc file push ${proxy_tmp} ${CT_NAME}/etc/profile.d/proxy.sh

lexec "chown root:root /etc/profile.d/proxy.sh"
lexec "chmod o+rx /etc/profile.d/proxy.sh"

rm -f ${proxy_tmp}

lexec "echo '. /etc/profile.d/proxy.sh' >> /etc/bash.bashrc"
lexec ". /etc/bash.bashrc && env | grep -ie http_proxy= -ie https_proxy= >> /etc/environment"

### yum update, system restart.
lexec "systemctl stop open-iscsi iscsid"
lexec "systemctl mask open-iscsi iscsid"
lexec "apt -y purge cloud-init"

lexec "sed -i.bak -e 's%http://archive.ubuntu.com/ubuntu%http://ftp.iij.ad.jp/pub/linux/ubuntu/archive%g' /etc/apt/sources.list"
lexec "apt clean && apt update"
lexec "apt full-upgrade -y "

sudo lxc restart ${CT_NAME}

# TODO wait network ready..
sleep 9


### Config lang and timezone.
lexec "mkdir -p /etc/systemd/system/systemd-localed.service.d/ && \
       cat << EOT >> /etc/systemd/system/systemd-localed.service.d/override.conf
[Service]
PrivateNetwork=no
EOT"

lexec "mkdir -p /etc/systemd/system/systemd-hostnamed.service.d/ && \
       cat << EOT >> /etc/systemd/system/systemd-hostnamed.service.d/override.conf
[Service]
PrivateNetwork=no
EOT"

lexec "systemctl restart systemd-hostnamed && systemctl restart systemd-localed"

lexec "apt install -y language-pack-ja avahi-daemon"
lexec "localectl set-locale LANG=ja_JP.UTF-8"
lexec "timedatectl set-timezone Asia/Tokyo"

### Install sshd and setting, autostart.
lexec 'sed -ie "s/^#\(UseDNS\).*/\1 no/" /etc/ssh/sshd_config && \
       systemctl restart sshd'


### Setup maintain user.
lexec "useradd -m ${MAINTAIN_USER} -s /bin/bash"
lexec "echo \"${MAINTAIN_USER} ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/${MAINTAIN_USER}"
lexec "sudo -iu ${MAINTAIN_USER} bash -c 'mkdir -p ~/.ssh/ && chmod 700 ~/.ssh/'"

lexec "sudo -iu ${MAINTAIN_USER} bash -c 'ssh-keygen -f ~/.ssh/private_key -t rsa -b 4096 -C \"${MAINTAIN_USER} key pair\" -q -N \"\" '"

sudo lxc file pull ${CT_NAME}/home/${MAINTAIN_USER}/.ssh/private_key ${CURDIR}/.conf/
sudo chmod o+r ${CURDIR}/.conf/private_key
lexec "rm -f /home/${MAINTAIN_USER}/.ssh/private_key"

lexec "sudo -iu ${MAINTAIN_USER} bash -c 'mv ~/.ssh/{private_key.pub,authorized_keys} && chmod 600 ~/.ssh/authorized_keys'"

lexec "apt -y install build-essential wget zip unzip vim"

popd

