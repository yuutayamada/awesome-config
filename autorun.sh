#!/bin/bash

# opacity
cairo-compmgr &
xcompmgr -cF &

# handles themes, starts gnome-screensaver. You may have to use gconf
# to disable it setting the background.
gnome-settings-daemon &
