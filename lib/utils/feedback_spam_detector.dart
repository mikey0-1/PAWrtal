/// 🔥 ENHANCED Spam & Gibberish Detection for Feedback System
/// Detects: redundant submissions, scrambled words, gibberish, and duplicate content
class FeedbackSpamDetector {
  // ============= CONFIGURATION =============
  static const double SPAM_THRESHOLD = 0.55; // 55% confidence = spam
  static const double REDUNDANCY_THRESHOLD = 0.75; // 75% similarity = redundant
  static const int MIN_WORD_LENGTH = 2;
  static const int MAX_SPECIAL_CHAR_RATIO = 35; // 35% special chars
  static const int MAX_CONSONANT_STREAK = 6;
  static const int MAX_REPETITION_RATIO = 45; // 45% repeated chars

  // Spam patterns
  static final List<RegExp> _spamPatterns = [
    RegExp(r'(.)\1{4,}', caseSensitive: false), // Same char 5+ times
    RegExp(r'[^a-zA-Z0-9\s]{8,}'), // 8+ special chars in a row
    RegExp(r'[qwrtypsdfghjklzxcvbnm]{7,}', caseSensitive: false), // Keyboard mashing
    RegExp(r'^[aeiou]{12,}$', caseSensitive: false), // Only vowels
    RegExp(r'^[^aeiou\s]{12,}$', caseSensitive: false), // Only consonants
    RegExp(r'\b(\w+)\s+\1\s+\1', caseSensitive: false), // Same word 3+ times
  ];

  // English word patterns (common letter combinations)
  static final Set<String> _validBigrams = {
    'th', 'he', 'in', 'er', 'an', 're', 'on', 'at', 'en', 'nd',
    'ti', 'es', 'or', 'te', 'of', 'ed', 'is', 'it', 'al', 'ar',
    'st', 'to', 'nt', 'ng', 'se', 'ha', 'as', 'ou', 'io', 'le',
  };

  // Common English words whitelist
  static final Set<String> _commonWords = {
    'the', 'and', 'for', 'with', 'this', 'that', 'have', 'from', 'they',
    'will', 'would', 'could', 'should', 'about', 'when', 'what', 'where',
    'appointment', 'clinic', 'doctor', 'pet', 'service', 'help', 'need',
    'please', 'thank', 'sorry', 'issue', 'problem', 'bug', 'error', 'can',
    'has', 'been', 'very', 'good', 'bad', 'want', 'like', 'time', 'just',
    'make', 'know', 'take', 'see', 'come', 'think', 'look', 'also', 'back',
    'use', 'way', 'even', 'new', 'well', 'day', 'work', 'year', 'call',
  };

  // ============= MAIN DETECTION METHODS =============

  /// 🎯 MAIN: Check if feedback is spam (subject + description)
  static bool isSpamOrGibberish({
    required String subject,
    required String description,
  }) {
    if (subject.trim().isEmpty && description.trim().isEmpty) return true;

    // Analyze both subject and description
    final subjectScore = _calculateSpamScore(subject);
    final descriptionScore = _calculateSpamScore(description);

    // Weighted average (subject is more important)
    final finalScore = (subjectScore * 0.4) + (descriptionScore * 0.6);


    return finalScore >= SPAM_THRESHOLD;
  }

  /// 🔄 Check if user has redundant/duplicate submissions
  static bool hasRedundantSubmissions({
    required String userId,
    required String currentSubject,
    required String currentDescription,
    required List<Map<String, dynamic>> userPreviousFeedbacks,
  }) {
    if (userPreviousFeedbacks.isEmpty) return false;


    int redundantCount = 0;
    final currentContent = '$currentSubject $currentDescription'.toLowerCase();

    for (var previousFeedback in userPreviousFeedbacks) {
      final previousSubject = previousFeedback['subject']?.toString() ?? '';
      final previousDescription = previousFeedback['description']?.toString() ?? '';
      final previousContent = '$previousSubject $previousDescription'.toLowerCase();

      // Calculate similarity
      final similarity = _calculateSimilarity(currentContent, previousContent);


      if (similarity >= REDUNDANCY_THRESHOLD) {
        redundantCount++;
      }
    }

    final isRedundant = redundantCount > 0;

    return isRedundant;
  }

  // ============= SPAM SCORING =============

