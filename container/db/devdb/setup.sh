#!/bin/bash -eu


lexec(){
  sudo lxc exec ${CT_NAME} -- /bin/bash -lc "${1}"
}

CURDIR=$(cd $(dirname $0); pwd)
CT_NAME=$(basename ${CURDIR})

### Install MySQL.
lexec "export DEBIAN_FRONTEND=noninteractive && \
       echo debconf mysql-server/root_password password password | sudo debconf-set-selections && \
       echo debconf mysql-server/root_password_again password password | sudo debconf-set-selections && \
       apt -y install mysql-server mysql-client"

lexec "sed -i -e 's/^\(bind-address.*\)/#\1/' /etc/mysql/mysql.conf.d/mysqld.cnf"
lexec "systemctl restart mysql"
lexec "mysql -uroot -ppassword << EOT
grant all privileges on *.* to root@'%' identified by 'password' with grant option;
EOT"


### Install Postgresql.
lexec "echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
lexec "wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -"
lexec "apt update"
lexec "apt -y install postgresql"
lexec "echo \"listen_addresses = '*'\" >> /etc/postgresql/10/main/postgresql.conf"
lexec "sed -i.bk -e 's@127\.0\.0\.1/32@0.0.0.0/0@g' -e 's@^\(host.*::1\/128.*\)@#\1@g' /etc/postgresql/10/main/pg_hba.conf"
lexec "sudo -i -u postgres psql -c \"alter role postgres with password 'password';\""
lexec "systemctl restart postgresql"
