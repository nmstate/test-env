#!/bin/bash -e

trap exit INT

TAGS=(nm-c9s nm-c10s libreswan-srv-c9s libreswan-cli-c9s)

for TAG in "${TAGS[@]}"; do
    podman build -f ./Containerfile.$TAG \
        -t quay.io/cathay4t/test-env:$TAG
    podman push quay.io/cathay4t/test-env:$TAG
done
