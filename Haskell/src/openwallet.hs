import Data.Word
import Data.Maybe (fromJust, fromMaybe)

import qualified Data.ByteString as B (ByteString, readFile, pack, length, take, drop)
import qualified Data.ByteString.Char8 as C8 (pack, unpack)

import Crypto.KDF.PBKDF2 (Parameters(..), fastPBKDF2_SHA256)
import Crypto.Cipher.AES (AES128)
import Crypto.Error (throwCryptoError)
import Crypto.Cipher.Types (cipherInit, cbcDecrypt, makeIV)
import Crypto.Data.Padding (Format(..), unpad)

isAWalletIdentifier :: B.ByteString
isAWalletIdentifier = B.pack [
    0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
    0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
    0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
    0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
    0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
    0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e]

isCorrectPasswordIdentifier :: B.ByteString
isCorrectPasswordIdentifier = B.pack [
    0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
    0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
    0x79, 0x6f, 0x75, 0x2e]

pbkdf2Iterations = 500000

main :: IO ()
main = putStrLn . extractJSON =<< (B.readFile "../test.wallet")

-- Check the given magic bytes are present (and we have enough space for them)
hasMagicBytes :: B.ByteString -> B.ByteString -> Bool
hasMagicBytes input magicBytes
    | B.length magicBytes > B.length input = False
    | otherwise = magicBytes == B.take (B.length magicBytes) input

removeIsAWalletID :: B.ByteString -> B.ByteString
removeIsAWalletID = removeIdentifier isAWalletIdentifier "Missing wallet identifier magic bytes!"

removeCorrectPasswordID :: B.ByteString -> B.ByteString
removeCorrectPasswordID = removeIdentifier isCorrectPasswordIdentifier "Wrong password!"

-- Remove the magic bytes, if present. Else error.
removeIdentifier :: B.ByteString -> String -> B.ByteString -> B.ByteString
removeIdentifier identifier errorMsg input
    | not (hasMagicBytes input identifier) = error errorMsg
    | otherwise = B.drop (B.length identifier) input

extractJSON :: B.ByteString -> String
extractJSON input = C8.unpack $ removeCorrectPasswordID $ decrypt salt encryptedData
    where idRemoved = removeIsAWalletID input
          salt = B.take 16 idRemoved
          encryptedData = B.drop (B.length salt) idRemoved

decrypt :: B.ByteString -> B.ByteString -> B.ByteString
decrypt salt encryptedData = fromMaybe (error "Wrong password!") (unpad (PKCS7 16) $ decrypted)
    -- hash our password with pbkdf2
    where key = fastPBKDF2_SHA256 (Parameters pbkdf2Iterations 16) (C8.pack "password") salt :: B.ByteString
          ctx = throwCryptoError $ cipherInit key :: AES128
          decrypted = cbcDecrypt ctx (fromJust $ makeIV salt) encryptedData
