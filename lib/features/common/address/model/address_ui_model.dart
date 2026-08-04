import 'package:BlueEra/features/common/address/model/user_address_model.dart';

/// Handed back by the address picker whenever the user confirms a selection,
/// so any feature (cart, order, rider booking, service enquiry…) can consume
/// the chosen address without knowing anything about this module.
typedef AddressSelectedCallback = void Function(UserAddress address);

/// Address "type" tag shown as chips on the add/edit form.
///
/// The API stores this as a plain string on `addressType`. `Home` and
/// `Office` are the two fixed presets; anything else is a user-authored
/// label typed into the "Other" field (e.g. `Gym`) and is round-tripped
/// through the same field — that is why [selectionFor] treats an
/// unrecognised value as "Other" plus a custom label rather than bad data.
class AddressTypeOption {
  const AddressTypeOption._();

  static const String home = 'Home';
  static const String office = 'Office';
  static const String other = 'Other';

  /// Chips rendered on the form, in order.
  static const List<String> selectable = [home, office, other];

  /// Which chip should appear selected for a stored [type].
  static String selectionFor(String? type) {
    final value = type?.trim() ?? '';
    if (value.isEmpty) return home;
    if (value.toLowerCase() == home.toLowerCase()) return home;
    if (value.toLowerCase() == office.toLowerCase()) return office;
    return other;
  }

  /// The free-text label to pre-fill in the "Other" input, or `null` when the
  /// stored value is one of the presets (or the bare word "Other").
  static String? customLabelFor(String? type) {
    final value = type?.trim() ?? '';
    if (value.isEmpty) return null;
    if (selectionFor(value) != other) return null;
    if (value.toLowerCase() == other.toLowerCase()) return null;
    return value;
  }
}

/// Floor of the building, shown as a dropdown on the add/edit form and sent
/// to the API on `floor_no`.
///
/// Stored as a plain string so `10+` (everything above the tenth floor)
/// round-trips as-is; [selectionFor] keeps an unrecognised stored value out
/// of the dropdown rather than crashing it, since the widget can only show a
/// value that is in [selectable].
class FloorNumberOption {
  const FloorNumberOption._();

  static const String ground = '0';
  static const String tenPlus = '10+';

  /// `0`, `1` … `10`, `10+` — in dropdown order.
  static const List<String> selectable = [
    ground,
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    tenPlus,
  ];

  /// What the user reads for a stored value.
  static String labelFor(String value) {
    if (value == ground) return 'Ground floor (0)';
    if (value == tenPlus) return 'Above 10th floor (10+)';
    return 'Floor $value';
  }

  /// The dropdown entry matching a stored [floorNo], or `null` when nothing
  /// was saved (or the saved value is not one of ours).
  static String? selectionFor(String? floorNo) {
    final value = floorNo?.trim() ?? '';
    if (value.isEmpty) return null;
    return selectable.contains(value) ? value : null;
  }
}

/// Presentation helpers over [UserAddress].
extension UserAddressUi on UserAddress {
  /// Label for the type chip on a saved-address card.
  String get typeLabel {
    final value = addressType?.trim() ?? '';
    return value.isEmpty ? AddressTypeOption.home : value;
  }

  /// `line1, line2, city, state - pincode` with every empty part dropped.
  String get formattedAddress {
    final parts = [
      addressLine1?.trim() ?? '',
      addressLine2?.trim() ?? '',
      city?.trim() ?? '',
      state?.trim() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    final pin = pincode?.trim() ?? '';
    final joined = parts.join(', ');
    if (pin.isEmpty) return joined;
    return joined.isEmpty ? pin : '$joined - $pin';
  }
}
