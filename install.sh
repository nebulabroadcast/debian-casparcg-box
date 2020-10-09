#!/bin/bash

TARGET_USER=nebula

getty_dir=/etc/systemd/system/getty@tty1.service.d
mkdir -p $getty_dir
cat <<EOT > $getty_dir/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I \$TERM
EOT

sed -i -e s/\#NAutoVTs.*/NAutoVTs=1/ /etc/systemd/logind.conf

cat <<EOT > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX=""
GRUB_GFXMODE=800x600
EOT

apt-get install -y --no-install-recommends \
    xorg xinit

systemctl set-default multi-user.target

cp support/.profile /home/$TARGET_USER/
cp support/.xinitrc /home/$TARGET_USER/
cp support/logo.png /usr/share/pixmaps/nebula.png
