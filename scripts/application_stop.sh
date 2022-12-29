#!/bin/bash
#Stopping existing node servers
echo "Stopping any existing node server"
pkill node
# systemctl stop node-api.service
# sudo rm -rf /home/linux/Code/node-codedeploy