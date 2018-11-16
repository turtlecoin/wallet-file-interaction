# Make sure to compile in release mode - this pbkdf2 is very slow in debug
# mode
import nimcrypto/pbkdf2
import nimcrypto

const IS_A_WALLET_IDENTIFIER: array[64, byte] = [
    # Indicate it's a byte array
    0x49'u8, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
    0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
    0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
    0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
    0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
    0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e
]

const IS_CORRECT_PASSWORD_IDENTIFIER: array[26, byte] = [
    0x59'u8, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
    0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
    0x79, 0x6f, 0x75, 0x2e
]

const PBKDF2_ITERATIONS = 500000

# Converts an array of bytes to a string
proc arrToStr(oa: openArray[byte]): string =
    var str: string

    for i in 0..oa.len - 1:
        str = str & chr(oa[i])

    return str

# Removes pkcs7 padding
proc unpad(oa: openArray[byte]): seq[byte] =
    # Grab the last char
    var paddingChar = oa[high(oa)]

    # The value of the padding char indicates how many padding chars there are
    return oa[0.. len(oa) - ord(paddingChar) - 1]

var f: File

# Open the file
if not open(f, "../test.wallet"):
    raise newException(ValueError, "Could not open file!")

# Get the file size in bytes
var fileSize = getFileSize(f)

var data = newSeq[byte](fileSize)

# Read the file as bytes
discard readBytes(f, data, 0, fileSize)

# Check the magic bytes are present
if data[0..len(IS_A_WALLET_IDENTIFIER) - 1] != IS_A_WALLET_IDENTIFIER:
    raise newException(ValueError, "Data is missing wallet identifier magic bytes!")

# Remove the magic bytes
data = data[len(IS_A_WALLET_IDENTIFIER)..^1]

# Grab the salt
var salt = data[0..15]

# Remove the salt
data = data[len(salt)..^1]

# Space for our outputted pbkdf2 key
var key: array[16, byte]

var ctx: HMAC[sha256]

# Hash the password with pbkdf2
discard pbkdf2(ctx, "password", arrToStr(salt), PBKDF2_ITERATIONS, key, len(key))

var aesDecryption: CBC[aes128]

# Init our aes decryption with the key and salt
aesDecryption.init(key, salt)

# Output seq for decoded data
var decoded = newSeq[byte](len(data))

# Perform the decryption
aesDecryption.decrypt(data, decoded)

# Remove the pkcs7 padding
decoded = unpad(decoded)

# Verify the magic bytes
if decoded[0..len(IS_CORRECT_PASSWORD_IDENTIFIER) - 1] != IS_CORRECT_PASSWORD_IDENTIFIER:
    raise newException(ValueError, "Incorrect password!")

# Remove the magic bytes
decoded = decoded[len(IS_CORRECT_PASSWORD_IDENTIFIER)..^1]

echo arrToStr(decoded)
