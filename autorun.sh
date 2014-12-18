#!/bin/bash
test -z $XDG_CONFIG_HOME && export XDG_CONFIG_HOME="$HOME/.config"

# opacity
if which cairo-compmgr; then
  cairo-compmgr &
fi

if which xcompmgr; then
  xcompmgr -cF &
fi

# handles themes, starts gnome-screensaver. You may have to use gconf
# to disable it setting the background.
if which gnome-settings-daemon; then
  gnome-settings-daemon &
fi

touch /tmp/trello.txt

if ! pgrep gpg-agent; then
  eval `gpg-agent --daemon`
fi

if which conky && ! pgrep conky; then
  conky -u 3 -p 3 -d -c $XDG_CONFIG_HOME/conky/conky.conf &
  ~/.config/conky/gonky/cmd/gonky_trello_update &
  conky -u 100 -p 3 -d -c $XDG_CONFIG_HOME/conky/gonky/gonky_trello \
        -f "Ricty:size=12" -a bottom_right &
fi
