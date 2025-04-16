#!/bin/bash -ex

trap exit INT

echo "Make sure you have \`qemu-user-static\` installed"

TAGS=(nm-c9s nm-c10s libreswan-srv-c9s libreswan-cli-c9s)


for TAG in "${TAGS[@]}"; do
    IMAGE="quay.io/nmstate/test-env:$TAG"
    podman image rm $IMAGE -f || true
    podman manifest rm $IMAGE || true
    podman manifest create $IMAGE
    podman build \
        --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x \
        -f ./Containerfile.$TAG \
        --manifest $IMAGE
    podman manifest push $IMAGE
done
