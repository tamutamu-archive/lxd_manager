#!/bin/bash -eu


CURDIR=$(cd $(dirname $0); pwd)

lxc file push ./kindle-for-pc-1-17-44183.exe windows/home/maintain/
lxc exec windows -- chown maintain:maintain /home/maintain/kindle-for-pc-1-17-44183.exe

ssh -i ../.conf/private_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -X maintain@windows.local wine kindle-for-pc-1-17-44183.exe


lxc file pull "windows/home/maintain/.local/share/icons/hicolor/256x256/apps/0914_Kindle.0.png" \
      kindle_256.png
xdg-icon-resource install --novendor --size 256 kindle_256.png kindle

cat > kindle.desktop <<EOF
[Desktop Entry]
Name=Kindle
GenericName=Kindle for PC
Comment=Ebook reader
Exec=ssh -i ${CURDIR}/../.conf/private_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -X maintain@kindle.local QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx wine ".wine/drive_c/Program\ Files\ \(x86\)/Amazon/Kindle/Kindle.exe"
Terminal=false
Type=Application
Icon=kindle
Categories=Office;Viewer;
EOF

desktop-file-validate kindle.desktop
desktop-file-install --dir=$HOME/.local/share/applications/ kindle.desktop
