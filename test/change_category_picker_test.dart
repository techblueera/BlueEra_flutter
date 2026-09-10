import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/profile_category/model/category_option.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two rules that decide what the change-category picker offers and what
/// it asks for (§6 / §7 of FLUTTER_PROFILE_CATEGORY_CHANGE_GUIDE.md).
///
/// Both are cheap to get wrong in a way nobody notices until a user is stuck:
/// offering a retired profession produces a change that always 422s, and
/// missing a medical category produces a 400 the user can't act on.
void main() {
  group('profession is selectable — §6 filter', () {
    ProfessionTypeData row({bool? isActive, String? deletedAt}) =>
        ProfessionTypeData.fromJson({
          '_id': '1',
          'name': 'Bike Rider',
          'tag_id': 'BIKE_RIDER',
          'isActive': isActive,
          'deletedAt': deletedAt,
        });

    test('ordinary rows are selectable', () {
      // The flags are omitted for normal professions, so absent must mean
      // active — defaulting the other way would empty the picker.
      expect(row().isSelectable, isTrue);
      expect(row(isActive: true).isSelectable, isTrue);
    });

    test('retired and soft-deleted rows are not', () {
      // GET individual-professions returns both; the change endpoint rejects
      // them with 422 unknown_category.
      expect(row(isActive: false).isSelectable, isFalse);
      expect(row(deletedAt: '2026-01-04T00:00:00.000Z').isSelectable, isFalse);
      expect(row(isActive: false, deletedAt: '2026-01-04T00:00:00.000Z')
          .isSelectable, isFalse);
    });
  });

  group('licence requirement — §7', () {
    bool needsLicense(String tagId) =>
        CategoryOption(tagId: tagId, name: tagId).requiresLicense;

    test('covers all six medical categories', () {
      for (final tag in [
        'PHARMACY',
        'HOSPITALS',
        'CLINICS',
        'DOCTORS',
        'DIAGNOSTIC',
        'ALTERNATIVE_HEALTH',
      ]) {
        expect(needsLicense(tag), isTrue,
            reason: '$tag needs a licence number or the change 400s');
      }
    });

    test('matches the category spellings the API actually sends', () {
      // The category arrives as a display name on some paths and a tag id on
      // others, so the test is on the token, not an exact string.
      expect(needsLicense('ALTERNATIVE HEALTH'), isTrue);
      expect(needsLicense('Clinic Doctors'), isTrue);
    });

    test('leaves non-medical categories alone', () {
      for (final tag in [
        'GROCERY_STORE',
        'FOOD_RESTAURANT',
        'VEHICLE_SALES',
        'MANUFACTURING_PRODUCT',
      ]) {
        expect(needsLicense(tag), isFalse,
            reason: '$tag must not ask for a licence');
      }
    });
  });

  group('sub-category handling', () {
    test('a category with sub-categories reports them', () {
      const option = CategoryOption(
        tagId: 'FOOD_RESTAURANT',
        name: 'Food & Restaurant',
        subCategories: [CategorySubOption(id: 'a1', name: 'Cafe')],
      );
      expect(option.hasSubCategories, isTrue);
    });

    test('one without them does not prompt', () {
      const option = CategoryOption(tagId: 'BIKE_RIDER', name: 'Bike Rider');
      expect(option.hasSubCategories, isFalse);
    });
  });
}
