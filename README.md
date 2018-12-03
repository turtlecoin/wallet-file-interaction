# Wallet File Interaction

This document sets out the format of wallet files used by the TurtleCoin software, how to open them, save them, and the format of the JSON contained within them.

Code examples to open wallet files are given in the subdirectories - A few common languages have been included. So far, there are implementations in:

* [C++](https://github.com/turtlecoin/wallet-file-interaction/tree/master/Cpp)
* [C#](https://github.com/turtlecoin/wallet-file-interaction/tree/master/C%23)
* [NodeJS](https://github.com/turtlecoin/wallet-file-interaction/tree/master/NodeJS)
* [Python](https://github.com/turtlecoin/wallet-file-interaction/tree/master/Python)
* [Dart](https://github.com/turtlecoin/wallet-file-interaction/tree/master/Dart)
* [Rust](https://github.com/turtlecoin/wallet-file-interaction/tree/master/Rust)
* [Nim](https://github.com/turtlecoin/wallet-file-interaction/tree/master/Nim)
* [Haskell](https://github.com/turtlecoin/wallet-file-interaction/tree/master/Haskell)
* [Golang](https://github.com/turtlecoin/wallet-file-interaction/tree/master/Go)

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

Below follows an example wallet JSON.

I'll go through most of the fields.

```
{
    /* Object - Contains each individual 'subWallet', along with keys and transctions. */
    "subWallets": {
        /* Boolean - Is the wallet a view only wallet or not. View only wallets will have a privateSpendKey of all zeros. */
        "isViewWallet": false,

        /* [Object] - Stores transactions that have been sent by the user (outgoing), but have not been added to a block yet */
        "lockedTransactions": [
            {
                "blockHeight": 0,
                "fee": 10,
                "hash": "486281aa8fbaa10fc48fc24a9f7ed1d1f7195683b980a22900832c7cb098b790",
                "isCoinbaseTransaction": false,
                "paymentID": "",
                "timestamp": 0,
                "transfers": [
                    {
                        "amount": -133,
                        "publicKey": "0cf52f52dc611ff5d832f0c5c5886efdacd9cebe2b5ed0fa9078372ecf7f4508"
                    }
                ],
                "unlockTime": 0
            }
        ],

        /* String - 64 char hex string that represents the shared, private view key */
        "privateViewKey": "8e5cd4ee272df7ad3a0c9f661d7b0fee1ec91efee96a3f449921beeb9c2d3400",

        /* [String] - Stores the public spend keys of the subwallets. Each are 64 char hex strings. */
        "publicSpendKeys": [
            "0cf52f52dc611ff5d832f0c5c5886efdacd9cebe2b5ed0fa9078372ecf7f4508"
        ],

        /* [Object] - An array of subwallets. Contains keys, transaction inputs, etc */
        "subWallet": [
            {
                /* String - This subwallets address */
                "address": "TRTLuwor1VsdrxTb6noiLLa3KPN4dnZSm8FkKqK43hyXbhyyHVWin2j13ktgSVDxyc6KiCpZwtjLYNUJyWEhxuhpNFzm6cXSoxi",

                /* Boolean - Is this subwallet the 'primary' subwallet? This is usually the first one created, and is used for sending change to when not specified */
                "isPrimaryAddress": true,

                /* [Object] - Inputs which have been spent in an outgoing transaction, but not added to a block yet */
                "lockedInputs": [
                    {
                        "amount": 300,
                        "blockHeight": 1026208,
                        "globalOutputIndex": 1304817,
                        "key": "97a3bc4e9a9094e3baa6dbff0146e7872d311ce3e11012c930d12b541f90246f",
                        "keyImage": "be7c949b2335ff9d604b0bc1aaad8280aa081ae69085bf5fbf2ed60ab147dd7b",
                        "parentTransactionHash": "87373e7bef5171c1601528891062796397d4843b74ce771133dd267756aabad3",
                        "spendHeight": 0,
                        "transactionIndex": 4,
                        "transactionPublicKey": "80b4334b6c172a4b45f070cb1132ae7ffa693b57799c2ab74c3dcf1362a451f9",
                        "unlockTime": 0
                    }
                ],
                /* String - 64 char hex string that represents this subwallets private spend key (Will be all zeros if view only wallet) */
                "privateSpendKey": "a76e7b6f492eacc1598364aab2af339f2f9ba83a780f941672331fcb05be900e",

                /* String - 64 char hex string that represents this subwallets public spend key (Duplicated in publicSpendKeys above) */
                "publicSpendKey": "0cf52f52dc611ff5d832f0c5c5886efdacd9cebe2b5ed0fa9078372ecf7f4508",

                /* [Object] - Inputs which have been spent in an outgoing transaction */
                "spentInputs": [
                    {
                        "amount": 4,
                        "blockHeight": 1026192,
                        "globalOutputIndex": 217339,
                        "key": "9af8339e1596b99fdd7936da2d6396681bdbcd4a82c3c11b5e240d6e648cce83",
                        "keyImage": "0e125ef0192eaf998191e8677b0f7288a48b8a06cec8bb6bf06a0e233ddf0be3",
                        "parentTransactionHash": "bbacdf17dc9ec2ba31fe526b1cf7e0adaa773e25614b047476b8f0d0f1153623",
                        "spendHeight": 1026208,
                        "transactionIndex": 0,
                        "transactionPublicKey": "a7d34469def42b589e5e6157482663f1fed64b3aebd950fe5518ac50be53aa04",
                        "unlockTime": 0
                    },
                    {
                        "amount": 30,
                        "blockHeight": 1026192,
                        "globalOutputIndex": 261605,
                        "key": "d6876a3b391fd3e763155bcd9418078961f55cdcae0b148893036d2320cd7e41",
                        "keyImage": "4839e4bfded513c746a15bd9fd50e69ae0d436385b721394473c52abda494876",
                        "parentTransactionHash": "bbacdf17dc9ec2ba31fe526b1cf7e0adaa773e25614b047476b8f0d0f1153623",
                        "spendHeight": 1026208,
                        "transactionIndex": 2,
                        "transactionPublicKey": "a7d34469def42b589e5e6157482663f1fed64b3aebd950fe5518ac50be53aa04",
                        "unlockTime": 0
                    },
                    {
                        "amount": 1000,
                        "blockHeight": 1026192,
                        "globalOutputIndex": 1688414,
                        "key": "f72e237102f90dbb4ae26e22da7ac77d78fd17bbe2f71a5bcb2a5e5dfd70efdb",
                        "keyImage": "87f95951d8c8676b91b2067469a3eb30abf1c1a11a072a79bf36bbe8ee2be4a0",
                        "parentTransactionHash": "bbacdf17dc9ec2ba31fe526b1cf7e0adaa773e25614b047476b8f0d0f1153623",
                        "spendHeight": 1026208,
                        "transactionIndex": 6,
                        "transactionPublicKey": "a7d34469def42b589e5e6157482663f1fed64b3aebd950fe5518ac50be53aa04",
                        "unlockTime": 0
                    }
                ],
                /* Number - The height to begin requesting blocks from. Ignored if syncStartTimestamp != 0 */
                "syncStartHeight": 0,
                
                /* Number - The timestamp to begin request blocks from. Ignored if syncStartHeight != 0 */
                "syncStartTimestamp": 1543790137,

                /* [Object] - The amounts and keys of incoming amounts, these are transactions we have sent that come back as change */
                "unconfirmedIncomingAmounts": [
                    {
                        /* Number - The value of this incoming amount */
                        "amount": 7,

                        /* String - The key the corresponding input has. This can be used to remove this entry when the full input gets confirmed */
                        "key": "944fdc89bd4ae50f8435e89016dcd078c6e664f2257aa0fb92947b7f86437bcc",

                        /* String - The transaction hash that contains this input */
                        "parentTransactionHash": "486281aa8fbaa10fc48fc24a9f7ed1d1f7195683b980a22900832c7cb098b790"
                    },
                    {
                        "amount": 60,
                        "key": "5492bef296dd602b90cbb1348bef4492faee7ea98dd35717f1631b1ad9d68b0b",
                        "parentTransactionHash": "486281aa8fbaa10fc48fc24a9f7ed1d1f7195683b980a22900832c7cb098b790"
                    },
                    {
                        "amount": 100,
                        "key": "c9cd332cfc3e6f5f1a4a82e8bca96be001e0acafc5bee465c55df1246fc40034",
                        "parentTransactionHash": "486281aa8fbaa10fc48fc24a9f7ed1d1f7195683b980a22900832c7cb098b790"
                    }
                ],
                
                /* [Object] - Inputs which have not been spent */
                "unspentInputs": [
                    {
                        /* Number - The value of this input, in atomic units */
                        "amount": 200,

                        /* Number - The block height this input was received at */
                        "blockHeight": 1026192,

                        /* Number - The index of this input in the global database */
                        "globalOutputIndex": 1326110,

                        /* String - The key of this input */
                        "key": "32490c3654ba12894dc98cc9a915f95d5da7af73be9d315a17fbb3b7fce4c42d",

                        /* String - The key image of this input */ 
                        "keyImage": "047fa9c5e10729e0ea1572c64e45622fc60f13374b687dd49650d4e83de68a17",

                        /* String - The transaction hash this input was received in */
                        "parentTransactionHash": "bbacdf17dc9ec2ba31fe526b1cf7e0adaa773e25614b047476b8f0d0f1153623",

                        /* Number - The height this input was spent at (0 if unspent) */
                        "spendHeight": 0,

                        /* Number - The index of this input in the transaction it was received in */
                        "transactionIndex": 4,

                        /* String - The public key of the transaction this input was received in */
                        "transactionPublicKey": "a7d34469def42b589e5e6157482663f1fed64b3aebd950fe5518ac50be53aa04",

                        /* Number - The time this input unlocks at. If >= 500000000, treated as a timestamp. Else, treated as a block height. Cannot be spent till unlocked. */
                        "unlockTime": 0
                    },
                    {
                        "amount": 6,
                        "blockHeight": 1026208,
                        "globalOutputIndex": 216317,
                        "key": "6f30143575d7b221cf2ae1b5f685d8aaa3bd50bcead22939e9ff979aca96f87b",
                        "keyImage": "4ce0aa71e59d457646399ef4ff430c15f6ecb4576e440dc95f633ceadd12a774",
                        "parentTransactionHash": "87373e7bef5171c1601528891062796397d4843b74ce771133dd267756aabad3",
                        "spendHeight": 0,
                        "transactionIndex": 0,
                        "transactionPublicKey": "80b4334b6c172a4b45f070cb1132ae7ffa693b57799c2ab74c3dcf1362a451f9",
                        "unlockTime": 0
                    },
                    {
                        "amount": 40,
                        "blockHeight": 1026208,
                        "globalOutputIndex": 264830,
                        "key": "fd709eee186ecedf7988429bc742e2ceea0b9152c434157d58f7bf842f7369f5",
                        "keyImage": "30ef3d364a62887e54870c94ad0bd787c7fbd89783f8578a75d71f143978c893",
                        "parentTransactionHash": "87373e7bef5171c1601528891062796397d4843b74ce771133dd267756aabad3",
                        "spendHeight": 0,
                        "transactionIndex": 2,
                        "transactionPublicKey": "80b4334b6c172a4b45f070cb1132ae7ffa693b57799c2ab74c3dcf1362a451f9",
                        "unlockTime": 0
                    }
                ]
            }
        ],
        /* [Object] - Any transactions which are in a block */
        "transactions": [
            {
                /* Number - The block height this transaction was included in */
                "blockHeight": 1026192,

                /* Number - The fee used on this transaction (in atomic units) */
                "fee": 10,

                /* String - The hash of this transaction */
                "hash": "bbacdf17dc9ec2ba31fe526b1cf7e0adaa773e25614b047476b8f0d0f1153623",

                /* Boolean - Is this transaction a 'coinbase'/miner reward transaction */
                "isCoinbaseTransaction": false,

                /* String - The payment ID used in this transaction (may be the empty string) */
                "paymentID": "7fe73bd90ef05dea0b5c15fc78696619c50dd5f2ba628f2fd16a2e3445b1922f",

                /* Number - The timestamp of the block this transaction was included in (unix style) */
                "timestamp": 1543797411,

                /* [Object] - The amounts and destinations of the transaction. Amounts can be positive and negative if sending from one container address to another. */
                "transfers": [
                    {
                        "amount": 1234,
                        "publicKey": "0cf52f52dc611ff5d832f0c5c5886efdacd9cebe2b5ed0fa9078372ecf7f4508"
                    }
                ],

                /* Number - The time this transaction unlocks at. If >= 500000000, treated as a timestamp. Else, treated as a block height. Cannot be spent till unlocked. */
                "unlockTime": 0
            },
            {
                "blockHeight": 1026208,
                "fee": 10,
                "hash": "87373e7bef5171c1601528891062796397d4843b74ce771133dd267756aabad3",
                "isCoinbaseTransaction": false,
                "paymentID": "2a2d91e6b6cc4aecd3c0411bfae3088771a50d3fa2e91e3acf07301dfa718692",
                "timestamp": 1543797955,
                "transfers": [
                    {
                        "amount": -688,
                        "publicKey": "0cf52f52dc611ff5d832f0c5c5886efdacd9cebe2b5ed0fa9078372ecf7f4508"
                    }
                ],
                "unlockTime": 0
            }
        ],
        /* [Object] - Private keys of transactions sent by this container, and the hash they belong to. Can be used for auditing transactions */
        "txPrivateKeys": [
            {
                /* String - The hash of the transaction this key belongs to */
                "transactionHash": "486281aa8fbaa10fc48fc24a9f7ed1d1f7195683b980a22900832c7cb098b790",

                /* String - The private key of this transaction */
                "txPrivateKey": "815bbfbc835b096c79a1d0aa83f5d8c25808fe29cf51d50470853b3cea05d409"
            },
            {
                "transactionHash": "87373e7bef5171c1601528891062796397d4843b74ce771133dd267756aabad3",
                "txPrivateKey": "02085cb6c2312c01584487c88a51feb91d7617a30f4179eb86eefa261642ac0c"
            }
        ]
    },
    /* Number - The format of the wallet file. May change in the future. */
    "walletFileFormatVersion": 0,

    /* Object - Data used to help store the wallet synchronization state */
    "walletSynchronizer": {

        /* String - The private view key used to decrypt transactions */
        "privateViewKey": "8e5cd4ee272df7ad3a0c9f661d7b0fee1ec91efee96a3f449921beeb9c2d3400",

        /* Number - The height to begin requesting blocks from. Ignored if syncStartTimestamp != 0 */
        "startHeight": 0,

        /* Number - The timestamp to begin request blocks from. Ignored if syncStartHeight != 0 */
        "startTimestamp": 1543790137,

        /* Object - The synchronization status of transactions */
        "transactionSynchronizerStatus": {

            /* [String] - Block hash checkpoints taken by default every 5k blocks. Useful for if a very deep fork occurs. */
            "blockHashCheckpoints": [],

            /* [String] - Block hash checkpoints of the last (up to) 100 blocks. The first hashes are the newer ones. */
            "lastKnownBlockHashes": [
                "a049238bbd33d0c8af2362af7813e8439093471d5bc871aa0821640480d7bd2d",
                "be9755e48bf9b9ff5211fc7a077f02f8197158470dd72cef2200f5dd516abfcf",
                "16e7869b799af072e7330d00fa8b1a81262bdc8672818647ec559e2b21da7aeb",
                "0f04401a542325047bf86b20cba4d6313abab7d3816a01146b9c50105844ddb6",
                "42bc0a8a8eb28347965fe53c642e3feb0a06b02702e56cbf8c329e5def581f78",
                "0344eb16d3614d631f8e1226990a968a9334deb45df4afc2997bf8819680cfee",
                "231d679287bd2fe6af3473ca56ded91cfe637bbe993743323368574814faa83c",
                "97896aa73a5f3fe275334f5215f3089989d0286ff4fcb208df79d42045b238a2",
                "753102353d43d1e5218dfddf9745f92475cc0ddbd419d78bd11ac7cb31ba161d",
                "0197d85f75ae5aa320840298f8c697e5bf030d3b78fc86f7de690f393ca7fc4f",
                "99537c0d72883402f69331450a420d3bb4d5b39515cab3abbf05f8ac661a3c9c",
                "231e8997ecc7ac07244dc3db7c929de1e0f69c597826200af735ce9a85f034d5",
                "c84354ccbbe47af023d12b0f039253bc9d13de27bc6ff61855168f9f6ee6d08b",
                "0df2244fa47d3da4c85c0cdc64c633f3653df57883b1096dc84989a59cca5978",
                "2465b6b468eacdcfd5e6fe9c61c9feb505973691a1e4d37da666112ca965b4f8",
                "4bc277ef0a218b0a8228957569e5f11d11eb5b41a7d3f7995792b03450c827a5",
                "1e037d73adeebfc05900cb884c8f71398f890118f5155470331c2763da485288",
                "415c3213879802c28564754b52cef74ba88677b8ab6c344ba833247bb24d61d6",
                "c5ebd53d962a50ef5db613a233974907946ad20035310cef098454fcb9ecad9f",
                "057070d23b353c2a2e10c0fe0cbeb903c48f40313c110663c38aa71982841ba7",
                "1eb5dd11e4656e179f2704bc6a79cf4e4a9ee893f90ed0a993c39c944bffc04a",
                "b5c1b4848a7809a50ac9a6d6296a842e1cf0cd97a05e5b79ce12536076ce7de2",
                "6f2b1e3ac79ea036afa9d96b52acdeed6dfa2c601d684fcaa695cd5b13bc20c5",
                "af507557cf0a09f027df357e2d806f621c8cb180abeec0af06c67e3714d95995",
                "1f8629d36609d58e1912d47011c9fdb98ca956be3eb466f4237fc8bec8310534",
                "cbd3762c758bd49d819a156ee2570004fd7e76d6bcb5782d8ce2740367bedbb8",
                "368a6ea67d63edebd835b9d22a2c3b827457ef4d4630c6f743ecdf31eb522e72"
            ],

            /* Number - The last block we scanned */
            "lastKnownBlockHeight": 1026216
        }
    }
}
```
