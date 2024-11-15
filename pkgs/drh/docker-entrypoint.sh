#!/bin/sh
#
# Entry point for tellicast docker container
# Maintainer: Daniel R. Hurtmans
#
# Start services for using e-token
sudo /etc/init.d/pcscd start 
sudo /etc/init.d/SACSrv start

# Start tellicast
sudo /etc/init.d/tellicast-client start

# Sleep to maintain the container running in the background 
sleep infinity

