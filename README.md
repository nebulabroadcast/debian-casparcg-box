# Debian CasparCG box

**Experimental script. Not suitable for production.**

This script installs CasparCG to Debian buster server. It assumes server has an NVidia GPU and Decklink card.
After the setup, the server will boot directly to minimal X11 system with CasparCG running.

## Installation

 - Install debian buster from *Debian Buster: Nebula Broadcast preseed* image
 - If you don't have NB preseed image, install Debian 10 without a desktop environment and create user `nebula`
 - Login as root
 - Run `hostnamectl set-hostname YOURPREFERREDHOSTNAME`
 - If you have a separate media storage, mount it to `/var/playout` and set-up a share.
 - Run `apt-get install -y git`
 - Clone this repository and run `./install.sh`
 - Reboot
 - ???
 - Profit
 
