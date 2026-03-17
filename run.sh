#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

IMAGE="quay.io/nmstate/nm-c10s"
NAME="nm-c10s"

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )")

cd $SCRIPT_DIR

if [ "CHK$1" == "CHKnm" ];then
    shift
    ./nm.sh "$@"
elif [ "CHK$1" == "CHKipsec" ];then
    shift
    ./ipsec/run.sh "$@"
elif [ "CHK$1" == "CHK802_1x" ];then
    shift
    ./802_1x/run.sh "$@"
else
    echo "Usage: ./run.sh [nm|ipsec|802_1x] ..."
    exit 1
fi
