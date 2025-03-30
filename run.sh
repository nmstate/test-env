#!/bin/bash

IMAGE="quay.io/cathay4t/nm-c10s"
NAME="nm-c10s"

if [ "CHK$1" == "CHKnm" ];then
    shift
    ./nm.sh "$@"
elif [ "CHK$1" == "CHKipsec" ];then
    shift
    ./ipsec/run.sh "$@"
else
    echo "Usage: ./run.sh [nm|ipsec] ..."
    exit 1
fi
