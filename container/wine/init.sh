#!/bin/bash -eu


### Create container.
poron init --img ubuntu16


### Generate ssh key.
poron start
sleep 5
poron gen_sshkey --ssh_user maintain
poron stop


### Generate ssh key.
poron launch

