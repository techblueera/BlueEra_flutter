extension GrammarExtension on String {
  String get withArticle {
    if (isEmpty) return this;

    // Check if the first letter is a vowel
    final vowels = ['a', 'e', 'i', 'o', 'u'];
    final isVowel = vowels.contains(this[0].toLowerCase());

    return '${isVowel ? "an" : "a"} $this';
  }
}

String formatRole(String rawRole) {
  return rawRole
      .toLowerCase()
      .split('_')
      .map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '')
      .join(' ');
}

String formatToTwoLines(String? text) {
  if (text == null || text.isEmpty) return "";

  // If no spaces, we can't split it by words
  if (!text.contains(" ")) return text;

  // 1. Find the rough middle of the string
  int mid = text.length ~/ 2;

  // 2. Find the space closest to the middle
  // We check the space immediately BEFORE the middle
  int beforeIndex = text.lastIndexOf(" ", mid);

  // We check the space immediately AFTER the middle
  int afterIndex = text.indexOf(" ", mid);

  // 3. Determine which space is closer to the center
  int splitIndex;

  if (beforeIndex == -1) {
    // No space in first half, take the one after
    splitIndex = afterIndex;
  } else if (afterIndex == -1) {
    // No space in second half, take the one before
    splitIndex = beforeIndex;
  } else {
    // Both exist, see which is closer to 'mid'
    if ((mid - beforeIndex) < (afterIndex - mid)) {
      splitIndex = beforeIndex;
    } else {
      splitIndex = afterIndex;
    }
  }

  // 4. Replace that space with a newline '\n'
  if (splitIndex != -1) {
    return text.replaceRange(splitIndex, splitIndex + 1, "\n");
  }

  return text;
}

extension StringExtensions on String? {
  /// Compares two strings ignoring case.
  /// Handles null values safely.
  bool equalsIgnoreCase(String? other) {
    if (this == null || other == null) return this == other;
    return this!.toLowerCase() == other.toLowerCase();
  }
}
