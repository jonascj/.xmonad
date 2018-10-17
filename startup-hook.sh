#!/bin/sh


# Network Manager Applet (nm-applet)
if [ -z "$(pgrep nm-applet)" ] ; then
    echo "nm-applet not running, starting it."
    nm-applet &
else
    echo "nm-applet alread running."
fi



