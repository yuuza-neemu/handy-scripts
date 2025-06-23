#!/bin/bash
# A script for selecting and setting the screen temperature (and brightness) based
# on a predefined set of option

choice=$(echo -e "Warm 3500K\nNeutral 4500K\nCool 6000K\nDim 3500K + 60%" | rofi -dmenu -p "Select warmth/dimming")

# Kill any existing wlsunset instances
pkill wlsunset

case "$choice" in
  "Warm 3500K")
    wlsunset -t 3500 -T 3510 &
    ;;
  "Neutral 4500K")
    wlsunset -t 4500 -T 4510 &
    ;;
  "Cool 6000K")
    wlsunset -t 6000 -T 6010 &
    ;;
  "Dim 3500K + 60%")
    wlsunset -t 3500 -T 3510 -b 0.6 &
    ;;
esac

