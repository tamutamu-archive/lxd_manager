#!/bin/bash

sudo snap remove lxd
sudo rm -rf /var/lxd/
sudo rm -f /etc/profile.d/poron.sh /etc/sudoers.d/poron

echo "Need to os restart."
