class LanguageModel {
  final String name;
  final String code;

  LanguageModel({
    required this.name,
    required this.code,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    try {
      return LanguageModel(
        name: json['languageName']?.toString() ?? '',
        code: json['languageCode']?.toString() ?? '',
      );
    } catch (e) {
      print('Error in LanguageModel.fromJson: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'languageName': name,
      'languageCode': code,
    };
  }

  @override
  String toString() {
    return 'LanguageModel(name: $name, code: $code)';
  }
}