  /// Calculate spam probability (0.0 - 1.0)
  static double _calculateSpamScore(String text) {
    if (text.trim().isEmpty) return 1.0;

    double totalScore = 0.0;
    int checks = 0;

    // Check 1: Special character ratio
    totalScore += _checkSpecialCharacterRatio(text);
    checks++;

    // Check 2: Consonant streaks (gibberish)
    totalScore += _checkConsonantStreaks(text);
    checks++;

    // Check 3: Repetitive patterns
    totalScore += _checkRepetitivePatterns(text);
    checks++;

    // Check 4: Recognizable words
    totalScore += _checkRecognizableWords(text);
    checks++;

    // Check 5: Spam pattern matching
    totalScore += _checkSpamPatterns(text);
    checks++;

    // Check 6: Random case mixing
    totalScore += _checkRandomCaseMixing(text);
    checks++;

    // Check 7: 🆕 Letter bigram analysis (detect scrambled words)
    totalScore += _checkLetterBigrams(text);
    checks++;

    // Check 8: 🆕 Word scrambling detection
    totalScore += _checkWordScrambling(text);
    checks++;

      totalScore += _checkRepeatedPhrases(text);
      checks++;

      return totalScore / checks;

  
  }

  /// Check 1: Too many special characters
  static double _checkSpecialCharacterRatio(String text) {
    final specialChars = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');
    final ratio = (specialChars.length / text.length) * 100;

    if (ratio > MAX_SPECIAL_CHAR_RATIO) return 1.0;
    if (ratio > MAX_SPECIAL_CHAR_RATIO * 0.7) return 0.7;
    if (ratio > MAX_SPECIAL_CHAR_RATIO * 0.4) return 0.4;
    return 0.0;
  }

  /// Check 2: Unrealistic consonant streaks
  static double _checkConsonantStreaks(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    int violationCount = 0;

    for (var word in words) {
      if (word.length < MIN_WORD_LENGTH) continue;

      int consonantStreak = 0;
      for (var char in word.split('')) {
        if ('bcdfghjklmnpqrstvwxyz'.contains(char)) {
          consonantStreak++;
          if (consonantStreak > MAX_CONSONANT_STREAK) {
            violationCount++;
            break;
          }
        } else {
          consonantStreak = 0;
        }
      }
    }

    final ratio = words.isEmpty ? 0.0 : violationCount / words.length;
    return ratio > 0.3 ? 1.0 : ratio * 2.5;
  }

  /// Check 3: Repetitive characters
  static double _checkRepetitivePatterns(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return 0.0;

    final charCounts = <String, int>{};
    for (var char in cleaned.split('')) {
      charCounts[char] = (charCounts[char] ?? 0) + 1;
    }

    final maxRepeat = charCounts.values.fold(0, (max, count) => count > max ? count : max);
    final repeatRatio = (maxRepeat / cleaned.length) * 100;

    if (repeatRatio > MAX_REPETITION_RATIO) return 1.0;
    if (repeatRatio > MAX_REPETITION_RATIO * 0.7) return 0.7;
    if (repeatRatio > MAX_REPETITION_RATIO * 0.4) return 0.4;
    return 0.0;
  }

