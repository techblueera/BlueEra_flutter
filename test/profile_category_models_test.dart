import 'dart:convert';

import 'package:BlueEra/features/common/profile_category/model/profile_category_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parsing for the one-time profile-category change (§5 / §7 of
/// FLUTTER_PROFILE_CATEGORY_CHANGE_GUIDE.md).
///
/// The payloads below are copied from the guide verbatim, so a backend change
/// that breaks the contract fails here rather than in a bottom sheet.
void main() {
  Map<dynamic, dynamic> body(String raw) =>
      (jsonDecode(raw) as Map)['data'] as Map;

  group('ProfileCategoryState — BUSINESS (§5)', () {
    final state = ProfileCategoryState.fromJson(body('''
      {"success": true, "data": {
        "account_type": "BUSINESS",
        "supported": true,
        "current": {
          "tag_id": "GROCERY_STORE",
          "name": "Grocery Store",
          "category_type": "Grocery",
          "sub_category_id": "6a088aeccc4c93f8e56649f0"
        },
        "changes_used": 0,
        "changes_remaining": 1,
        "can_change": true,
        "last_changed_at": null,
        "last_changed_by": null,
        "options_endpoint": "/business/getAllcategories"
      }}
    '''));

    test('reads the envelope', () {
      expect(state.accountType, 'BUSINESS');
      expect(state.supported, isTrue);
      expect(state.canChange, isTrue);
      expect(state.changesUsed, 0);
      expect(state.changesRemaining, 1);
      expect(state.lastChangedAt, isNull);
    });

    test('reads the current category', () {
      expect(state.current?.tagId, 'GROCERY_STORE');
      expect(state.current?.name, 'Grocery Store');
      expect(state.current?.categoryType, 'Grocery');
      expect(state.current?.subCategoryId, '6a088aeccc4c93f8e56649f0');
    });

    test('routes the picker to the business catalog', () {
      expect(state.usesProfessionsCatalog, isFalse);
    });
  });

  group('ProfileCategoryState — INDIVIDUAL (§5)', () {
    final state = ProfileCategoryState.fromJson(body('''
      {"success": true, "data": {
        "account_type": "INDIVIDUAL",
        "supported": true,
        "current": {
          "tag_id": "BIKE_RIDER",
          "name": "Bike Rider",
          "profile_type": "GigWork",
          "designation": "Delivery"
        },
        "changes_used": 0,
        "changes_remaining": 1,
        "can_change": true,
        "options_endpoint": "/individual-professions"
      }}
    '''));

    test('reads the individual-only fields', () {
      expect(state.current?.tagId, 'BIKE_RIDER');
      // The catalog spelling, NOT the app enum — normalizeProfileType owns
      // that conversion, and doing it here would hide the mismatch.
      expect(state.current?.profileType, 'GigWork');
      expect(state.current?.designation, 'Delivery');
    });

    test('routes the picker to the professions catalog', () {
      expect(state.usesProfessionsCatalog, isTrue);
    });
  });

  group('ProfileCategoryState — defensive defaults', () {
    test('an unreadable response hides the row rather than offering it', () {
      final state = ProfileCategoryState.fromJson(const {});
      expect(state.supported, isFalse);
      expect(state.canChange, isFalse);
      expect(state.current, isNull);
    });

    test('supported/can_change must be literally true', () {
      final state = ProfileCategoryState.fromJson(
          const {'supported': 'true', 'can_change': 1});
      expect(state.supported, isFalse);
      expect(state.canChange, isFalse);
    });

    test('numeric counters tolerate strings', () {
      final state = ProfileCategoryState.fromJson(
          const {'changes_used': '1', 'changes_remaining': '0'});
      expect(state.changesUsed, 1);
      expect(state.changesRemaining, 0);
    });

    test('GUEST is unsupported', () {
      final state = ProfileCategoryState.fromJson(
          const {'account_type': 'GUEST', 'supported': false});
      expect(state.supported, isFalse);
    });
  });

  group('ProfileCategoryChangeResult (§7)', () {
    final result = ProfileCategoryChangeResult.fromJson(body('''
      {"success": true, "data": {
        "from": "GROCERY_STORE",
        "to": "FOOD_RESTAURANT",
        "current": {
          "tag_id": "FOOD_RESTAURANT",
          "name": "Food & Restaurant",
          "category_type": "Food",
          "sub_category_id": null
        },
        "state": {"can_change": false, "changes_used": 1, "changes_remaining": 0}
      }}
    '''));

    test('reads both ends of the change and the new state', () {
      expect(result.from, 'GROCERY_STORE');
      expect(result.to, 'FOOD_RESTAURANT');
      expect(result.current?.tagId, 'FOOD_RESTAURANT');
      // Cleared because no new sub_category_id was sent — the old one belonged
      // to the old category's tree.
      expect(result.current?.subCategoryId, isNull);
      expect(result.canChange, isFalse);
      expect(result.changesRemaining, 0);
    });

    test('a missing state block reads as spent, not as still available', () {
      final r = ProfileCategoryChangeResult.fromJson(const {'to': 'X'});
      expect(r.canChange, isFalse);
      expect(r.changesUsed, 1);
    });

    test('afterChange updates the row without a second GET', () {
      final before = ProfileCategoryState.fromJson(const {
        'account_type': 'BUSINESS',
        'supported': true,
        'can_change': true,
        'changes_remaining': 1,
        'options_endpoint': '/business/getAllcategories',
      });

      final after = before.afterChange(result);

      expect(after.canChange, isFalse);
      expect(after.changesRemaining, 0);
      expect(after.current?.name, 'Food & Restaurant');
      // Carried over — the change response doesn't repeat them, and losing
      // either would hide the row or misroute the picker.
      expect(after.accountType, 'BUSINESS');
      expect(after.supported, isTrue);
      expect(after.optionsEndpoint, '/business/getAllcategories');
    });
  });

  group('error codes (§8)', () {
    test('only the genuinely un-spent failures are retryable', () {
      for (final code in [
        ProfileCategoryErrorCode.earnProfileSyncFailed,
        ProfileCategoryErrorCode.serverError,
        ProfileCategoryErrorCode.networkError,
      ]) {
        expect(ProfileCategoryException(code: code).isRetryable, isTrue,
            reason: '$code costs the user nothing, so Retry must be offered');
      }
    });

    test('rejections are not retryable', () {
      for (final code in [
        ProfileCategoryErrorCode.sameCategory,
        ProfileCategoryErrorCode.changeLimitReached,
        ProfileCategoryErrorCode.licenseRequired,
        ProfileCategoryErrorCode.unknownCategory,
        ProfileCategoryErrorCode.unsupportedAccountType,
        ProfileCategoryErrorCode.unspecified,
      ]) {
        expect(ProfileCategoryException(code: code).isRetryable, isFalse,
            reason: 'retrying $code just fails the same way');
      }
    });
  });
}
