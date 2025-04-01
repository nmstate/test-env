#!/bin/bash -x

IMAGE="quay.io/nmstate/nm-c10s"
NAME="nm-c10s"

if [ "CHK$1" == "CHKc9s" ];then
    IMAGE="quay.io/nmstate/nm-c9s"
    NAME="nm-c9s"
elif [ "CHK$1" == "CHKc10s" ];then
    IMAGE="quay.io/nmstate/nm-c10s"
    NAME="nm-c10s"
fi

CONTAINER_ID=`podman run --systemd=true --privileged -d \
    --hostname $NAME \
    -v $HOME:$HOME \
    $IMAGE `

podman exec -i $CONTAINER_ID \
    /bin/bash -c  \
        'systemctl start systemd-udevd;
        while ! systemctl is-active systemd-udevd; do sleep 1; done'
podman exec -i $CONTAINER_ID \
    /bin/bash -c  \
        'systemctl restart NetworkManager;
         while ! systemctl is-active NetworkManager; do sleep 1; done'

podman exec -i $CONTAINER_ID \
    /bin/bash -c  'sysctl -w net.ipv6.conf.all.disable_ipv6=0'

podman exec -it $CONTAINER_ID /bin/bash
podman rm $CONTAINER_ID -f
echo "Container deleted"
