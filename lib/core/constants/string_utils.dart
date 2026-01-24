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