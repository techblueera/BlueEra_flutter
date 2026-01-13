extension GrammarExtension on String {
  String get withArticle {
    if (isEmpty) return this;

    // Check if the first letter is a vowel
    final vowels = ['a', 'e', 'i', 'o', 'u'];
    final isVowel = vowels.contains(this[0].toLowerCase());

    return '${isVowel ? "an" : "a"} $this';
  }
}