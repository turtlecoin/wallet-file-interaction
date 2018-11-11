#include "openwallet.h"

#include <fstream>

#include <iostream>

#include <iterator>

#include <string>

#include <cryptopp/aes.h>
#include <cryptopp/algparam.h>
#include <cryptopp/filters.h>
#include <cryptopp/modes.h>
#include <cryptopp/sha.h>
#include <cryptopp/pwdbased.h>

int main()
{
    openWallet("../test.wallet", "password");
}

bool openWallet(const std::string filename, const std::string password)
{
    /* Open in binary mode, since we have encrypted data */
    std::ifstream file(filename, std::ios::binary);

    /* Stop eating white space in binary mode!!! :(((( */
    file.unsetf(std::ios::skipws);

    /* Check we successfully opened the file */
    if (!file)
    {
        std::cout << "Failed to open file!" << std::endl;
        return false;
    }
    /* Read file into a buffer */
    std::vector<unsigned char> buffer((std::istream_iterator<unsigned char>(file)),
                                      (std::istream_iterator<unsigned char>()));

    /* Check that the decrypted data has the 'isAWallet' identifier,
       and remove it it does. If it doesn't, return an error. */
    if (!hasMagicIdentifier(buffer, IS_A_WALLET_IDENTIFIER))
    {
        return false;
    }

    /* The salt we use for both PBKDF2, and AES decryption */
    CryptoPP::byte salt[16];

    /* Check the file is large enough for the salt */
    if (buffer.size() < sizeof(salt))
    {
        std::cout << "Buffer is not large enough to read salt from!" << std::endl;
        return false;
    }

    /* Copy the salt to the salt array */
    std::copy(buffer.begin(), buffer.begin() + sizeof(salt), salt);

    /* Remove the salt, don't need it anymore */
    buffer.erase(buffer.begin(), buffer.begin() + sizeof(salt));

    /* The key we use for AES decryption, generated with PBKDF2 */
    CryptoPP::byte key[16];

    /* Using SHA256 as the algorithm */
    CryptoPP::PKCS5_PBKDF2_HMAC<CryptoPP::SHA256> pbkdf2;

    /* Generate the AES Key using pbkdf2 */
    pbkdf2.DeriveKey(
        key, sizeof(key), 0, (CryptoPP::byte *)password.data(),
        password.size(), salt, sizeof(salt), PBKDF2_ITERATIONS
    );

    /* Intialize aesDecryption with the AES Key */
    CryptoPP::AES::Decryption aesDecryption(key, sizeof(key));

    /* Using CBC encryption, pass in the salt */
    CryptoPP::CBC_Mode_ExternalCipher::Decryption cbcDecryption(
        aesDecryption, salt
    );

    /* This will store the decrypted data */
    std::string decryptedData;

    /* Stream the decrypted data into the decryptedData string */
    try
    {
        CryptoPP::StreamTransformationFilter stfDecryptor(
            cbcDecryption, new CryptoPP::StringSink(decryptedData)
        );

        /* Write the data to the AES decryptor stream */
        stfDecryptor.Put(reinterpret_cast<const CryptoPP::byte *>(buffer.data()),
                         buffer.size());

        stfDecryptor.MessageEnd();
    }
    /* do NOT report an alternate error for invalid padding. It allows them
       to do a padding oracle attack, I believe. Just report the wrong password
       error. */
    catch (const CryptoPP::Exception &)
    {
        std::cout << "Wrong password" << std::endl;
        return false;
    }

    /* Check that the decrypted data has the 'isCorrectPassword' identifier,
       and remove it it does. If it doesn't, return an error. */
    if (!hasMagicIdentifier(decryptedData, IS_CORRECT_PASSWORD_IDENTIFIER))
    {
        return false;
    }

    std::cout << "JSON data:\n" << decryptedData << std::endl;

    return true;
}
