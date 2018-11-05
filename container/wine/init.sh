#!/bin/bash -eu


### Create container.
ctl init --img ubuntu16


### Generate ssh key.
ctl start
sleep 5
ctl gen_sshkey --ssh_user maintain
ctl stop


### Generate ssh key.
ctl launch

