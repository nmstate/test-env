<!-- vim-markdown-toc GFM -->

* [Containers for test usage](#containers-for-test-usage)
    * [NetworkManager](#networkmanager)
        * [NetworkManager on CentOS Stream 10](#networkmanager-on-centos-stream-10)
        * [NetworkManager on CentOS Stream 9](#networkmanager-on-centos-stream-9)
    * [IPSec](#ipsec)
        * [IPSec using PSK authentication](#ipsec-using-psk-authentication)
        * [IPSec using RSA authentication](#ipsec-using-rsa-authentication)
        * [IPSec using PKI authentication](#ipsec-using-pki-authentication)
        * [IPSec P2P connection](#ipsec-p2p-connection)
        * [IPSec Site-to-Site connection](#ipsec-site-to-site-connection)
        * [IPSec Transport connection (p2p only)](#ipsec-transport-connection-p2p-only)
        * [IPSec Host-to-Site connection](#ipsec-host-to-site-connection)
        * [IPSec IPv4 in IPv6 and IPv6 in IPv4 connection](#ipsec-ipv4-in-ipv6-and-ipv6-in-ipv4-connection)

<!-- vim-markdown-toc -->

The containers are stored in (https://quay.io/repository/nmstate/test-env)

All files licensed under Apache 2.0.

# Containers for test usage

## NetworkManager

### NetworkManager on CentOS Stream 10

```bash
sudo ./run.sh nm c10s
```

### NetworkManager on CentOS Stream 9

```bash
sudo ./run.sh nm c9s
```

## IPSec

By default, this script will create both server and client containers.

Passing `--server-only` will only create server container and load IPSec
keys to local ipsec database.

### IPSec using PSK authentication

```bash
sudo ./run.sh ipsec psk
```

### IPSec using RSA authentication

```bash
sudo ./run.sh ipsec rsa
```

### IPSec using PKI authentication

```bash
sudo ./run.sh ipsec cert
```

### IPSec P2P connection

```bash
sudo ./run.sh ipsec p2p
```

### IPSec Site-to-Site connection

```bash
sudo ./run.sh ipsec site2site
```

### IPSec Transport connection (p2p only)

```bash
sudo ./run.sh ipsec transport
```

### IPSec Host-to-Site connection

```bash
sudo ./run.sh ipsec host2site
```

### IPSec IPv4 in IPv6 and IPv6 in IPv4 connection

```bash
sudo ./run.sh ipsec mix46
```
