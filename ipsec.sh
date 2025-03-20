#!/bin/bash -ex

IPSEC_SRV_IPV4_SUBNET="192.0.2.0/24"
IPSEC_SRV_IPV6_SUBNET="2001:db8:a::/64"
SEV_IPSEC_IPV4_ADDR="192.0.2.1"
SRV_IPSEC_IPV6_ADDR="2001:db8:a::1"
SRV_CORP_IPV4_ADDR="10.0.0.1"
SRV_CORP_IPV6_ADDR="fd00:a::1"
CORP_IPV4_SUBNET="10.0.0.0/24"
CORP_IPV6_SUBNET="fd00:a::/64"

PSK_IMAGE="quay.io/cathay4t/test-env:librswan-c9s-psk"

function clean_up {
    podman network rm gw -f
    podman network rm br0 -f
    podman network rm corp -f
    ip link del br0 || true
}


function setup_podman_network {
    clean_up

    sleep 1
    ip link add br0 type bridge || true
    ip link set br0 up

    podman network create gw

    podman network create br0 \
        --driver bridge --opt "mode=unmanaged" --interface-name br0 --internal \
        --disable-dns \
        --subnet $IPSEC_SRV_IPV4_SUBNET --subnet $IPSEC_SRV_IPV6_SUBNET

    podman network create corp \
        --internal -o "no_default_route=1" \
        --subnet $CORP_IPV4_SUBNET --subnet $CORP_IPV6_SUBNET

}

function start_psk {
    CONTAINER_ID=$(podman run -d --privileged \
        --name ipsec-srv-psk --hostname hostb.example.org \
        --network corp:ip=$SRV_CORP_IPV4_ADDR,ip6=$SRV_CORP_IPV6_ADDR \
        --network br0:ip=$SEV_IPSEC_IPV4_ADDR,ip6=$SRV_IPSEC_IPV6_ADDR \
        --network gw \
        $PSK_IMAGE)
}

if [ "CHK$1" == "CHK" ];then
    echo "Please define \$1, valid values: psk"
    exit 1
elif [ "CHK$1" == "CHKpsk" ];then
    setup_podman_network
    start_psk
fi

echo "
To start the ipsec connection, please invoke

    nmstatectl apply -f ./ipsec/psk.yml

"

read -n 1 -p "Press anykey to delete this container and clean up"

podman rm -f $CONTAINER_ID
clean_up
