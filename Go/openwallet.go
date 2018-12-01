package main

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/sha256"
	"io/ioutil"

	"golang.org/x/crypto/pbkdf2"
)

var isAWalletIdentifier = []byte{
	0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
	0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
	0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
	0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
	0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
	0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e}

var isCorrectPasswordIdentifier = []byte{
	0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
	0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
	0x79, 0x6f, 0x75, 0x2e}

const pbkdf2Iterations = 500000

func main() {

	/* Read file into a byte array */
	data, err := ioutil.ReadFile("../test.wallet")
	if err != nil {
		panic(err)
	}

	/* Get the first set of Magic Bytes */
	magicBytes1 := data[:len(isAWalletIdentifier)]

	/* Verify the magic bytes are correct */
	if !bytes.Equal(magicBytes1, isAWalletIdentifier) {
		panic("Data is missing wallet identifier magic bytes!")
	}

	/* Remove the magic bytes */
	data = data[len(isAWalletIdentifier):]

	/* Salt is the next 16 bytes */
	salt := data[:16]

	/* Remove the salt */
	data = data[16:]

	/* Use pbkdf2 to generate the AES key, using the extracted
	   salt - Using SHA256 as the algorithm */
	key := pbkdf2.Key([]byte("password"), salt, pbkdf2Iterations, 16, sha256.New)

	/* Create AES Block with the generated key */
	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err)
	}

	/* Create CBC Cipher with the generated AES block and salt*/
	cbc := cipher.NewCBCDecrypter(block, salt)

	/* Decrypt */
	cbc.CryptBlocks(data, data)

	/* Grab second set of magic bytes*/
	magicBytes2 := data[:len(isCorrectPasswordIdentifier)]

	/* verify the magic bytes are correct */
	if !bytes.Equal(magicBytes2, isCorrectPasswordIdentifier) {
		println("Incorrect password!")
		return
	}

	/* Remove the magic bytes */
	data = data[len(isCorrectPasswordIdentifier):]

	println(string(data))
}
