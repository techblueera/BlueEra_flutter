import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Service-type options for the rider "Set Preference" tab. Each option maps
// to a backend `vehicleUsesType` slug — the field the nearby-rider filter
// keys off (see docs/backend/RIDER_PREFERENCE_FILTER.md):
//   passenger → passenger rides only
//   goods     → delivery (goods) only
//   both      → passenger&delivery
// `labelKey` is an AppStrings key resolved with `.tr` so the radio labels
// and submit confirmation stay localized.
enum RiderServicePreference {
  passenger('passenger', AppStrings.servicePassenger, Icons.person_rounded),
  goods('delivery', AppStrings.serviceGoods, Icons.inventory_2_rounded),
  both('passenger&delivery', AppStrings.serviceBoth,
      Icons.all_inclusive_rounded);

  const RiderServicePreference(this.slugId, this.labelKey, this.icon);

  /// Backend `vehicleUsesType` value persisted for this preference.
  final String slugId;

  /// AppStrings key for the human-readable label.
  final String labelKey;

  /// Glyph shown beside the label — carried here so the icon can never drift
  /// from the option it describes.
  final IconData icon;

  String get label => labelKey.tr;

  /// Maps a backend `vehicleUsesType` slug back to a UI option so the card
  /// can pre-select the rider's saved choice. `goodsTransport` (a heavy-goods
  /// onboarding type) collapses to the Goods option.
  static RiderServicePreference? fromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    for (final p in RiderServicePreference.values) {
      if (p.slugId == slug) return p;
    }
    if (slug == 'goodsTransport') return RiderServicePreference.goods;
    return null;
  }
}
