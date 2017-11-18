#!/bin/bash

#settings variables
SSID=RiggingSystemNetwork
CON=Hotspot
WIFI=wlan0

#add a new connection to NetworkManager
echo "Starting Network"
sudo nmcli connection add type wifi ifname $WIFI con-name $CON autoconnect no ssid $SSID

#change the connection type to a hotspot
echo "Modifying Connection Settings"
sudo nmcli connection modify $CON 802-11-wireless.mode ap 802-11-wireless.band a ipv4.method shared

#turn on the connection
echo "Broadcasting Network"
sudo nmcli connection up $CON

#run the server code
echo "Starting Server"
#python3 server.py
