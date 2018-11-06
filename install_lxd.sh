#!/bin/bash -eu
set -euo pipefail

CURDIR=$(cd $(dirname $0); pwd)
pushd ${CURDIR}

. var.conf


# Remove lxd.
sudo apt -y purge lxd*
sudo apt -y autoremove
sudo apt -y autoclean


# Install lxd.
sudo apt -y install snapd zfsutils-linux jq dnsmasq-utils
sudo snap install lxd --channel=3.0
sudo lxd waitready

sudo usermod -aG lxd ${USER}

echo "Please logout and login!"
