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
    std::ifstream file(filename, std::ios_base::binary);

    /* Check we successfully opened the file */
    if (!file)
    {
        std::cout << "Failed to open file!" << std::endl;
        return false;
    }

    /* Read file into a buffer */
    std::vector<char> buffer((std::istreambuf_iterator<char>(file)),
                             (std::istreambuf_iterator<char>()));

    /* Check that the decrypted data has the 'isAWallet' identifier,
       and remove it it does. If it doesn't, return an error. */
    if (!hasMagicIdentifier(buffer, IS_A_WALLET_IDENTIFIER))
    {
        return false;
    }

    using namespace CryptoPP;

    /* The salt we use for both PBKDF2, and AES decryption */
    byte salt[16];

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
    byte key[16];

    /* Using SHA256 as the algorithm */
    PKCS5_PBKDF2_HMAC<SHA256> pbkdf2;

    /* Generate the AES Key using pbkdf2 */
    pbkdf2.DeriveKey(
        key, sizeof(key), 0, (byte *)password.c_str(),
        password.size(), salt, sizeof(salt), PBKDF2_ITERATIONS
    );

    CBC_Mode<AES>::Decryption cbcDecryption;

    /* Initialize our decrypter with the key and salt/iv */
    cbcDecryption.SetKeyWithIV(key, sizeof(key), salt);

    /* This will store the decrypted data */
    std::string decryptedData;

    try
    {
        /* Decrypt, handling padding */
        StringSource((byte *)buffer.data(), buffer.size(), true, new StreamTransformationFilter(
            cbcDecryption, new StringSink(decryptedData))
        );
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
