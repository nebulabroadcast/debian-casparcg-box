width=$(xrandr --current | grep '*' | head -n 1 | uniq | awk '{print $1}' | cut -d 'x' -f1)
height=$(xrandr --current | grep '*' | head -n 1 | uniq | awk '{print $1}' | cut -d 'x' -f2)

xsetroot -solid white
xli -onroot -at 20,20 -background "#ffffff" -border "#ffffff" /usr/share/pixmaps/nebula.png

xterm -bd white -geometry 100x30+20+150
