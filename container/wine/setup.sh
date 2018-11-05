#!/bin/bash -eu


### Base container.
lxc exec windows apt update
lxc exec windows -- apt full-upgrade -y
lxc exec windows -- apt install -y language-pack-ja fonts-takao avahi-daemon


### Wine and Firefox install.
lxc exec windows -- dpkg --add-architecture i386
lxc exec windows -- wget -nc https://dl.winehq.org/wine-builds/Release.key
lxc exec windows -- apt-key add Release.key
lxc exec windows -- apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ xenial main'
lxc exec windows -- apt update
lxc exec windows -- apt -y install --install-recommends winehq-stable

#lxc exec windows -- add-apt-repository -y ppa:wine/wine-builds
#lxc exec windows apt update
#lxc exec windows -- apt install -y winehq-devel


### Init config Wine.
ssh -i .conf/private_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -X maintain@windows.local wineboot
sleep 7


### Setting font.
lxc exec windows -- /bin/bash -lc  \
        ' cat << EOT >> /home/maintain/.wine/user.reg

[Software\\\\Wine\\\\Fonts\\\\Replacements]
"MS Gothic"="Takaoゴシック"
"MS Mincho"="Takao明朝"
"MS PGothic"="Takao Pゴシック"
"MS PMincho"="Takao P明朝"
"MS UI Gothic"="TakaoExゴシック"
"ＭＳ ゴシック"="Takaoゴシック"
"ＭＳ 明朝"="Takao明朝"
"ＭＳ Ｐゴシック"="Takao Pゴシック"
"ＭＳ Ｐ明朝"="Takao P明朝"
EOT'
