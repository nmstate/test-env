# Steps to create CA and keys for hostapd IEEE 802.1x authentication

```
mkdir tmp_pki_dir
cd tmp_pki_dir
cp /etc/easy-rsa/vars ./
# Uncomment EASYRSA_CA_EXPIRE EASYRSA_CERT_EXPIRE and set long expired days


easyrsa init-pki
easyrsa gen-dh
# Set the CA password to `test-env!`
easyrsa build-ca
easyrsa  --subject-alt-name="DNS:ieee802-1x-srv.example.org" \
    build-server-full ieee802-1x-srv.example.org nopass
# Use `password` for client key
easyrsa  --subject-alt-name="DNS:ieee802-1x-cli-a.example.org" \
    build-client-full ieee802-1x-cli-a.example.org
```
