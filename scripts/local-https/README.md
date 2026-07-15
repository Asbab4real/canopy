# Local HTTPS RPC for `canopy.rpc`

This helper exposes Canopy's HTTP RPC at:

`https://canopy.rpc:8443/v1/eth`

The proxy forwards traffic to the normal local Canopy RPC:

`http://127.0.0.1:50002`

## Setup

1. Add a hosts entry:

   ```text
   127.0.0.1 canopy.rpc
   ```

2. Generate a certificate:

   ```bash
   make dev/https-cert
   ```

   If `mkcert` is installed, the certificate will be locally trusted automatically.
   If `openssl` is used as a fallback, you must trust the generated certificate in your OS trust store.

3. Start the Canopy RPC as usual on `http://127.0.0.1:50002`.

4. Start the HTTPS proxy:

   ```bash
   make run/https-rpc-proxy
   ```

5. Point Binance Wallet at:

   ```text
   https://canopy.rpc:8443/v1/eth
   ```

## Overrides

You can change the listen port or upstream without editing files:

```bash
make run/https-rpc-proxy HTTPS_LISTEN=127.0.0.1:9443 HTTPS_UPSTREAM=http://127.0.0.1:50002
```
