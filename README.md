# Containers for test usage

The containers are stored in (https://quay.io/repository/cathay4t/test-env)

## NetworkManager on CentOS Stream 10

```bash
sudo ./run.sh nm c10s
```

## NetworkManager on CentOS Stream 9

```bash
sudo ./run.sh nm c9s
```

## IPSec using PSK authentication

```bash
sudo ./run.sh ipsec psk
```

## IPSec using RSA authentication

```bash
sudo ./run.sh ipsec rsa
```

## IPSec using PKI authentication

```bash
sudo ./run.sh ipsec cert
```

## IPSec P2P connection

```bash
sudo ./run.sh ipsec p2p
```

## IPSec Site-to-Site connection

```bash
sudo ./run.sh ipsec site2site
```

## IPSec Transport connection (p2p only)

```bash
sudo ./run.sh ipsec transport
```

## IPSec Host-to-Site connection

```bash
sudo ./run.sh ipsec host2site
```

## IPSec IPv4 in IPv6 and IPv6 in IPv4 connection

```bash
sudo ./run.sh ipsec mix46
```
