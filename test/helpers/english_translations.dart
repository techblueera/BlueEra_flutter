import 'dart:convert';
import 'dart:io';

/// The app's English strings (`assets/translations/en.json`), keyed for
/// `GetMaterialApp(translationsKeys:)`.
///
/// Widgets render `AppStrings.x.tr`, and `AppStrings` values are translation
/// keys, so without these a widget test sees raw keys ("bookNow") instead of
/// the text a user reads ("Book Now"). Pair with `locale: Locale('en')`.
Map<String, Map<String, String>> englishTranslations() {
  final json =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;
  return {'en': json.map((k, v) => MapEntry(k, v.toString()))};
}
