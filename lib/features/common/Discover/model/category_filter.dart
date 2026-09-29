import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:get/get.dart';

/// How a Discover listing (earn services, consultants) is sorted.
enum CategoryFilter {
  nearest('Nearest', AppStrings.filterNearest),
  experienced('Experienced', AppStrings.filterExperienced),
  priceLowToHigh('Price (Low-High)', AppStrings.filterPriceLowToHigh);

  final String label;
  final String _translationKey;

  const CategoryFilter(this.label, this._translationKey);

  /// Returns the translated label, falling back to the English [label]
  /// if the current locale has no translation yet (so the UI never breaks
  /// or shows raw keys while Hindi/other-language packs are still loading).
  String get localizedLabel {
    final translated = _translationKey.tr;
    return translated == _translationKey ? label : translated;
  }
}
