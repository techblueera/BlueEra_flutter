import 'package:BlueEra/core/navigation/me_section_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Me-tab routing table, pinned.
///
/// [resolveMeSectionKind] was lifted out of `_buildBusinessScreen`'s if/else
/// chain so the go-live nudge could describe the right kind of business. That
/// chain decided which module every merchant lands on, so these cases exist to
/// prove the extraction kept each destination — and to keep the next edit of
/// the mapping honest, since a wrong answer here is a merchant on the wrong
/// screen rather than a failed build.
void main() {
  MeSectionKind kindOf(String type, [String category = '']) =>
      resolveMeSectionKind(businessType: type, businessCategory: category);

  group('single-category types', () {
    test('map straight from the business type', () {
      expect(kindOf('Food'), MeSectionKind.food);
      expect(kindOf('Grocery'), MeSectionKind.grocery);
      expect(kindOf('Siksha'), MeSectionKind.school);
      expect(kindOf('Motel'), MeSectionKind.hotel);
      expect(kindOf('Product'), MeSectionKind.product);
      expect(kindOf('Service'), MeSectionKind.service);
      expect(kindOf('Finance'), MeSectionKind.service);
    });

    test('are case-insensitive, as the API is inconsistent about case', () {
      expect(kindOf('FOOD'), MeSectionKind.food);
      expect(kindOf('food'), MeSectionKind.food);
    });
  });

  group('healthcare', () {
    test('doctors and clinics are standalone practitioners', () {
      expect(kindOf('Healthcare', 'DOCTORS'), MeSectionKind.doctor);
      expect(kindOf('Healthcare', 'Clinic Doctors'), MeSectionKind.doctor);
      expect(kindOf('Healthcare', 'CLINICS'), MeSectionKind.doctor);
    });

    test('splits its remaining categories by module', () {
      expect(kindOf('Healthcare', 'HOSPITALS'), MeSectionKind.hospital);
      expect(
          kindOf('Healthcare', 'ALTERNATIVE HEALTH'), MeSectionKind.hospital);
      expect(kindOf('Healthcare', 'DIAGNOSTIC'), MeSectionKind.laboratory);
      expect(kindOf('Healthcare', 'PHARMACY'), MeSectionKind.pharmacy);
    });

    test('anything else under it falls back to the services screen', () {
      expect(kindOf('Healthcare', 'SOMETHING_NEW'), MeSectionKind.service);
      expect(kindOf('Healthcare'), MeSectionKind.service);
    });

    test('tolerates a padded category', () {
      // The pre-extraction chain compared an untrimmed category with `==`, so
      // this one landed on the generic services screen instead of the pharmacy
      // module.
      expect(kindOf('Healthcare', ' PHARMACY '), MeSectionKind.pharmacy);
    });
  });

  group('manufacturing', () {
    test('follows what is made, in either category spelling', () {
      expect(kindOf('Manufacturing', 'MANUFACTURING_GROCERY'),
          MeSectionKind.grocery);
      expect(kindOf('Manufacturing', 'Manufacturing Healthcare'),
          MeSectionKind.pharmacy);
      expect(kindOf('Manufacturing', 'MANUFACTURING_AUTOMOTIVE'),
          MeSectionKind.automotiveParts);
    });

    test('defaults to the general goods catalogue, including new categories',
        () {
      expect(kindOf('Manufacturing', 'MANUFACTURING_PRODUCT'),
          MeSectionKind.manufacturerProduct);
      expect(kindOf('Manufacturing', 'SOMETHING_ADDED_LATER'),
          MeSectionKind.manufacturerProduct);
    });
  });

  group('automotive', () {
    test('splits showroom, workshop and parts', () {
      expect(kindOf('Automotive', 'VEHICLE_SALES'), MeSectionKind.vehicleSales);
      expect(kindOf('Automotive', 'VEHICLE SALES'), MeSectionKind.vehicleSales);
      expect(kindOf('Automotive', 'VEHICLE_SERVICE'),
          MeSectionKind.automotiveService);
      expect(kindOf('Automotive', 'TRANSPORT_LOGISTICS_PARKING'),
          MeSectionKind.automotiveService);
      expect(
          kindOf('Automotive', 'AUTO PARTS'), MeSectionKind.automotiveParts);
    });

    test('an unknown automotive category is unknown, not a workshop', () {
      // Automotive is the one type whose fallback is the unknown-business
      // screen rather than a module — it had no catch-all destination before
      // the extraction either.
      expect(kindOf('Automotive', 'VEHICLE_RENTAL'), MeSectionKind.unknown);
      expect(kindOf('Automotive'), MeSectionKind.unknown);
    });
  });

  group('unrecognised accounts', () {
    test('fall through to unknown', () {
      expect(kindOf('Both'), MeSectionKind.unknown);
      expect(kindOf('SomeNewTypeTheApiAdded'), MeSectionKind.unknown);
      // A type global that hasn't hydrated yet — the Me tab shows its shimmer
      // above this, but the classifier must not guess.
      expect(kindOf(''), MeSectionKind.unknown);
    });
  });
}
