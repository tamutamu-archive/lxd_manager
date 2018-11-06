#!/bin/bash -eu


. var.conf

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}


ct_name=${1}

### Setup http proxy.
if [ ! -z "${HTTP_PROXY_HOST}" ];then

  sudo lxc exec ${ct_name} -- bash -lc \
    "cat << 'EOT' >> /etc/profile.d/proxy.sh
export http_proxy=http://${HTTP_PROXY_HOST}:${HTTP_PROXY_PORT}
export HTTP_PROXY=\${http_proxy}
export https_proxy=\${http_proxy}
export HTTPS_PROXY=\${http_proxy}
export no_proxy=${HTTP_NO_PROXY}
export NO_PROXY=\${no_proxy}
EOT"

  sudo lxc exec ${ct_name} -- bash -lc \
      ". .bash_profile && env | grep -ie http_proxy= -ie https_proxy= -ie no_proxy= >> /etc/environment"
fi


### yum update, system restart.
sudo lxc exec ${ct_name} -- bash -lc \
  "sed -i.bk -e 's/^mirrorlist=/#mirrorlist=/g' \
             -e 's/#baseurl=/baseurl=/g' /etc/yum.repos.d/CentOS-Base.repo"

sudo lxc exec ${ct_name} -- bash -lc "yum clean all && yum -y update"
sudo lxc restart ${ct_name}

# TODO wait network ready..
sleep 15


### Config lang and timezone.
sudo lxc exec ${ct_name} -- bash -lc \
  "mkdir -p /etc/systemd/system/systemd-localed.service.d/ \
   && cat << EOT >> /etc/systemd/system/systemd-localed.service.d/override.conf
[Service]
PrivateNetwork=no
EOT"

sudo lxc exec ${ct_name} -- bash -lc \
  "mkdir -p /etc/systemd/system/systemd-hostnamed.service.d/ \
   && cat << EOT >> /etc/systemd/system/systemd-hostnamed.service.d/override.conf
[Service]
PrivateNetwork=no
EOT"

sudo lxc exec ${ct_name} -- bash -lc \
  "systemctl restart systemd-hostnamed && systemctl restart systemd-localed"

sudo lxc exec ${ct_name} -- bash -lc "localectl set-locale LANG=ja_JP.UTF-8"
sudo lxc exec ${ct_name} -- bash -lc "timedatectl set-timezone Asia/Tokyo"

### Install sshd and setting, autostart.
sudo lxc exec ${ct_name} -- bash -lc \
    'yum -y install openssh-server && systemctl enable sshd && systemctl start sshd'
sudo lxc exec ${ct_name} -- bash -lc \
    'sed -i -e "s/^#\(UseDNS\).*/\1 no/" -e "s/^\(GSSAPIAuthentication\).*/\1 no/" /etc/ssh/sshd_config && \
       systemctl restart sshd && systemctl enable sshd'


### Setup maintain user.
sudo lxc exec ${ct_name} -- bash -lc 'yum -y install sudo'
sudo lxc exec ${ct_name} -- bash -lc "useradd ${MAINTAIN_USER}"
sudo lxc exec ${ct_name} -- bash -lc "echo \"${MAINTAIN_USER} ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/${MAINTAIN_USER}"
sudo lxc exec ${ct_name} -- bash -lc "sudo -iu ${MAINTAIN_USER} bash -c 'mkdir -p ~/.ssh/ && chmod 700 ~/.ssh/'"

### Setup ssh key.
gen_sshkey ${ct_name} ${MAINTAIN_USER} ${USER}


### Install base development.
sudo lxc exec ${ct_name} -- bash -lc \
  'yum -y groupinstall "Development Tools" && \
   yum -y install wget zip unzip vim'

popd

