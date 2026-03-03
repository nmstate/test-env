#!/bin/bash -ex

trap exit INT

PROJECT_BASE_DIR=$(readlink -f "$(dirname -- "$0")");

# The podman cross platform is only works in Fedora with `qemu-user-static`,
# even Archlinux will not work, hence we force user of this script
# to run in Fedora

if [ ! -f /etc/fedora-release ];then
    echo "Please run this script in Fedora"
    exit 1
fi

rpm -q qemu-user-static 1>/dev/null 2>/dev/null || \
    (echo "Please install qemu-user-static"; exit 1)

echo "Make sure you have \`qemu-user-static\` installed"

TAGS=(nm-c9s nm-c10s libreswan-srv-c9s libreswan-cli-c9s 8021x-srv-c10s)


for TAG in "${TAGS[@]}"; do
    IMAGE="quay.io/nmstate/test-env:$TAG"
    podman image rm $IMAGE -f || true
    podman manifest rm $IMAGE || true
    podman manifest create $IMAGE
    podman build \
        --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x \
        -f ./containers/Containerfile.$TAG \
        --manifest $IMAGE $PROJECT_BASE_DIR
    podman manifest push $IMAGE
done
