using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Security.Cryptography;

class OpenWallet
{
    /* We use this to check that the file is a wallet file, this bit does
       not get encrypted, and we can check if it exists before decrypting.
       If it isn't, it's not a wallet file. */
    protected static byte[] isAWalletIdentifier =
    {
        0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
        0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
        0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
        0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
        0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
        0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e
    };

    /* We use this to check if the file has been correctly decoded, i.e.
       is the password correct. This gets encrypted into the file, and
       then when unencrypted the file should start with this - if it
       doesn't, the password is wrong */
    protected static byte[] isCorrectPasswordIdentifier =
    {
        0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
        0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
        0x79, 0x6f, 0x75, 0x2e
    };

    protected const int PBKDF2Iterations = 500000;

    public static void Main()
    {
        Open("../test.wallet", "password");
    }

    static bool Open(string filename, string password)
    {
        if (!File.Exists(filename))
        {
            Console.WriteLine("Failed to open file!");
            return false;
        }

        /* Read file into a byte array */
        byte[] fileData = File.ReadAllBytes(filename);

        /* Check it's got the is a wallet magic bytes */
        if (!HasMagicIdentifier(fileData, isAWalletIdentifier))
        {
            Console.WriteLine("Missing isAWalletIdentifier magic bytes!");
            return false;
        }

        /* Remove identifier, we're done with it */
        fileData = RemoveMagicIdentifier(fileData, isAWalletIdentifier);

        byte[] salt = new byte[16];

        if (fileData.Length < salt.Length)
        {
            Console.WriteLine("Wallet is corrupted, cannot get salt!");
            return false;
        }

        /* Extract salt from input */
        Buffer.BlockCopy(fileData, 0, salt, 0, salt.Length);

        /* Remove the salt from the inputted bytes, we don't need it any
           more */
        fileData = RemoveMagicIdentifier(fileData, salt);

        byte[] decryptedBytes;

        using (var aes = Aes.Create())
        {
            /* Use pbkdf2 to generate the AES key, using the extracted
               salt - Using SHA256 as the algorithm */
            var pbkdf2 = new Rfc2898DeriveBytes(
                password, salt, PBKDF2Iterations, HashAlgorithmName.SHA256
            );

            /* 16 byte key */
            aes.KeySize = 128;

            /* Use the pbkdf2 result as our AES key */
            aes.Key = pbkdf2.GetBytes(aes.KeySize / 8);

            /* 16 byte blocks */
            aes.BlockSize = 128;

            /* CBC mode encryption */
            aes.Mode = CipherMode.CBC;

            /* Use the extracted salt as the IV */
            aes.IV = salt;

            /* Initialize our aes decrypter, using the given Key and IV */
            ICryptoTransform decryptor = aes.CreateDecryptor(aes.Key, aes.IV);

            string decryptedData;

            try
            {
                using (var memoryStream = new MemoryStream(fileData))
                /* Decode the AES encrypted file in a stream */
                using (var cryptoStream = new CryptoStream(
                    memoryStream, decryptor, CryptoStreamMode.Read
                ))
                /* Write the decoded data into the string */
                using (var streamReader = new StreamReader(cryptoStream))
                {
                    decryptedData = streamReader.ReadToEnd();
                }
            }
            /* This exception will be thrown if the data has invalid
               padding, which indicates an incorrect password.
               !! MAKE SURE YOU USE A GENERIC WRONG PASSWORD ERROR HERE !!
               Otherwise, I believe this can be abused to decrypt the
               plaintext by using it as a padding oracle attack. */
            catch (CryptographicException e)
            {
                Console.WriteLine("Invalid password!");
                return false;
            }

            decryptedBytes = Encoding.UTF8.GetBytes(decryptedData);
        }

        /* Check it decoded by verifying the isCorrectPasswordIdentifier
           bytes are present */
        if (!HasMagicIdentifier(decryptedBytes, isCorrectPasswordIdentifier))
        {
            Console.WriteLine("Invalid password!");
            return false;
        }

        /* Remove the magic identifier from the decrypted bytes, we don't
           need it any more */
        decryptedBytes = RemoveMagicIdentifier(decryptedBytes, isCorrectPasswordIdentifier);

        Console.WriteLine("Json data:");
        Console.WriteLine(Encoding.UTF8.GetString(decryptedBytes));

        return true;
    }

    /* Check that a given byte[] has the magicIdentifier as a prefix */
    static bool HasMagicIdentifier(byte[] input, byte[] magicIdentifier)
    {
        /* The input must be at least as long as the magic identifier */
        if (input.Length < magicIdentifier.Length)
        {
            return false;
        }

        /* Each byte in input must match the byte in magicIdentifier,
           whilst we're checking the first magicIdentifier bytes */
        for (int i = 0; i < magicIdentifier.Length; i++)
        {
            if (input[i] != magicIdentifier[i])
            {
                return false;
            }
        }

        return true;
    }

    /* Remove the magicIdentifier prefix from a given byte[] */
    static byte[] RemoveMagicIdentifier(byte[] input, byte[] magicIdentifier)
    {
        return input.Skip(magicIdentifier.Length).ToArray(); 
    }
}
