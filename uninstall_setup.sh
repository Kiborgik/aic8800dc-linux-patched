#!/bin/bash
################################################################################
#			clean files
################################################################################
echo "Clean aic8800 wifi driver setup files!"
echo "Authentication requested [root] for clean:"
if [ "`uname -r |grep fc`" == " " ]; then
	  sudo su -c "rm -rf /lib/firmware/aic8800DC/"; Error=$?
	  sudo su -c "rm /etc/udev/rules.d/aic.rules"; Error=$?
	  sudo su -c "udevadm control --reload"; Error=$?
else
	  su -c "rm -rf /lib/firmware/aic8800DC/"; Error=$?
	  su -c "rm /etc/udev/rules.d/aic.rules"; Error=$?
	  su -c "udevadm control --reload"; Error=$?
fi

echo "The Uninstall Setup Script is completed!"
