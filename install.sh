#!/bin/bash

TARGET_USER=nebula
DESKTOP_VIDEO_VERSION="11.6a26"
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



function install_base(){
    apt-get update
    apt-get install -y --no-install-recommends \
        xorg xinit \
        xserver-xorg-input-libinput xserver-xorg-input-kbd xserver-xorg-input-mouse \
        rxvt-unicode xli \
        python3 python3-pip \
        linux-headers-$(uname -r) \
        software-properties-common || return 1
}

function install_nvidia(){
    add-apt-repository contrib
    add-apt-repository non-free
    apt-get update
    apt-get install -y nvidia-driver nvidia-smi || return 1
}

function install_decklink(){
    DESKTOP_VIDEO_FNAME="desktopvideo_${DESKTOP_VIDEO_VERSION}_amd64.deb"
    wget ${REPO_URL}/${DESKTOP_VIDEO_FNAME} || return 1
    dpkg -i ${DESKTOP_VIDEO_FNAME}
    apt -y -f install
}

function enable_autologin(){
    getty_dir=/etc/systemd/system/getty@tty1.service.d
    mkdir -p $getty_dir
    cat <<EOT > $getty_dir/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I \$TERM
EOT
    sed -i -e s/\#NAutoVTs.*/NAutoVTs=1/ /etc/systemd/logind.conf
    systemctl set-default multi-user.target
}


function update_grub(){
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
}



function install_casparcg(){
    cd /opt
    wget ${REPO_URL}/casparcg.tar.gz || return 1
    tar -xf casparcg.tar.gz
    rm casparcg.tar.gz

    DIRS=(
        "media"
        "template"
        "log"
        "data"
    )

    for dir in ${DIRS[@]}; do
        if [ ! -d /var/playout/${dir}.dir ]; then
            mkdir -p /var/playout/${dir}.dir
        fi
        if [ -d /opt/casparcg/${dir} ]; then
            rm -rf /opt/${dir}
            ln -s /var/playout/${dir}.dir /opt/${dir}
        fi
    done

    if [ ! -d /var/playout/fonts.dir ]; then
        mkdir /var/playout/fonts.dir
    fi
    if [ ! -L /usr/share/fonts/truetype/playout ]; then
        ln -s /var/playout/fonts.dir /usr/share/fonts/truetype/playout
    fi
}


function install_promexp(){
    cd /opt
    if [ ! -d nebula-prometheus-exporter ]; then
        git clone https://github.com/nebulabroadcast/nebula-prometheus-exporter
    fi
    cd nebula-prometheus-exporter
    git pull
    make
    systemctl enable nebula-prometheus-exporter
    systemctl start nebula-prometheus-exporter
}


install_base || error_exit
install_nvidia || error_exit
install_decklink || error_exit
enable_autologin || error_exit
update_grub || error_exit

install_casparcg || error_exit
install_promexp || error_exit


chown -R $TARGET_USER:$TARGET_USER /var/playout
chown -R $TARGET_USER:$TARGET_USER /opt/casparcg
addgroup $TARGET_USER sudo
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




finished
