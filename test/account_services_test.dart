import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/account_plan/repo/account_plan_repo.dart';
import 'package:BlueEra/features/account_plan/service/deposit_migration_service.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/auth/service/gst_verify_service.dart';
import 'package:BlueEra/features/common/joining_bounce/service/joining_bonus_claim_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/repo/joining_bounce_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakePlanRepo extends AccountPlanRepo {
  _FakePlanRepo({this.eligibilityStatus = 200, this.migrateBody});

  final int eligibilityStatus;
  final Object? migrateBody;

  @override
  Future<ResponseModel> migrationEligibility() async =>
      _res(eligibilityStatus, {
        'data': {'eligible': true, 'already_migrated': false}
      });

  @override
  Future<ResponseModel> migrate() async => _res(200, migrateBody);
}

class _FakeAuthRepo extends AuthRepo {
  _FakeAuthRepo(this.status, this.body);

  final int status;
  final Object? body;

  @override
  Future<ResponseModel> getUserVerifyGstRepo(
          {required String? gstNumber, bool showProgress = false}) async =>
      _res(status, body);
}

class _FakeBounceRepo extends JoiningBounceRepo {
  _FakeBounceRepo(this.status, this.message);

  final int status;
  final String? message;
  String? claimedTag;

  @override
  Future<ResponseModel> createClaim(
      {required String tagId, String? accountType}) async {
    claimedTag = tagId;
    return _res(status, {'message': message});
  }
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('DepositMigrationService', () {
    test('reads the eligibility, or nothing when the check fails', () async {
      final ok =
          await DepositMigrationService(repo: _FakePlanRepo()).eligibility();
      expect(ok?.eligible, isTrue);

      expect(
          await DepositMigrationService(
                  repo: _FakePlanRepo(eligibilityStatus: 500))
              .eligibility(),
          isNull);
    });

    test('a refused migration carries the server message', () async {
      final result = await DepositMigrationService(
              repo: _FakePlanRepo(
                  migrateBody: {'success': false, 'message': 'No deposit'}))
          .migrate();

      expect(result, (ok: false, already: false, message: 'No deposit'));
    });
  });

  group('GstVerifyService', () {
    test('prefers the GSTIN the verifier echoed back', () async {
      final result = await GstVerifyService(
          repo: _FakeAuthRepo(200, {
        'is_verified': true,
        'data': {'gstin': ' 09abcde1234f1z5 '}
      })).verify('09ABCDE1234F1Z5');

      expect(result.verified, isTrue);
      expect(result.gstin, '09ABCDE1234F1Z5');
    });

    test('tells an unverified number from a failed call', () async {
      final unverified = await GstVerifyService(
          repo: _FakeAuthRepo(200, {'is_verified': false})).verify('X');
      final failed =
          await GstVerifyService(repo: _FakeAuthRepo(500, null)).verify('X');

      expect((unverified.verified, unverified.failed), (false, false));
      expect((failed.verified, failed.failed), (false, true));
    });
  });

  group('JoiningBonusClaimService', () {
    test('claims with the tag and passes the server message on', () async {
      final repo = _FakeBounceRepo(200, 'Bonus added');

      final result =
          await JoiningBonusClaimService(repo: repo).claim(tagId: 't1');

      expect(repo.claimedTag, 't1');
      expect(result, (ok: true, message: 'Bonus added'));
    });

    test('an empty server message becomes null', () async {
      final result =
          await JoiningBonusClaimService(repo: _FakeBounceRepo(400, ''))
              .claim(tagId: 't1');

      expect(result, (ok: false, message: null));
    });
  });
}
