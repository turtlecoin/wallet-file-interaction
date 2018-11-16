# Opening a wallet file in C++

Simply run `make` to compile an executable, `openwallet`.

It will look for a file `test.wallet` in the parent directory, using the password `password`.

If it works successfully, it should print the JSON data.

If you are having errors opening a wallet under Windows, ensure your CryptoPP has this patch applied: https://github.com/weidai11/cryptopp/issues/649#issuecomment-436129947
