#!/bin/bash -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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
SRV_NIC_NAME="ipsec_srv"
CLI_NIC_NAME="ipsec_cli"
SRV_CONTAINER_NAME="ipsec-srv"
CLI_CONTAINER_NAME="ipsec-cli"

SRV_IMAGE="quay.io/nmstate/test-env:libreswan-srv-c9s"
CLI_IMAGE="quay.io/nmstate/test-env:libreswan-cli-c9s"

function pull_container_image {
    local container_id=$1

    for i in {1..5};do
        podman pull $container_id && break
    done
}

function clean_up {
    podman rm -f $CLI_CONTAINER_NAME 1>/dev/null 2>/dev/null || true
    podman rm -f $SRV_CONTAINER_NAME 1>/dev/null 2>/dev/null || true
    ip netns exec $SRV_NET_NS_NAME \
        ip link del $SRV_NIC_NAME 2>/dev/null || true
    ip netns del $SRV_NET_NS_NAME 2>/dev/null || true
    ip netns del $CLI_NET_NS_NAME 2>/dev/null || true
    rm -rfv /var/lib/ipsec/nss/*.db || true
    ipsec initnss || true
}

trap clean_up EXIT

function setup_podman_network {
    clean_up

    ip netns add $SRV_NET_NS_NAME
    if [[ $SRV_ONLY -eq 0 ]]; then
        ip netns add $CLI_NET_NS_NAME
    fi
    ip link add $CLI_NIC_NAME type veth peer $SRV_NIC_NAME
    ip link set $SRV_NIC_NAME netns $SRV_NET_NS_NAME
    ip netns exec $SRV_NET_NS_NAME ip link set $SRV_NIC_NAME up
    if [[ $SRV_ONLY -eq 0 ]]; then
        ip link set $CLI_NIC_NAME netns $CLI_NET_NS_NAME
        ip netns exec $CLI_NET_NS_NAME ip link set $CLI_NIC_NAME up
    else
        ip link set $CLI_NIC_NAME up
    fi
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

function start_srv {
    pull_container_image $SRV_IMAGE

    podman run -d --privileged --replace \
        --name $SRV_CONTAINER_NAME --hostname ipsec-srv.example.org \
        --network ns:/run/netns/$SRV_NET_NS_NAME \
        $SRV_IMAGE
}

function start_ipsec_service {
    podman cp $IPSEC_CONF $SRV_CONTAINER_NAME:/etc/ipsec.d/srv.conf

    wait_services $SRV_CONTAINER_NAME
}

function start_cli {
    pull_container_image $CLI_IMAGE

    podman run -d --privileged --replace \
        --name $CLI_CONTAINER_NAME --hostname cli-a.example.org \
        --network ns:/run/netns/$CLI_NET_NS_NAME \
        $CLI_IMAGE
    wait_services $CLI_CONTAINER_NAME
}

function load_cli_keys {
    ipsec checknss;
    pk12util -i $SCRIPT_DIR/pki/cli-a.example.org.p12 \
        -d sql:/var/lib/ipsec/nss -W ""
    certutil -M -n "Easy-RSA CA" -t CT  -d sql:/var/lib/ipsec/nss/
    systemctl restart ipsec
}

#### Main function starts

cd $SCRIPT_DIR

if [ "CHK$1" == "CHKpsk" ];then
    IPSEC_CONF="libreswan_conf/psk_gw.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_psk_gw.yml"
elif [ "CHK$1" == "CHKrsa" ];then
    IPSEC_CONF="libreswan_conf/rsa_gw.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_rsa_gw.yml"
elif [ "CHK$1" == "CHKcert" ];then
    IPSEC_CONF="libreswan_conf/cert_gw.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_cert_gw.yml"
elif [ "CHK$1" == "CHKp2p" ];then
    IPSEC_CONF="libreswan_conf/p2p.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_p2p.yml"
elif [ "CHK$1" == "CHKsite2site" ];then
    IPSEC_CONF="libreswan_conf/site_to_site.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_site_to_site.yml"
elif [ "CHK$1" == "CHKtransport" ];then
    IPSEC_CONF="libreswan_conf/transport.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_transport.yml"
elif [ "CHK$1" == "CHKhost2site" ];then
    IPSEC_CONF="libreswan_conf/host_to_site.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_host_to_site.yml"
elif [ "CHK$1" == "CHKmix46" ];then
    IPSEC_CONF="libreswan_conf/4in6_6in4.conf"
    NMSTATE_IPSEC_CLI_YML="/root/nmstate_conf/nmstate_4in6_6in4.yml"
else
    echo "Invalid argument."
    echo -n "Valid are 'psk', 'rsa', 'cert', 'p2p', 'site2site', 'transport', "
    echo "'host2site', 'mix46'."
    echo "Use --server-only for creating server container only"
    exit 1
fi

SRV_ONLY=0

if [[ "$@" == *"--server-only"* ]]; then
    SRV_ONLY=1
fi

setup_podman_network
start_srv


if [[ $SRV_ONLY -eq 0 ]]; then
  start_cli
else
  load_cli_keys
  NMSTATE_IPSEC_CLI_YML="$SCRIPT_DIR/nmstate_conf/$(basename \
      $NMSTATE_IPSEC_CLI_YML)"
fi

start_ipsec_service

if [[ $SRV_ONLY -eq 0 ]]; then
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
else
    echo "
    IPSEC Server has been started.
    The client authenticaion key has been imported.
    You may start the ipsec connection by invoking command(in another terminal):

        nmstatectl apply $SCRIPT_DIR/ipsec_cli_network.yml
        nmstatectl apply $NMSTATE_IPSEC_CLI_YML

    Press enter to clean and quit.
    ".
    read
fi

echo "Cleaning up"
