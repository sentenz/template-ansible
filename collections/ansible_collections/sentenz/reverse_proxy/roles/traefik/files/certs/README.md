# `certs/`

The `certs/` directory contains self-signed certificates used for Reverse Proxy and TLS termination.

## Creating a CA and Signing a Certificate using `mkcert`

```bash
install -d certs
# Localhost
# mkcert -key-file certs/key.pem -cert-file certs/cert.pem dependency-track.localhost api.dependency-track.localhost
# Challenges
mkcert -key-file certs/key.pem -cert-file certs/cert.pem dependency-track.sentenz.dev api.dependency-track.sentenz.dev
# All
mkcert -key-file certs/key.pem -cert-file certs/cert.pem dependency-track.localhost api.dependency-track.localhost dependency-track.sentenz.dev api.dependency-track.sentenz.dev
mkcert -install
```

## Creating a CA and Signing a Certificate

1. Certificates

      ```bash
      openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem -config openssl.ini
      ```

    - `openssl.ini`

      ```ini
      [ req ]
      default_bits       = 2048
      distinguished_name = req_distinguished_name
      req_extensions     = req_ext
      prompt             = no

      [ req_distinguished_name ]
      CN = dependency-track.sentenz.dev

      [ req_ext ]
      subjectAltName = @alt_names

      [ alt_names ]
      DNS.1 = dependency-track.localhost
      DNS.2 = api.dependency-track.localhost
      DNS.3 = dependency-track.sentenz.dev
      DNS.4 = api.dependency-track.sentenz.dev
      ```

2. Trust Store

    - Convert or Rename Your Certificate

      ```bash
      cp myCA.pem myCA.crt
      ```

    - Copy the Certificate to the CA Directory

      ```bash
      sudo cp myCA.crt /usr/local/share/ca-certificates/
      ```

    - Update the CA Certificates

      ```bash
      sudo update-ca-certificates --fresh
      ```

3. Testing the Trust

    ```bash
    curl -v https://your-signed-domain.example
    ```
