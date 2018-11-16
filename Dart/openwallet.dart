import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:pointycastle/pointycastle.dart';

const IS_A_WALLET_IDENTIFIER = [
    0x49, 0x66, 0x20, 0x49, 0x20, 0x70, 0x75, 0x6c, 0x6c, 0x20, 0x74,
    0x68, 0x61, 0x74, 0x20, 0x6f, 0x66, 0x66, 0x2c, 0x20, 0x77, 0x69,
    0x6c, 0x6c, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x64, 0x69, 0x65, 0x3f,
    0x0a, 0x49, 0x74, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62,
    0x65, 0x20, 0x65, 0x78, 0x74, 0x72, 0x65, 0x6d, 0x65, 0x6c, 0x79,
    0x20, 0x70, 0x61, 0x69, 0x6e, 0x66, 0x75, 0x6c, 0x2e
];

const IS_CORRECT_PASSWORD_IDENTIFIER = [
    0x59, 0x6f, 0x75, 0x27, 0x72, 0x65, 0x20, 0x61, 0x20, 0x62, 0x69,
    0x67, 0x20, 0x67, 0x75, 0x79, 0x2e, 0x0a, 0x46, 0x6f, 0x72, 0x20,
    0x79, 0x6f, 0x75, 0x2e
];

const PBKDF2_ITERATIONS = 500000;

main() {
    new File('../test.wallet').readAsBytes().then((List<int> dataList) {
        var data = Uint8List.fromList(dataList);

        /* Dart doesn't like comparing arrays :( */
        Function eq = const ListEquality().equals;

        /* Verify the magic bytes are correct */
        if (!eq(data.sublist(0, IS_A_WALLET_IDENTIFIER.length), IS_A_WALLET_IDENTIFIER)) {
            throw FormatException('Data is missing wallet identifier magic bytes!');
        }

        /* Remove the magic bytes */
        data = data.sublist(IS_A_WALLET_IDENTIFIER.length, data.length);

        /* Get the salt */
        final salt = data.sublist(0, 16);

        /* Remove the salt */
        data = data.sublist(salt.length, data.length);

        final pbkdf2 = new KeyDerivator("SHA-256/HMAC/PBKDF2");

        /* Setup salt, iterations, output size */
        pbkdf2.init(new Pbkdf2Parameters(salt, PBKDF2_ITERATIONS, 16));

        /* Get the key from out pbkdf2 */
        final key = pbkdf2.process(Uint8List.fromList('password'.codeUnits));

        /* Setup our aes decryption with CBC */
        final decryptionCipher = new PaddedBlockCipher("AES/CBC/PKCS7");

        /* Add key and salt/iv */
        CipherParameters params = new PaddedBlockCipherParameters(
            new ParametersWithIV(new KeyParameter(key), salt), null
        );

        /* We're decrypting */
        bool isEncryption = false;

        decryptionCipher.init(isEncryption, params);

        Uint8List decrypted;
        
        /* Decrypt */
        try {
            decrypted = decryptionCipher.process(data);
        } on ArgumentError {
            throw FormatException('Wrong password!');
        }

        /* Check password magic bytes */
        if (!eq(decrypted.sublist(0, IS_CORRECT_PASSWORD_IDENTIFIER.length), IS_CORRECT_PASSWORD_IDENTIFIER)) {
            throw FormatException('Wrong password!');
        }
        
        /* Remove magic bytes */
        decrypted = decrypted.sublist(IS_CORRECT_PASSWORD_IDENTIFIER.length, decrypted.length);

        print(new String.fromCharCodes(decrypted));
    });
}
