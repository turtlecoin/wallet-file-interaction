# Opening a wallet file in Python

Just run `python openwallet.py`. Requires python 3, so try `python3` if python2 is default.

It will look for a file `test.wallet` in the parent directory, using the password `password`.

If it works successfully, it should print the JSON data.

Python is unique in that you have to manually unpad the AES decrypted data, which is a little ugly, but only one extra line.
