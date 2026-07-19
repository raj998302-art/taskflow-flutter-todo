import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Cryptographic utilities for hashing PIN / Pattern secrets before storing.
///
/// We never store the raw PIN or pattern. Instead we generate a random 16-byte
/// salt per user, append it to the secret, and SHA-256 hash the combination.
/// Only the salt and the hash are persisted — matching the approach described
/// in the lock-security prompt.
///
/// Note: this requires the `crypto` package (already a transitive dependency
/// via Hive / http). If it's missing, add `crypto: ^3.0.6` to pubspec.
class CryptoUtils {
  CryptoUtils._();

  /// Generates a cryptographically random 16-byte salt, base64-encoded.
  static String generateSalt() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  /// Hashes [value] (PIN string or pattern string like "0-1-2-5") with the
  /// given base64 [salt] using SHA-256. Returns a base64-encoded hash.
  static String hashWithSalt(String value, String salt) {
    final saltBytes = base64.decode(salt);
    final combined = utf8.encode(value) + saltBytes;
    final hashBytes = sha256.convert(combined).bytes;
    return base64.encode(hashBytes);
  }

  /// Verifies [input] against the stored [storedHash] + [storedSalt].
  static bool verify(String input, String storedHash, String storedSalt) {
    final inputHash = hashWithSalt(input, storedSalt);
    return inputHash == storedHash;
  }

  /// Converts a pattern node list (e.g. [0,1,2,4,7]) to a string "0-1-2-4-7".
  static String patternToString(List<int> pattern) {
    return pattern.join('-');
  }
}
