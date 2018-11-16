const pbkdf2 = require('pbkdf2');
const fs = require('fs');
const crypto = require('crypto');

const walletFile = "../test.wallet";
const password = "password";

const PBKDF2_ITERATIONS = 500000;

/* We use this to check that the file is a wallet file, this bit does
   not get encrypted, and we can check if it exists before decrypting.
   If it isn't, it's not a wallet file. */
const IS_A_WALLET_IDENTIFIER = Buffer.from([
    0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
    0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
    0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
    0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
    0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
    0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e
]);

/* We use this to check if the file has been correctly decoded, i.e.
   is the password correct. This gets encrypted into the file, and
   then when unencrypted the file should start with this - if it
   doesn't, the password is wrong */
const IS_CORRECT_PASSWORD_IDENTIFIER = Buffer.from([
    0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
    0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
    0x79, 0x6f, 0x75, 0x2e
]);

fs.readFile(walletFile, (err, data) => {
    if (err) {
        throw err;
    }

    /* Take a slice containing the wallet identifier magic bytes */
    const magicBytes1 = data.slice(0, IS_A_WALLET_IDENTIFIER.length);

    if (magicBytes1.compare(IS_A_WALLET_IDENTIFIER) != 0) {
        throw new Error('File is missing wallet identifer magic bytes!');
    }

    /* Remove the magic bytes */
    data = data.slice(IS_A_WALLET_IDENTIFIER.length, data.length);

    /* Grab the salt from the data */
    const salt = data.slice(0, 16);

    /* Remove the salt from the data */
    data = data.slice(salt.length, data.length);

    /* Derive our key with pbkdf2, 16 bytes long */
    const key = pbkdf2.pbkdf2Sync(password, salt, PBKDF2_ITERATIONS, 16, 'sha256');

    /* Setup the aes decryption */
    const decipher = crypto.createDecipheriv('aes-128-cbc', key, salt);

    var decrypted;

    try {
        /* Perform the decryption */
        decrypted = Buffer.concat([decipher.update(data), decipher.final()]);
    } catch (err) {
        throw new Error('Wrong password!');
    }

    /* Grab the second set of magic bytes */
    const magicBytes2 = decrypted.slice(0, IS_CORRECT_PASSWORD_IDENTIFIER.length);

    /* Verify the magic bytes are present */
    if (magicBytes2.compare(IS_CORRECT_PASSWORD_IDENTIFIER) != 0) {
        throw new Error('Wrong password!');
    }

    /* Remove the magic bytes */
    decrypted = decrypted.slice(IS_CORRECT_PASSWORD_IDENTIFIER.length, decrypted.length);

    /* Print out the data */
    console.log(JSON.parse(decrypted));
});
