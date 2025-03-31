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

## IPSec server with PSK authentication on CentOS Stream 9

```bash
sudo ./run.sh ipsec psk
```

## IPSec server with RSA authentication on CentOS Stream 9

```bash
sudo ./run.sh ipsec rsa
```

## IPSec server with PKI authentication on CentOS Stream 9

```bash
sudo ./run.sh ipsec cert
```

## IPSec P2P connection

```bash
sudo ./run.sh ipsec p2p
```

## IPSec Site-to-Site connection (subnet)

```bash
sudo ./run.sh ipsec subnet
```
