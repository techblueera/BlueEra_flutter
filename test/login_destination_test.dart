import 'dart:convert';

import 'package:BlueEra/core/api/model/otp_verify_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/auth/model/login_destination.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the login routing decision that made 26,831 of 66,913 production
/// accounts (40.1%) look like fresh installs: the app branched on
/// `account_type` to decide whether someone was logged in, so a `GUEST` — and
/// `Admin`, and the literal string `NULL` — matched no branch, had no session
/// persisted, and was dropped signed-out.
///
/// Case numbers below are the table in
/// lib/docs/FLUTTER_LOGIN_EXISTING_USER_FIX_GUIDE.md §6.
void main() {
  group('resolveLoginDestination', () {
    LoginDestination resolve({
      bool userExists = true,
      String? accountType,
      bool needsOnboarding = false,
      bool hasToken = true,
    }) =>
        resolveLoginDestination(
          userExists: userExists,
          accountType: accountType,
          needsOnboarding: needsOnboarding,
          hasToken: hasToken,
        );

    test('case 1 — a GUEST logs in (26,797 rows): a login, not a signup', () {
      expect(
        resolve(accountType: AppConstants.guest, needsOnboarding: true),
        LoginDestination.guest,
      );
      // The regression in one line: the account exists, so it must never be
      // routed to signup, whatever `needs_onboarding` says.
      expect(
        resolve(accountType: AppConstants.guest, needsOnboarding: true),
        isNot(LoginDestination.signup),
      );
    });

    test('case 3 — an existing INDIVIDUAL (35,122 rows)', () {
      expect(resolve(accountType: AppConstants.individual),
          LoginDestination.individual);
    });

    test('case 4 — an existing BUSINESS (4,960 rows)', () {
      expect(
          resolve(accountType: AppConstants.business), LoginDestination.business);
    });

    test('case 5 — account_type "Admin" (32 rows) logs in via the fallback',
        () {
      expect(resolve(accountType: 'Admin'), LoginDestination.individual);
    });

    test('case 6 — the literal string "NULL" (2 rows) logs in too', () {
      expect(resolve(accountType: 'NULL'), LoginDestination.individual);
    });

    test('case 7 — a genuinely new number goes to signup', () {
      expect(
        resolve(userExists: false, accountType: null, hasToken: false),
        LoginDestination.signup,
      );
    });

    test('case 9 — BLUEFLY (0 rows) logs in via the fallback', () {
      expect(
          resolve(accountType: AppConstants.bluefly), LoginDestination.individual);
    });

    test('an account type nobody has shipped yet still logs in', () {
      // The rule the whole fix rests on: an unrecognised `account_type` is a
      // label the app does not know, never a reason to discard a session.
      for (final unknown in const [
        'SOMETHING_NEW',
        'bluefly',
        'Individual',
        '',
        '   ',
      ]) {
        expect(
          resolve(accountType: unknown),
          isNot(LoginDestination.signup),
          reason: 'account_type "$unknown" must not be treated as a new user',
        );
      }
    });

    test('account_type is matched case- and whitespace-insensitively', () {
      expect(resolve(accountType: ' business '), LoginDestination.business);
      expect(resolve(accountType: 'Guest'), LoginDestination.guest);
      expect(resolve(accountType: 'individual'), LoginDestination.individual);
    });

    test('needs_onboarding never demotes a stated real account type', () {
      // A BUSINESS/INDIVIDUAL keeps its own path — being routed down the guest
      // path would store it as GUEST locally and saddle it with every guest
      // restriction in the app.
      expect(
        resolve(accountType: AppConstants.business, needsOnboarding: true),
        LoginDestination.business,
      );
      expect(
        resolve(accountType: AppConstants.individual, needsOnboarding: true),
        LoginDestination.individual,
      );
    });

    test('needs_onboarding is honoured for an unrecognised account type', () {
      expect(
        resolve(accountType: 'SOMETHING_NEW', needsOnboarding: true),
        LoginDestination.guest,
      );
    });

    test(
        'legacy backend: user:false + GUEST + a token is still a guest login',
        () {
      // A deployment on the pre-September whitelist answers `user: false` for
      // a guest while handing over a token (guide §7 deploy-branch warning).
      expect(
        resolve(
            userExists: false,
            accountType: AppConstants.guest,
            hasToken: true),
        LoginDestination.guest,
      );
      // …but with no token there is no session to build: that is a new number.
      expect(
        resolve(
            userExists: false,
            accountType: AppConstants.guest,
            hasToken: false),
        LoginDestination.signup,
      );
    });

    test('user:false is honoured for every account type', () {
      for (final type in const [
        AppConstants.individual,
        AppConstants.business,
        AppConstants.bluefly,
        'Admin',
        'NULL',
        null,
      ]) {
        expect(
          resolve(userExists: false, accountType: type, hasToken: true),
          LoginDestination.signup,
          reason: 'user:false means no account exists, whatever "$type" says',
        );
      }
    });
  });

  group('OtpVerifyModel', () {
    OtpVerifyModel parse(Map<String, dynamic> json) =>
        otpVerifyModelFromJson(jsonEncode(json));

    test('parses the existing-user contract (guide §5)', () {
      final model = parse({
        'success': true,
        'message': 'Login successful',
        'token': '<jwt>',
        'chat_token': null,
        'data': {
          '_id': '68763d966cbe951b99f684da',
          'account_type': 'INDIVIDUAL',
          'contact_no': '9876543210',
          'business': null,
        },
        'user': true,
        'account_type': 'INDIVIDUAL',
        'needs_onboarding': false,
        'isBlocked': false,
        'blockedType': null,
        'account_deletion_cancelled': false,
      });

      expect(model.userExists, isTrue);
      expect(model.accountType, 'INDIVIDUAL');
      expect(model.needsOnboarding, isFalse);
      expect(model.token, '<jwt>');
      expect(model.data?.id, '68763d966cbe951b99f684da');
      expect(model.data?.contactNo, '9876543210');
      expect(model.isBlocked, isFalse);
      expect(model.accountDeletionCancelled, isFalse);
    });

    test('parses the guest contract: exists, with onboarding pending', () {
      final model = parse({
        'success': true,
        'token': '<jwt>',
        'data': {
          '_id': 'abc',
          'account_type': 'GUEST',
          'contact_no': '9876543210',
          'business': null,
        },
        'user': true,
        'account_type': 'GUEST',
        'needs_onboarding': true,
        'isBlocked': false,
      });

      expect(model.userExists, isTrue);
      expect(model.needsOnboarding, isTrue);
      expect(
        resolveLoginDestination(
          userExists: model.userExists == true,
          accountType: model.accountType,
          needsOnboarding: model.needsOnboarding == true,
          hasToken: model.token?.isNotEmpty ?? false,
        ),
        LoginDestination.guest,
      );
    });

    test('parses the new-number contract (a 200 with no data object)', () {
      final model = parse({
        'success': false,
        'user': false,
        'message': 'No User Found. Create A New User',
      });

      expect(model.userExists, isFalse);
      expect(model.data, isNull);
      expect(model.accountType, isNull);
      expect(model.needsOnboarding, isFalse);
      expect(
        resolveLoginDestination(
          userExists: model.userExists == true,
          accountType: model.accountType,
          hasToken: model.token?.isNotEmpty ?? false,
        ),
        LoginDestination.signup,
      );
    });

    test('a missing `user` key is not an account', () {
      final model = parse({'success': true, 'token': '<jwt>'});
      expect(model.userExists, isFalse);
      expect(model.needsOnboarding, isFalse);
    });

    test('stringified booleans are tolerated', () {
      final model = parse({
        'user': 'true',
        'needs_onboarding': 'true',
        'token': '<jwt>',
        'account_type': 'GUEST',
      });
      expect(model.userExists, isTrue);
      expect(model.needsOnboarding, isTrue);
    });

    test('top-level account_type wins over a pre-enum data.account_type', () {
      // The backend guarantees the top-level field is non-null on a
      // successful login; `data.account_type` can still be absent on rows
      // created before the enum existed.
      final model = parse({
        'user': true,
        'token': '<jwt>',
        'account_type': 'BUSINESS',
        'data': {'_id': 'abc', 'contact_no': '9876543210'},
      });

      expect(model.accountType, 'BUSINESS');
      expect(model.data?.accountType, isNull);
      expect(
        resolveLoginDestination(
          userExists: true,
          accountType: model.accountType ?? model.data?.accountType,
          hasToken: true,
        ),
        LoginDestination.business,
      );
    });
  });
}
