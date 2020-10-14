#!/bin/bash

TARGET_USER=nebula
DESKTOP_VIDEO_VERSION="11.2a8"
REPO_URL="https://repo.imm.cz"

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
temp_dir=/tmp/$(basename "${BASH_SOURCE[0]}")

function error_exit {
    printf "\n\033[0;31mInstallation failed\033[0m\n"
    cd ${base_dir}
    exit 1
}

function finished {
    printf "\n\033[0;92mInstallation completed\033[0m\n"
    cd ${base_dir}
    exit 0
}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   error_exit
fi


apt-get update

apt-get install -y --no-install-recommends \
    xorg xinit \
    xserver-xorg-input-libinput xserver-xorg-input-kbd xserver-xorg-input-mouse \
    rxvt-unicode xli \
    linux-headers-$(uname -r) \
    software-properties-common || error_exit

#
# Install Nvidia driver
#

add-apt-repository contrib
add-apt-repository non-free
apt-get update
apt-get install -y nvidia-driver

#
# Install decklink driver
#

DESKTOP_VIDEO_FNAME="desktopvideo_${DESKTOP_VIDEO_VERSION}_amd64.deb"

wget ${REPO_URL}/${DESKTOP_VIDEO_FNAME} || error_exit
dpkg -i ${DESKTOP_VIDEO_FNAME}
apt -y -f install

#
# Autologin
#

getty_dir=/etc/systemd/system/getty@tty1.service.d
mkdir -p $getty_dir
cat <<EOT > $getty_dir/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I \$TERM
EOT

sed -i -e s/\#NAutoVTs.*/NAutoVTs=1/ /etc/systemd/logind.conf
systemctl set-default multi-user.target

#
# Disable Grub menu
#

cat <<EOT > /etc/default/grub
#GRUB_DEFAULT=0
#GRUB_TIMEOUT=0
#GRUB_TIMEOUT_STYLE=hidden
#GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_DISTRIBUTOR=`Nebula Broadcast`
GRUB_CMDLINE_LINUX_DEFAULT="quiet nomodeset"
GRUB_CMDLINE_LINUX=""
GRUB_GFXMODE=800x600
EOT

update-grub

#
# Font and logo
#

cp support/logo.png /usr/share/pixmaps/nebula.png
cp -r support/RobotoMono /usr/share/fonts/truetype/

#
# User configuration files
#

cp support/.profile /home/$TARGET_USER/
cp support/.xinitrc /home/$TARGET_USER/
cp support/.Xresources /home/$TARGET_USER/

chown $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.profile
chown $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.xinitrc
chown $TARGET_USER:$TARGET_USER /home/$TARGET_USER/.Xresources

#
# CasparCG
#

if [ ! -d /var/playout ]; then
    mkdir /var/playout
fi

if [ ! -d /var/playout/media.dir ]; then
    mkdir /var/playout/media.dir
fi

if [ ! -d /var/playout/templates.dir ]; then
    mkdir /var/playout/templates.dir
fi

if [ ! -d /var/playout/log.dir ]; then
    mkdir /var/playout/log.dir
fi

cd /opt
wget ${REPO_URL}/casparcg.tar.gz || return 1
tar -xf casparcg.tar.gz 
rm casparcg.tar.gz

if [ -d /opt/casparcg/media ]; then
    rm -rf /opt/media
fi

if [ -d /opt/casparcg/template ]; then
    rm -rf /opt/template
fi

if [ -d /opt/casparcg/log ]; then
    rm -rf /opt/log
fi

ln -s /var/playout/media.dir /opt/casparcg/media
ln -s /var/playout/templates.dir /opt/casparcg/template
ln -s /var/playout/log.dir /opt/casparcg/log

chown -R $TARGET_USER:$TARGET_USER /var/playout
chown -R $TARGET_USER:$TARGET_USER /opt/casparcg

finished