  /// Check 4: Recognizable words
  static double _checkRecognizableWords(String text) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= MIN_WORD_LENGTH)
        .toList();

    if (words.isEmpty) return 1.0;

    int recognizedCount = 0;
    for (var word in words) {
      if (_commonWords.contains(word)) {
        recognizedCount++;
      }
    }

    final recognizedRatio = recognizedCount / words.length;

    if (recognizedRatio < 0.05) return 1.0;
    if (recognizedRatio < 0.15) return 0.8;
    if (recognizedRatio < 0.3) return 0.5;
    if (recognizedRatio < 0.5) return 0.2;
    return 0.0;
  }

  /// Check 5: Known spam patterns
  static double _checkSpamPatterns(String text) {
    for (var pattern in _spamPatterns) {
      if (pattern.hasMatch(text)) {
        return 1.0;
      }
    }
    return 0.0;
  }

  /// Check 6: Random case mixing
  static double _checkRandomCaseMixing(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length < 10) return 0.0;

    int caseChanges = 0;
    bool lastWasUpper = letters[0] == letters[0].toUpperCase();

    for (int i = 1; i < letters.length; i++) {
      bool currentIsUpper = letters[i] == letters[i].toUpperCase();
      if (currentIsUpper != lastWasUpper) {
        caseChanges++;
      }
      lastWasUpper = currentIsUpper;
    }

    final changeRatio = caseChanges / letters.length;

    if (changeRatio > 0.4) return 1.0;
    if (changeRatio > 0.25) return 0.6;
    if (changeRatio > 0.15) return 0.3;
    return 0.0;
  }

  /// Check 7: 🆕 Letter bigram analysis (detect scrambled words)
  /// Real English words follow common letter patterns
  static double _checkLetterBigrams(String text) {
    final cleanedText = text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (cleanedText.length < 4) return 0.0;

    int totalBigrams = 0;
    int validBigrams = 0;

    for (int i = 0; i < cleanedText.length - 1; i++) {
      final bigram = cleanedText.substring(i, i + 2);
      totalBigrams++;
      if (_validBigrams.contains(bigram)) {
        validBigrams++;
      }
    }

    final validRatio = validBigrams / totalBigrams;

    // Low valid bigram ratio = scrambled/gibberish
    if (validRatio < 0.15) return 1.0;  // Very scrambled
    if (validRatio < 0.25) return 0.8;  // Highly scrambled
    if (validRatio < 0.35) return 0.5;  // Suspicious
    return 0.0;  // Normal text
  }

  /// Check 8: 🆕 Word scrambling detection
  /// Detects words with impossible letter combinations
  static double _checkWordScrambling(String text) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .toList();

    if (words.isEmpty) return 0.0;

    int scrambledCount = 0;

    for (var word in words) {
      // Check for impossible patterns
      bool hasVowel = word.contains(RegExp(r'[aeiou]'));
      bool hasConsonant = word.contains(RegExp(r'[bcdfghjklmnpqrstvwxyz]'));
      
      if (!hasVowel || !hasConsonant) {
        scrambledCount++;
        continue;
      }

      // Check for too many consonants in a row
      if (RegExp(r'[bcdfghjklmnpqrstvwxyz]{6,}').hasMatch(word)) {
        scrambledCount++;
        continue;
      }

      // Check if word is NOT in dictionary AND has low bigram score
      if (!_commonWords.contains(word)) {
        final validBigramRatio = _getWordBigramRatio(word);
        if (validBigramRatio < 0.3) {
          scrambledCount++;
        }
      }
    }

    final scrambledRatio = scrambledCount / words.length;

    if (scrambledRatio > 0.6) return 1.0;  // Most words scrambled
    if (scrambledRatio > 0.4) return 0.8;  // Many words scrambled
    if (scrambledRatio > 0.2) return 0.5;  // Some words scrambled
    return 0.0;
  }

  /// Helper: Get valid bigram ratio for a word
  static double _getWordBigramRatio(String word) {
    if (word.length < 2) return 0.0;

    int totalBigrams = 0;
    int validBigrams = 0;

    for (int i = 0; i < word.length - 1; i++) {
      final bigram = word.substring(i, i + 2);
      totalBigrams++;
      if (_validBigrams.contains(bigram)) {
        validBigrams++;
      }
    }

    return validBigrams / totalBigrams;
  }

  // ============= SIMILARITY CALCULATION =============

  /// Calculate similarity between two texts (Levenshtein-based)
  static double _calculateSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Normalize texts
    final normalized1 = _normalizeText(text1);
    final normalized2 = _normalizeText(text2);

    // Calculate Levenshtein distance
    final distance = _levenshteinDistance(normalized1, normalized2);
    final maxLength = normalized1.length > normalized2.length
        ? normalized1.length
        : normalized2.length;

    // Convert distance to similarity (0.0 - 1.0)
    return 1.0 - (distance / maxLength);
  }

  /// Normalize text for comparison
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculate Levenshtein distance (edit distance)
  static int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    final matrix = List.generate(len1 + 1, (_) => List<int>.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  static double _checkRepeatedPhrases(String text) {
  final words = text.toLowerCase()
      .replaceAll(RegExp(r'[^a-z\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.length >= 3)
      .toList();

  if (words.length < 5) return 0.0;

  // Check for same word repeated 3+ times in a row
  int repeatedSequences = 0;
  for (int i = 0; i < words.length - 2; i++) {
    if (words[i] == words[i + 1] && words[i] == words[i + 2]) {
      repeatedSequences++;
    }
  }

  final repeatedRatio = repeatedSequences / (words.length / 3);

  if (repeatedRatio > 0.3) return 1.0;  // High repetition
  if (repeatedRatio > 0.15) return 0.7;
  return 0.0;
}



  // ============= DETAILED ANALYSIS =============

  /// Get comprehensive spam analysis
  static Map<String, dynamic> analyzeMessage({
    required String subject,
    required String description,
  }) {
    final subjectScore = _calculateSpamScore(subject);
    final descriptionScore = _calculateSpamScore(description);
    final finalScore = (subjectScore * 0.4) + (descriptionScore * 0.6);

    return {
      'subject': subject,
      'description': description,
      'isSpam': finalScore >= SPAM_THRESHOLD,
      'subjectSpamScore': subjectScore,
      'descriptionSpamScore': descriptionScore,
      'finalSpamScore': finalScore,
      'specialCharRatio': _checkSpecialCharacterRatio('$subject $description'),
      'consonantStreakScore': _checkConsonantStreaks('$subject $description'),
      'repetitionScore': _checkRepetitivePatterns('$subject $description'),
      'wordRecognitionScore': _checkRecognizableWords('$subject $description'),
      'patternMatchScore': _checkSpamPatterns('$subject $description'),
      'caseMixingScore': _checkRandomCaseMixing('$subject $description'),
      'bigramScore': _checkLetterBigrams('$subject $description'),
      'scramblingScore': _checkWordScrambling('$subject $description'),
    };
  }
}