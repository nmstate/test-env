#!/bin/bash -e

IPSEC_SRV_IPV4_SUBNET="192.0.2.0/24"
IPSEC_SRV_IPV6_SUBNET="2001:db8:a::/64"
SEV_IPSEC_IPV4_ADDR="192.0.2.1"
SRV_IPSEC_IPV6_ADDR="2001:db8:a::1"
SRV_CORP_IPV4_ADDR="10.0.0.1"
SRV_CORP_IPV6_ADDR="fd00:a::1"
#CORP_IPV4_SUBNET="10.0.0.0/24"
#CORP_IPV6_SUBNET="fd00:a::/64"

SRV_NET_NS_NAME="ipsec-srv"
CLI_NET_NS_NAME="ipsec-cli"
SRV_CONTAINER_NAME="ipsec-srv"
CLI_CONTAINER_NAME="ipsec-cli"

PSK_IMAGE="quay.io/cathay4t/test-env:libreswan-psk-c9s"
CLI_IMAGE="quay.io/cathay4t/test-env:libreswan-cli-c9s"

function clean_up {
    podman rm -f $CLI_CONTAINER_NAME 1>/dev/null 2>/dev/null || true
    podman rm -f $SRV_CONTAINER_NAME 1>/dev/null 2>/dev/null || true
    ip netns exec $CLI_NET_NS_NAME ip link del ipsec_cli 2>/dev/null || true
    ip netns del $SRV_NET_NS_NAME 2>/dev/null || true
    ip netns del $CLI_NET_NS_NAME 2>/dev/null || true
}

trap clean_up EXIT

function setup_podman_network {
    clean_up

    ip netns add $SRV_NET_NS_NAME
    ip netns add $CLI_NET_NS_NAME
    ip link add ipsec_cli type veth peer ipsec_srv
    ip link set ipsec_srv netns $SRV_NET_NS_NAME
    ip link set ipsec_cli netns $CLI_NET_NS_NAME
    ip netns exec $SRV_NET_NS_NAME ip link set ipsec_srv up
    ip netns exec $CLI_NET_NS_NAME ip link set ipsec_cli up
}

function wait_services {
    local container_id=$1

    podman exec -i $container_id /bin/bash -c  \
        'systemctl start NetworkManager.service;
         while ! systemctl is-active NetworkManager.service; do sleep 1; done'
    podman exec -i $container_id /bin/bash -c  \
         'systemctl start nmstate.service;
          while ! systemctl is-active nmstate.service; do sleep 1; done'

    # Need to wait 2 seconds for IPv6 duplicate address detection
    sleep 2

    podman exec -i $container_id /bin/bash -c  \
         'systemctl start ipsec.service;
          while ! systemctl is-active ipsec.service; do sleep 1; done'

}

function start_psk_srv {
    podman run -d --privileged --replace \
        --name $SRV_CONTAINER_NAME --hostname hostb.example.org \
        --network ns:/run/netns/$SRV_NET_NS_NAME \
        $PSK_IMAGE

    wait_services $SRV_CONTAINER_NAME
}

function start_cli {
    podman run -d --privileged --replace \
        --name $CLI_CONTAINER_NAME --hostname hosta.example.org \
        --network ns:/run/netns/$CLI_NET_NS_NAME \
        $CLI_IMAGE
    wait_services $CLI_CONTAINER_NAME
}

if [ "CHK$1" == "CHK" ];then
    echo "Please define \$1, valid values: psk"
    exit 1
elif [ "CHK$1" == "CHKpsk" ];then
    setup_podman_network
    start_psk_srv
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_psk.yml"
fi

start_cli

podman exec -i $CLI_CONTAINER_NAME nmstatectl apply $NMSTATE_IPSEC_CLI_YML

echo "
Both IPSEC Server and Client container started.

You will be placed in the client container. Exit will purge both containters.

The nmstate YAML $NMSTATE_IPSEC_CLI_YML has applied.

To check the ipsec connection, try

    ipsec status
    ip xfrm state
    nmcli c
"
podman exec -it $CLI_CONTAINER_NAME bash
