extern crate openssl;

use openssl::hash::MessageDigest;
use openssl::pkcs5::pbkdf2_hmac;
use openssl::symm::{decrypt, Cipher};
use std::fs::File;
use std::io::{BufReader, Read};

// We use this to check that the file is a wallet file, this bit does not get encrypted
// and we can check if it exists before decrypting. If it isn't, it's not a wallet file.
const IS_A_WALLET_IDENTIFIER: [u8; 64] = [
    0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74, 0x68, 0x61, 0x74, 0x20, 0x6f,
    0x66, 0x66, 0x2c, 0x20, 0x77, 0x69, 0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65,
    0x3f, 0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62, 0x65, 0x20, 0x65, 0x78,
    0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79, 0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e,
];

// We use this to check if the file has been correctly decoded, i.e.is the password correct.
// This gets encrypted into the file, and then when unencrypted the file should start with this
// if it doesn't, the password is wrong
const IS_CORRECT_PASSWORD_IDENTIFIER: [u8; 26] = [
    0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69, 0x67, 0x20, 0x67, 0x75, 0x79,
    0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20, 0x79, 0x6f, 0x75, 0x2e,
];

// The number of iterations of PBKDF2 to perform on the wallet password.
const PBKDF2_ITERATIONS: usize = 500000;

type Credential = [u8; 16];

fn read_some<R>(reader: R, bytes_size: u64) -> Vec<u8>
where
    R: Read,
{
    let mut buf = vec![];
    let mut chunk = reader.take(bytes_size);
    let n = chunk
        .read_to_end(&mut buf)
        .expect("Data is too small for identifier!");
    assert_eq!(bytes_size as usize, n);
    buf
}

fn main() {
    open_wallet("../test.wallet".to_string(), "password".to_string()).unwrap();
}

fn open_wallet(filename: String, password: String) -> std::io::Result<()> {
    // Open the file and put into a read buffer
    let f = File::open(filename).expect("Failed to open file!");
    let mut buffer = BufReader::new(&f);

    // Take out wallet identifier portion from the buffer
    let wallet_id = read_some(&mut buffer, IS_A_WALLET_IDENTIFIER.len() as u64);
    if IS_A_WALLET_IDENTIFIER.ne(&*wallet_id) {
        panic!("Magic identifier is incorrect!");
    }

    // Take out salt portion from the buffer
    let iv = read_some(&mut buffer, 16);

    // Take leftover encrypted bytes to be decrypted
    let mut encrypted_data = Vec::new();
    buffer.read_to_end(&mut encrypted_data)?;

    // Derive our key with pbkdf2, 16 bytes long
    let mut key: Credential = [0u8; 16];
    let digest_alg = MessageDigest::sha256();
    pbkdf2_hmac(
        password.as_bytes(),
        &*iv,
        PBKDF2_ITERATIONS,
        digest_alg,
        &mut key,
    ).expect("Key derivation failed!");

    // Perform decryption, override any Error with generic wrong pass message
    let cipher = Cipher::aes_128_cbc();
    let mut decrypted = match decrypt(cipher, &key, Some(&*iv), &*encrypted_data) {
        Ok(res) => res,
        Err(_) => panic!("Wrong password"),
    };

    // Take out & verify the password identifier
    let bytes_range = std::ops::Range {
        start: 0,
        end: IS_CORRECT_PASSWORD_IDENTIFIER.len(),
    };
    let password_id: Vec<_> = decrypted.drain(bytes_range).collect();
    assert_eq!(IS_CORRECT_PASSWORD_IDENTIFIER, &*password_id);

    // Print out the data
    println!("{}", std::str::from_utf8(&decrypted).unwrap());

    Ok(())
}
