class LanguageModelNew {
  final String name;
  final String code;
  bool isDownloaded;
  bool isSelected;

  LanguageModelNew({
    required this.name,
    required this.code,
    this.isDownloaded = false,
    this.isSelected = false,
  });
}