#include <array>

#include <iostream>

#include <string>

bool openWallet(const std::string filename, const std::string password);

/* We use this to check that the file is a wallet file, this bit does
   not get encrypted, and we can check if it exists before decrypting.
   If it isn't, it's not a wallet file. */
const std::array<unsigned char, 64> IS_A_WALLET_IDENTIFIER =
{{
    0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
    0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
    0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
    0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
    0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
    0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e
}};

/* We use this to check if the file has been correctly decoded, i.e.
   is the password correct. This gets encrypted into the file, and
   then when unencrypted the file should start with this - if it
   doesn't, the password is wrong */
const std::array<unsigned char, 26> IS_CORRECT_PASSWORD_IDENTIFIER =
{{
    0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
    0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
    0x79, 0x6f, 0x75, 0x2e
}};

/* The number of iterations of PBKDF2 to perform on the wallet
   password. */
const uint64_t PBKDF2_ITERATIONS = 500000;

/* Check data has the magic indicator from first : last, and remove it if
   it does. */
template <class Buffer, class Identifier>
bool hasMagicIdentifier(Buffer &data, const Identifier &identifier)
{
    /* Check we've got space for the identifier */
    if (data.size() < identifier.size())
    {
        std::cout << "Data is too small for identifier!" << std::endl;
        return false;
    }

    if (!std::equal(identifier.begin(), identifier.end(), data.begin()))
    {
        std::cout << "Magic identifier is incorrect!" << std::endl;
        return false;
    }

    /* Remove the identifier from the string */
    data.erase(data.begin(), data.begin() + identifier.size());

    return true;
}
