// class NameValidator {
//   /// Check if account name matches ID verification name
//   /// Returns true if names match (with some flexibility)
//   /// Returns false if names are significantly different
//   static bool validateNameMatch({
//     required String accountName,
//     required String idName,
//   }) {
//     print('>>> ============================================');
//     print('>>> NAME VALIDATION');
//     print('>>> Account name: "$accountName"');
//     print('>>> ID name: "$idName"');
//     print('>>> ============================================');

//     // Clean and normalize both names
//     final cleanAccountName = _cleanName(accountName);
//     final cleanIdName = _cleanName(idName);

//     print('>>> Cleaned account name: "$cleanAccountName"');
//     print('>>> Cleaned ID name: "$cleanIdName"');

//     // Exact match (case-insensitive)
//     if (cleanAccountName == cleanIdName) {
//       print('>>> ✓ EXACT MATCH');
//       return true;
//     }

//     // Split into words
//     final accountWords = cleanAccountName.split(' ');
//     final idWords = cleanIdName.split(' ');

//     print('>>> Account words: $accountWords');
//     print('>>> ID words: $idWords');

//     // Check if all account words exist in ID name (handles middle names)
//     final allAccountWordsFound = accountWords.every((word) {
//       final found = idWords.any((idWord) => 
//         idWord.startsWith(word) || word.startsWith(idWord) || idWord == word
//       );
//       print('>>>   Word "$word" found in ID: $found');
//       return found;
//     });

//     if (allAccountWordsFound) {
//       print('>>> ✓ ALL ACCOUNT WORDS FOUND IN ID');
//       return true;
//     }

//     // Check if all ID words exist in account name (handles different ordering)
//     final allIdWordsFound = idWords.every((word) {
//       final found = accountWords.any((accWord) => 
//         accWord.startsWith(word) || word.startsWith(accWord) || accWord == word
//       );
//       print('>>>   ID word "$word" found in account: $found');
//       return found;
//     });

//     if (allIdWordsFound) {
//       print('>>> ✓ ALL ID WORDS FOUND IN ACCOUNT');
//       return true;
//     }

//     // Check for common name variations
//     if (_checkCommonVariations(accountWords, idWords)) {
//       print('>>> ✓ COMMON NAME VARIATIONS MATCHED');
//       return true;
//     }

//     // Check similarity ratio (at least 70% similar)
//     final similarity = _calculateSimilarity(cleanAccountName, cleanIdName);
//     print('>>> Similarity ratio: ${(similarity * 100).toStringAsFixed(1)}%');

//     if (similarity >= 0.7) {
//       print('>>> ✓ HIGH SIMILARITY (>70%)');
//       return true;
//     }

//     print('>>> ✗ NAMES DO NOT MATCH');
//     print('>>> ============================================');
//     return false;
//   }

//   /// Clean and normalize a name for comparison
//   static String _cleanName(String name) {
//     return name
//         .toLowerCase()
//         .trim()
//         // Remove common titles
//         .replaceAll(RegExp(r'\b(mr|mrs|ms|dr|prof|sir|madam)\.?\b'), '')
//         // Remove special characters except spaces and hyphens
//         .replaceAll(RegExp(r'[^\w\s\-]'), '')
//         // Replace multiple spaces with single space
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim();
//   }

//   /// Check for common name variations
//   static bool _checkCommonVariations(
//     List<String> accountWords,
//     List<String> idWords,
//   ) {
//     // Check if first and last names match (ignoring middle names)
//     if (accountWords.length >= 2 && idWords.length >= 2) {
//       final accountFirst = accountWords.first;
//       final accountLast = accountWords.last;
//       final idFirst = idWords.first;
//       final idLast = idWords.last;

//       if ((accountFirst == idFirst || _areInitialsSimilar(accountFirst, idFirst)) &&
//           (accountLast == idLast || _areInitialsSimilar(accountLast, idLast))) {
//         return true;
//       }
//     }

//     // Check if one is initials of the other
//     for (var accountWord in accountWords) {
//       for (var idWord in idWords) {
//         if (_areInitialsSimilar(accountWord, idWord)) {
//           return true;
//         }
//       }
//     }

//     return false;
//   }

//   /// Check if one word is initial of another
//   static bool _areInitialsSimilar(String word1, String word2) {
//     if (word1.length == 1 && word2.length > 1) {
//       return word2.startsWith(word1);
//     }
//     if (word2.length == 1 && word1.length > 1) {
//       return word1.startsWith(word2);
//     }
//     return false;
//   }

//   /// Calculate similarity ratio between two strings using Levenshtein distance
//   static double _calculateSimilarity(String s1, String s2) {
//     if (s1 == s2) return 1.0;
//     if (s1.isEmpty || s2.isEmpty) return 0.0;

//     final maxLen = s1.length > s2.length ? s1.length : s2.length;
//     final distance = _levenshteinDistance(s1, s2);
    
//     return 1.0 - (distance / maxLen);
//   }

//   /// Calculate Levenshtein distance between two strings
//   static int _levenshteinDistance(String s1, String s2) {
//     final len1 = s1.length;
//     final len2 = s2.length;

//     if (len1 == 0) return len2;
//     if (len2 == 0) return len1;

//     // Create distance matrix
//     final matrix = List.generate(
//       len1 + 1,
//       (i) => List.filled(len2 + 1, 0),
//     );

//     // Initialize first row and column
//     for (int i = 0; i <= len1; i++) {
//       matrix[i][0] = i;
//     }
//     for (int j = 0; j <= len2; j++) {
//       matrix[0][j] = j;
//     }

//     // Fill matrix
//     for (int i = 1; i <= len1; i++) {
//       for (int j = 1; j <= len2; j++) {
//         final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;

//         matrix[i][j] = [
//           matrix[i - 1][j] + 1, // deletion
//           matrix[i][j - 1] + 1, // insertion
//           matrix[i - 1][j - 1] + cost, // substitution
//         ].reduce((a, b) => a < b ? a : b);
//       }
//     }

//     return matrix[len1][len2];
//   }

//   /// Get detailed validation result with reason
//   static Map<String, dynamic> validateNameMatchDetailed({
//     required String accountName,
//     required String idName,
//   }) {
//     final isValid = validateNameMatch(
//       accountName: accountName,
//       idName: idName,
//     );

//     String reason;
//     if (isValid) {
//       reason = 'Names match successfully';
//     } else {
//       reason = 'Account name "$accountName" does not match ID name "$idName". '
//                'Please ensure your account name matches your government ID exactly.';
//     }

//     return {
//       'isValid': isValid,
//       'reason': reason,
//       'accountName': accountName,
//       'idName': idName,
//     };
//   }
// }