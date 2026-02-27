#!/bin/bash -e
# SPDX-License-Identifier: Apache-2.0


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

SRV_NET_NS_NAME="802-1x-srv"
SRV_NIC_NAME="802_1x_srv"
CLI_NIC_NAME="802_1x_cli"
SRV_CONTAINER_NAME="802-1x-srv"

CLI_NIC_MAC="00:23:45:67:ef:bc"
SRV_IMAGE="quay.io/nmstate/test-env:8021x-srv-c10s"
NMSTATE_802_1X_CLI_YML="$SCRIPT_DIR/nmstate-ieee802-1x-cli-a.yml"
CLI_PKI_KEY_PATH="/etc/pki/802-1x-test"
CLI_KEYS=(
    "ca.crt"
    "ieee802-1x-cli-a.example.org.key"
    "ieee802-1x-cli-a.example.org.crt"
)

function pull_container_image {
    local container_id=$1

    for i in {1..5};do
        podman pull $container_id && break
    done
}

function clean_up {
    podman rm -f $SRV_CONTAINER_NAME 1>/dev/null 2>/dev/null || true
    ip netns exec $SRV_NET_NS_NAME \
        ip link del $SRV_NIC_NAME 2>/dev/null || true
    ip netns del $SRV_NET_NS_NAME 2>/dev/null || true
    rm -rf $CLI_PKI_KEY_PATH 2>/dev/null || true
}

function setup_podman_network {
    clean_up

    ip netns add $SRV_NET_NS_NAME
    ip link add $CLI_NIC_NAME address ${CLI_NIC_MAC} \
        type veth peer $SRV_NIC_NAME
    ip link set $SRV_NIC_NAME netns $SRV_NET_NS_NAME
    ip netns exec $SRV_NET_NS_NAME ip link set $SRV_NIC_NAME up
    ip link set $CLI_NIC_NAME up
}

function start_srv {
    # pull_container_image $SRV_IMAGE

    podman run -d --privileged --replace \
        --name $SRV_CONTAINER_NAME --hostname 802-1x-srv.example.org \
        --network ns:/run/netns/$SRV_NET_NS_NAME \
        $SRV_IMAGE
}

function install_cli_key {
    mkdir -p /etc/pki/802-1x-test
    for key in "${CLI_KEYS[@]}"; do
        cp -fv $SCRIPT_DIR/pki/$key $CLI_PKI_KEY_PATH
    done
}

#### Main function starts

cd $SCRIPT_DIR

trap clean_up EXIT

SRV_ONLY=0

if [[ "$@" == *"--server-only"* ]]; then
    SRV_ONLY=1
fi

setup_podman_network
start_srv
install_cli_key

echo "
IEEE 802.1x Server has been started in $SRV_CONTAINER_NAME container.
You may start the 802.1x authentication by invoking command(in another terminal):

    nmstatectl apply $NMSTATE_802_1X_CLI_YML

Press enter to clean and quit.
".
read

echo "Cleaning up"
