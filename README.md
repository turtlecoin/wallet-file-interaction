# Wallet File Interaction

This document sets out the format of wallet files used by the TurtleCoin software, how to open them, save them, and the format of the JSON contained within them.

Code examples to open wallet files are given in the subdirectories - A few common languages have been included. So far, there are implementations in:

* [C++](https://github.com/turtlecoin/wallet-file-interaction/tree/master/cpp)
* [C#](https://github.com/turtlecoin/wallet-file-interaction/tree/master/C%23)

If you implement opening a wallet in your language of choice, please send a pull request to help out other users!

Note that this document only applies to wallets using 'WalletBackend', not wallets using 'WalletGreen'.

For your convenience, a brand new, empty wallet is included - [test.wallet](test.wallet). It is using the password, `password`.

## Opening a wallet file

![A visual representation of a wallet file](highlevel.png)

Start by loading the wallet file into a byte / unsigned char array.

Next, you need to verify that this file is a wallet file.

If it is a wallet file, it will begin with the following 'Is A Wallet File' identifier:

```
0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e
```

If these bytes are not present, the wallet file is not valid.

If they are present, remove them from the data you are processing, and continue.

Next, we need to read in the *salt*. The *salt* is 16 random bytes that are generated on each save, to prevent multiple saves with the same password leaking data.

Simply read in the following 16 bytes into a salt array.

Remove them from the data you are processing, and continue.

Now we need to hash the wallet password, which the user should have provided you.

Start by hashing the password with *PBKDF2*, also known as *RFC2898*. We use *500,000* iterations of PBKDF2, using the SHA256 algorithm, and the salt we extracted earlier.

Once you have got the hashed password, we can use this as the AES key to decrypt the data.

The AES parameters are as follows:

* AES key size - 16 bytes / 128 bits
* AES block size - 16 bytes / 128 bits
* AES Mode - CBC
* AES padding Mode - PKCS#7 (Also known as RFC 5652)

For the AES *key*, we use the first 16 bytes of the hashed password.
For the AES *IV*, we use the same *salt* we used earlier.

Apply the AES decryption with the given parameters to the data.

Note that if the wrong password is supplied, it is likely your AES decryption will throw, with an error about 'Invalid padding'. This is expected.

It is possible an 'Invalid padding' error is not thrown, with an invalid password, occasionaly. For this we have an additional magic identifier we can check the presence of.

The unencrypted data should now begin with the following 'Is Correct Password' identifier:

```
0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
0x79, 0x6f, 0x75, 0x2e
```

If it does, remove this identifier, and you should be left with the JSON data.

If it does not, the password is incorrect.

## Saving a wallet file

To save a wallet file, we essentially do the same process as detailed above, in reverse.

Convert any data you store to the JSON format we will detail later. Prepend the 'Is Correct Password' identifier to this.

Generate 16 random bytes, which will be used for the *salt*.

Hash the users password with *PBKDF2*, using the same parameters as before, and the *salt* you just generated. Make sure to generate a new *salt* on each save.

Next, encrypt the identifer + JSON data with AES. The AES parameters are exactly the same as before, again using the *salt* we just generated, and the hashed password.

Write the 'Is A Wallet' identifier to the file. Then, write the salt to the file. Finally, write the encrypted JSON to the file.

## The JSON Schema

TODO

Below follows an example wallet JSON.

```json
{
    "subWallets": {
        "isViewWallet": false,
        "lockedTransactions": [],
        "privateViewKey": "a12fb5354388565c6967933a64a5e9a07566629b9beb077f20ca7f37b4abdc06",
        "publicSpendKeys": [
            "805d665df31f9e09ce136bbcb2be26f567ea9fb803d5dcaabf28183b2e3aeaa7"
        ],
        "subWallet": [
            {
                "address": "TRTLuzkwbBJhfbwyeU1KsHWu2gBGMzwew1eD5HBBFSp28jVSMx81nX1UhFyJmw8QmBconoEw4qT26Xnsj1KBB3wY6pxDoKpdy7A",
                "isPrimaryAddress": true,
                "lockedInputs": [],
                "privateSpendKey": "da5d5d7135cc0315e8bef28fe9ea9aad641ecbc7303e9a2aa2b3ac8afdfdc800",
                "publicSpendKey": "805d665df31f9e09ce136bbcb2be26f567ea9fb803d5dcaabf28183b2e3aeaa7",
                "spentInputs": [],
                "syncStartHeight": 0,
                "syncStartTimestamp": 1541973731,
                "unspentInputs": [
                    {
                        "amount": 1,
                        "blockHeight": 965863,
                        "globalOutputIndex": 927274,
                        "key": "97d5c998bcf73a0e05dc91600c9dc0bb1d8a5de8f4474c2184426ecad9641efe",
                        "keyImage": "521aa5d09c675071f7d1a5e527b20395970cc63b9f0f1424659a3ee375bff764",
                        "parentTransactionHash": "ddc1bd59d5007d2b897be91c34bcfe69702f8aa0d6393b677685b53a625f3e98",
                        "spendHeight": 0,
                        "transactionIndex": 0,
                        "transactionPublicKey": "ff45191c075d4e5fda81c448c1f4ae87bfab0d9a9c6524aaa3c9c07a6b5b81d7",
                        "unlockTime": 0
                    },
                    {
                        "amount": 10,
                        "blockHeight": 965863,
                        "globalOutputIndex": 257617,
                        "key": "98e11c96032d5aeb76fcf9b02031dec7eecc99219aa74d74e559936733d3c975",
                        "keyImage": "d2972106cafac882e5416028490d508d43afcb15601239b718467949032d1b63",
                        "parentTransactionHash": "ddc1bd59d5007d2b897be91c34bcfe69702f8aa0d6393b677685b53a625f3e98",
                        "spendHeight": 0,
                        "transactionIndex": 2,
                        "transactionPublicKey": "ff45191c075d4e5fda81c448c1f4ae87bfab0d9a9c6524aaa3c9c07a6b5b81d7",
                        "unlockTime": 0
                    },
                    {
                        "amount": 100,
                        "blockHeight": 965863,
                        "globalOutputIndex": 1450184,
                        "key": "cab2f40bff4520361da46f2795bed0a14b03d8ef6a8c279836c7bce6301977ba",
                        "keyImage": "5ed476e983be8e1c72164ab6e7e476240aad19a8bc7d10551044b54422dbc1fe",
                        "parentTransactionHash": "ddc1bd59d5007d2b897be91c34bcfe69702f8aa0d6393b677685b53a625f3e98",
                        "spendHeight": 0,
                        "transactionIndex": 4,
                        "transactionPublicKey": "ff45191c075d4e5fda81c448c1f4ae87bfab0d9a9c6524aaa3c9c07a6b5b81d7",
                        "unlockTime": 0
                    },
                    {
                        "amount": 1000,
                        "blockHeight": 965863,
                        "globalOutputIndex": 1584222,
                        "key": "241c0b9e0996ed826a02a0eee55897cd52282a9a778bd91120de7788d6044df5",
                        "keyImage": "4cc59c3b8a5e9c62515dd65c1bc423c0eab4321e83a4ce3b86c19d81e0636bf5",
                        "parentTransactionHash": "ddc1bd59d5007d2b897be91c34bcfe69702f8aa0d6393b677685b53a625f3e98",
                        "spendHeight": 0,
                        "transactionIndex": 6,
                        "transactionPublicKey": "ff45191c075d4e5fda81c448c1f4ae87bfab0d9a9c6524aaa3c9c07a6b5b81d7",
                        "unlockTime": 0
                    }
                ]
            }
        ],
        "transactions": [
            {
                "blockHeight": 965863,
                "fee": 10,
                "hash": "ddc1bd59d5007d2b897be91c34bcfe69702f8aa0d6393b677685b53a625f3e98",
                "isCoinbaseTransaction": false,
                "paymentID": "7fe73bd90ef05dea0b5c15fc78696619c50dd5f2ba628f2fd16a2e3445b1922f",
                "timestamp": 1541980957,
                "transfers": [
                    {
                        "amount": 1111,
                        "publicKey": "805d665df31f9e09ce136bbcb2be26f567ea9fb803d5dcaabf28183b2e3aeaa7"
                    }
                ],
                "unlockTime": 0
            }
        ]
    },
    "walletFileFormatVersion": 0,
    "walletSynchronizer": {
        "privateViewKey": "a12fb5354388565c6967933a64a5e9a07566629b9beb077f20ca7f37b4abdc06",
        "startHeight": 0,
        "startTimestamp": 1541973731,
        "transactionSynchronizerStatus": {
            "blockHashCheckpoints": [
                "bfee487de34f1640d72075a8a582407c8cff32fbe26455cd7ddb756ac4dfffa4"
            ],
            "lastKnownBlockHashes": [
                "dadf6e1a5d789948448c3b252bfaeff6bc38c7e7e8c91125a9471792399e076e",
                "d2ece1b159c3132fda6bfc618ee31cb46b0ad8a479f02d486d6f650f7cd7e27e",
            ],
            "lastKnownBlockHeight": 965868
        }
    }
}
```
