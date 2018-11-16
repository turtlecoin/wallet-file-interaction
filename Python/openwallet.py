from pathlib import Path
from Crypto.Cipher import AES
import hashlib

IS_A_WALLET_IDENTIFIER = bytes([
    0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
    0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
    0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
    0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
    0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
    0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e
])

IS_CORRECT_PASSWORD_IDENTIFIER = bytes([
    0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
    0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
    0x79, 0x6f, 0x75, 0x2e
])

PBKDF2_ITERATIONS = 500000

# Open in binary mode
data = Path('../test.wallet').read_bytes()

# Get the first set of magic bytes
magicBytes1 = data[:len(IS_A_WALLET_IDENTIFIER)]

# Verify the magic bytes are correct
if (magicBytes1 != IS_A_WALLET_IDENTIFIER):
    raise ValueError('Data is missing wallet identifier magic bytes!')

# Remove the magic bytes
data = data[len(IS_A_WALLET_IDENTIFIER):]

# Salt is the next 16 bytes
salt = data[:16]

# Remove the salt
data = data[16:]

# Generate the key with pbkdf2
key = hashlib.pbkdf2_hmac('sha256', b'password', salt, 500000, dklen=16)

# Setup our aes decryption
cipher = AES.new(key, AES.MODE_CBC, salt)

# Need to manually unpad, python doesn't support pkdf2
# This just removes the last padding chars, e.g. T E X T 0x3 0x3 0x3
# Number of items to remove == the padding char
unpad = lambda s : s[:-ord(s[len(s)-1:])]

# Decrypt
decrypted = unpad(cipher.decrypt(data))

# Grab magic bytes
magicBytes2 = decrypted[:len(IS_CORRECT_PASSWORD_IDENTIFIER)]

# Verify magic bytes
if (magicBytes2 != IS_CORRECT_PASSWORD_IDENTIFIER):
    raise ValueError('Incorrect password!')

# Remove second set of magic bytes
decrypted = decrypted[len(IS_CORRECT_PASSWORD_IDENTIFIER):]

print(decrypted.decode('utf8'))
