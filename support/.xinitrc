
# Get screen width and height. This will be used later for a terminal window geometry

width=$(xrandr --current | grep '*' | head -n 1 | uniq | awk '{print $1}' | cut -d 'x' -f1)
height=$(xrandr --current | grep '*' | head -n 1 | uniq | awk '{print $1}' | cut -d 'x' -f2)


xrdb ~/.Xresources     # Load color scheme etc
xset s off -dpms       # Turn off screensaver and screen blanking
xsetroot -solid white  # Root window background color


# Nebula logo. It is important.

xli \
    -onroot \
    -at 22,20 \
    -background "#ffffff" \
    -border "#ffffff" \
    /usr/share/pixmaps/nebula.png


# Start a terminal with CasparCG server

urxvt \
    -bd white \
    -geometry 92x26+20+130 \
    -e /bin/bash \
    -c "/opt/casparcg/run.sh; /bin/bash"
