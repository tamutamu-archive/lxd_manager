#!/bin/bash -eu

. var.conf

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


CT_NAME=${1}

lexec(){
  sudo lxc exec ${CT_NAME} -- /bin/bash -lc "${1}"
}



### Setup http proxy.
set +e
proxy_tmp=$(mktemp)
env | grep -ie 'http_proxy' -ie 'https_proxy' -ie 'no_proxy' | sed -e 's/^/export /' > ${proxy_tmp}
sudo lxc file push ${proxy_tmp} ${CT_NAME}/etc/profile.d/proxy.sh

lexec "chown root:root /etc/profile.d/proxy.sh"
lexec "chmod o+rx /etc/profile.d/proxy.sh"

rm -f ${proxy_tmp}

lexec "echo '. /etc/profile.d/proxy.sh' >> /etc/bash.bashrc"
lexec ". /etc/bash.bashrc && env | grep -ie http_proxy= -ie https_proxy= >> /etc/environment"
set -e


### yum update, system restart.
lexec \
  "sed -i.bk -e 's/^mirrorlist=/#mirrorlist=/g' \
             -e 's/#baseurl=/baseurl=/g' /etc/yum.repos.d/CentOS-Base.repo"

lexec "yum clean all && yum -y update"
sudo lxc restart ${CT_NAME}

# TODO wait network ready..
sleep 15


### Config lang and timezone.
lexec \
  "mkdir -p /etc/systemd/system/systemd-localed.service.d/ \
   && cat << EOT >> /etc/systemd/system/systemd-localed.service.d/override.conf
[Service]
PrivateNetwork=no
EOT"

lexec \
  "mkdir -p /etc/systemd/system/systemd-hostnamed.service.d/ \
   && cat << EOT >> /etc/systemd/system/systemd-hostnamed.service.d/override.conf
[Service]
PrivateNetwork=no
EOT"

lexec \
  "systemctl restart systemd-hostnamed && systemctl restart systemd-localed"

lexec "localectl set-locale LANG=ja_JP.UTF-8"
lexec "timedatectl set-timezone Asia/Tokyo"

### Install sshd and setting, autostart.
lexec \
    'yum -y install openssh-server && systemctl enable sshd && systemctl start sshd'
lexec \
    'sed -i -e "s/^#\(UseDNS\).*/\1 no/" -e "s/^\(GSSAPIAuthentication\).*/\1 no/" /etc/ssh/sshd_config && \
       systemctl restart sshd && systemctl enable sshd'


### Setup maintain user.
lexec 'yum -y install sudo'
lexec "useradd ${MAINTAIN_USER}"
lexec "echo \"${MAINTAIN_USER} ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/${MAINTAIN_USER}"
lexec "sudo -iu ${MAINTAIN_USER} bash -c 'mkdir -p ~/.ssh/ && chmod 700 ~/.ssh/'"

### Setup ssh key.
poron gen_sshkey --ssh_user ${MAINTAIN_USER}


### Install base development.
lexec \
  'yum -y groupinstall "Development Tools" && \
   yum -y install wget zip unzip vim'

popd

