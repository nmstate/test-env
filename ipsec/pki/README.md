# The CA password is: `test-env!`

# Steps to create CA and keys

```
mkdir tmp_pki_dir
cd tmp_pki_dir
cp /etc/easy-rsa/vars ./
# Uncomment EASYRSA_CA_EXPIRE EASYRSA_CERT_EXPIRE and set long expired days

easyrsa init-pki
easyrsa build-ca
easyrsa  --subject-alt-name="DNS:ipsec-srv.example.org" \
    build-server-full ipsec-srv.example.org nopass
easyrsa  --subject-alt-name="DNS:cli-a.example.org" \
    build-server-full cli-a.example.org nopass
```

# Steps to create p12 file

```bash
for host in "ipsec-srv.example.org" "cli-a.example.org"; do
    # Empty passwd used for p12
    openssl pkcs12 -export -in ${host}.crt \
        -inkey ${host}.key \
        -certfile ca.crt \
        -passout pass:"" \
        -out ${host}.p12 -name ${host}
done
```

## Steps to import p12 into ipsec NSS

* Interactive way

```bash
ipsec checknss
ipsec import <path_of_p12>
```

* Scriptable way

```bash
ipsec checknss
pk12util -i <path_of_p12> -d sql:/var/lib/ipsec/nss -W ""
```
