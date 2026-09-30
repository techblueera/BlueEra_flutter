import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/common_bloc/place/service/place_lookup_service.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/auth/service/mobile_update_service.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/service/referral_code_service.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakePlaceRepo extends PlaceRepo {
  _FakePlaceRepo(this.status);

  final int status;

  @override
  Future<ResponseModel> autoCompleteSearch({required String query}) async =>
      _res(status, {
        'predictions': [
          {'description': 'Hazratganj', 'place_id': 'p1'},
        ],
        'error_message': 'Quota exceeded',
      });

  @override
  Future<ResponseModel> getCompletePlaceDetails(
          {required String placeId}) async =>
      _res(200, {
        'result': {
          'formatted_address': 'Hazratganj, Lucknow',
          'geometry': {
            'location': {'lat': 26.85, 'lng': 80.94}
          },
        },
      });
}

class _FakeUserRepo extends UserRepo {
  _FakeUserRepo(this.status, this.data);

  final int status;
  final Object? data;

  @override
  Future<ResponseModel> checkReferralRepo(String refCode) async =>
      _res(status, data);
}

class _FakeAuthRepo extends AuthRepo {
  _FakeAuthRepo(this.status);

  final int status;
  final List<String> calls = [];

  @override
  Future<ResponseModel> requestMobileUpdateOtpRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    calls.add('request:${bodyRequest?['newContactNo']}');
    return _res(status, {'message': 'ok'});
  }

  @override
  Future<ResponseModel> verifyMobileUpdateOtpRepo(
      {Map<String, dynamic>? bodyRequest}) async {
    calls.add('verify:${bodyRequest?['otp']}');
    return _res(status, {'message': 'ok'});
  }
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('PlaceLookupService', () {
    test('a detailed search gives predictions, or Places\' error message',
        () async {
      final ok = await PlaceLookupService(repo: _FakePlaceRepo(200))
          .searchDetailed('Hazrat');
      expect(ok.error, isNull);
      expect(ok.predictions.single.placeId, 'p1');

      final refused = await PlaceLookupService(repo: _FakePlaceRepo(403))
          .searchDetailed('Hazrat');
      expect(refused.error, 'Quota exceeded');
      expect(refused.predictions, isEmpty);
    });

    test('place details carry the whole body and its coordinates', () async {
      final details =
          await PlaceLookupService(repo: _FakePlaceRepo(200)).details('p1');

      expect(details?['result']?['formatted_address'], 'Hazratganj, Lucknow');
      expect(
          PlaceLookupService.coordinatesIn(details), (lat: 26.85, lng: 80.94));
      expect(PlaceLookupService.coordinatesIn(const {}), isNull);
    });
  });

  group('ReferralCodeService', () {
    test('a valid code', () async {
      final result = await ReferralCodeService(
              repo: _FakeUserRepo(200, {'success': true, 'isValid': true}))
          .check('ABC');
      expect(result, (valid: true, message: null));
    });

    test('an unknown code is invalid even on 200, with the server message',
        () async {
      final result = await ReferralCodeService(
          repo: _FakeUserRepo(200, {
        'success': true,
        'isValid': false,
        'message': 'Referral code is invalid',
      })).check('NOPE');
      expect(result, (valid: false, message: 'Referral code is invalid'));
    });

    test('a failed check reports nothing', () async {
      expect(
          await ReferralCodeService(repo: _FakeUserRepo(500, null)).check('X'),
          isNull);
    });
  });

  group('MobileUpdateService', () {
    test('requests then verifies the OTP', () async {
      final repo = _FakeAuthRepo(200);
      final service = MobileUpdateService(repo: repo);

      expect(await service.requestOtp({'newContactNo': '9999999999'}), isTrue);
      expect(await service.verifyOtp({'otp': '1234'}), isTrue);
      expect(repo.calls, ['request:9999999999', 'verify:1234']);
    });

    test('a refusal returns false', () async {
      final service = MobileUpdateService(repo: _FakeAuthRepo(400));

      expect(await service.requestOtp({'newContactNo': '1'}), isFalse);
      expect(await service.verifyOtp({'otp': '0'}), isFalse);
    });
  });
}
