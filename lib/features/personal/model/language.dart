class LocalizationModel {
  final String languageCode;
  final String languageName;
  final Map<String, String> strings;

  LocalizationModel({
    required this.languageCode,
    required this.languageName,
    required this.strings,
  });

  factory LocalizationModel.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final langCode = json['languageCode'] ?? '';
    final langName = json['languageName'] ?? '';

    // All other keys will be stored dynamically in a map
    final Map<String, String> allStrings = {};
    json.forEach((key, value) {
      if (key != 'languageCode' && key != 'languageName') {
        allStrings[key] = value?.toString() ?? '';
      }
    });

    return LocalizationModel(
      languageCode: langCode,
      languageName: langName,
      strings: allStrings,
    );
  }

  String getText(String key) => strings[key] ?? key;

  Map<String, dynamic> toJson() => {
    'languageCode': languageCode,
    'languageName': languageName,
    ...strings,
  };
}
