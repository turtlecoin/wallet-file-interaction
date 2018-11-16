# Opening a wallet file in Nim

Install dependencies: `nimble install nimcrypto hmac`

Compile and run: `nim compile -d:release --run openwallet.nim`

It will look for a file `test.wallet` in the parent directory, using the password `password`.

If it works successfully, it should print the JSON data.
