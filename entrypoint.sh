#!/bin/bash

sudo -u softs bash -c '#while [ True ] ; do echo work ; sleep 2 ; done & \
sudo /etc/init.d/redis-server start ; \
sudo /etc/init.d/postgresql start ; \
sleep 5 && sleep 1 ; \
source $HOME/.rvm/scripts/rvm ; \
cd /home/softs/appserver/medods ; \
rails s -e production -d ; \
while [ True ] ; do echo work ; sleep 2 ; done'
