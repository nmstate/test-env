#!/bin/bash

IMAGE="quay.io/cathay4t/nm-c9s"
NAME="nm-c9s"

CONTAINER_ID=`
    sudo podman run --systemd=true --privileged -d \
        --hostname $NAME \
        -v /home/fge/:/home/fge/ \
        $IMAGE `

sudo podman exec -i $CONTAINER_ID \
    /bin/bash -c  \
        'while ! systemctl is-active dbus; do sleep 1; done'
sudo podman exec -i $CONTAINER_ID \
    /bin/bash -c  \
        'systemctl start systemd-udevd;
        while ! systemctl is-active systemd-udevd; do sleep 1; done'
sudo podman exec -i $CONTAINER_ID \
    /bin/bash -c  \
        'systemctl restart NetworkManager;
         while ! systemctl is-active NetworkManager; do sleep 1; done'

sudo podman exec -i $CONTAINER_ID \
    /bin/bash -c  'sysctl -w net.ipv6.conf.all.disable_ipv6=0'

sudo podman exec -it $CONTAINER_ID /bin/bash
sudo podman rm $CONTAINER_ID -f
