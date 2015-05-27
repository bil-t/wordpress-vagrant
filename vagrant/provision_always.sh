#!/bin/bash -x
if [[ ! "$(sudo service mysql status)" =~ "start/running" ]]
then
    sudo service mysql start
fi
