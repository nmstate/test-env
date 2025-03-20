#!/bin/bash -ex

IPSEC_SRV_IPV4_SUBNET="192.0.2.0/24"
IPSEC_SRV_IPV6_SUBNET="2001:db8:a::/64"
SEV_IPSEC_IPV4_ADDR="192.0.2.1"
SRV_IPSEC_IPV6_ADDR="2001:db8:a::1"
SRV_CORP_IPV4_ADDR="10.0.0.1"
SRV_CORP_IPV6_ADDR="fd00:a::1"
#CORP_IPV4_SUBNET="10.0.0.0/24"
#CORP_IPV6_SUBNET="fd00:a::/64"

PSK_IMAGE="quay.io/cathay4t/test-env:libreswan-psk-c9s"

function clean_up {
    podman network rm br0 -f
    nmcli c del br0 || true
    ip link del br0 || true
}


function setup_podman_network {
    clean_up

    sleep 1

    echo "
    interfaces:
      - name: br0
        type: linux-bridge
        bridge:
          options:
            stp:
              enabled: false
    " | nmstatectl apply -


    podman network create br0 \
        --driver bridge --opt "mode=unmanaged" --interface-name br0 --internal \
        --disable-dns \
        --subnet $IPSEC_SRV_IPV4_SUBNET --subnet $IPSEC_SRV_IPV6_SUBNET

}

function start_psk {
    podman pull $PSK_IMAGE
    CONTAINER_ID=$(podman run -d --privileged \
        --name ipsec-srv-psk --hostname hostb.example.org \
        --network br0:ip=$SEV_IPSEC_IPV4_ADDR,ip6=$SRV_IPSEC_IPV6_ADDR \
        $PSK_IMAGE)
    podman exec $CONTAINER_ID ip link add corp0 type dummy
    podman exec $CONTAINER_ID ip link set corp0 up
    podman exec $CONTAINER_ID ip addr add ${SRV_CORP_IPV4_ADDR}/24 dev corp0
    podman exec $CONTAINER_ID ip addr add ${SRV_CORP_IPV6_ADDR}/64 dev corp0
}

if [ "CHK$1" == "CHK" ];then
    echo "Please define \$1, valid values: psk"
    exit 1
elif [ "CHK$1" == "CHKpsk" ];then
    setup_podman_network
    start_psk
fi

echo "
    routes:
      config:
        - destination: 0.0.0.0/0
          state: absent
        - destination: 0.0.0.0/0
          next-hop-interface: br0
          next-hop-address: 192.0.2.1
        - destination: ::/0
          next-hop-interface: br0
          next-hop-address: 2001:db8:a::1
    interfaces:
      - name: br0
        type: linux-bridge
        bridge:
          options:
            stp:
              enabled: false
        ipv4:
          enabled: true
          dhcp: false
          address:
            - ip: 192.0.2.2
              prefix-length: 24
        ipv6:
          enabled: true
          dhcp: false
          autoconf: false
          address:
            - ip: 2001:db8:a::2
              prefix-length: 64
    " | nmstatectl apply -



echo "
To start the ipsec connection, please invoke

    nmstatectl apply -f ./ipsec/psk.yml

To test the ipsec connection, try

    ping $SRV_CORP_IPV4_ADDR
"

read -n 1 -p "Press anykey to delete this container and clean up"

podman rm -f $CONTAINER_ID
clean_up
