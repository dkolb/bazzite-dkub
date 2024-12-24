#!/bin/sh

if [ "${1}" == "pre" ]; then
    if [ -n "$(rfkill list bluetooth|grep 'Soft blocked: no')" ]; then
        touch /tmp/bluetooth-was-enabled-before-suspend
        rfkill block bluetooth
    fi
elif [ "${1}" == "post" ]; then
    if [ -f "/tmp/bluetooth-was-enabled-before-suspend" ]; then
        rfkill unblock bluetooth
        rm -f /tmp/bluetooth-was-enabled-before-suspend
    fi
fi
