import 'package:BlueEra/core/constants/debug_log.dart';
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
      debugLog('Error in LanguageModel.fromJson: $e');
      debugLog('JSON data: $json');
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