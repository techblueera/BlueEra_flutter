import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/Discover/service/public_profile_service.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/reel/service/own_channel_service.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:BlueEra/features/common/rental/service/property_edit_service.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/service/follow_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakeEarnRepo extends EarnProfileRepo {
  _FakeEarnRepo(this.body);

  final Object? body;
  Map<String, dynamic>? query;

  @override
  Future<ResponseModel> fetchEarnProfileByUserId(
      {required String userId, Map<String, dynamic>? queryParams}) async {
    query = queryParams;
    return _res(200, body);
  }
}

class _FakeDoctorRepo extends DoctorProfileRepo {
  _FakeDoctorRepo(this.status);

  final int status;

  @override
  Future<ResponseModel> getPublicProfile({required String ownerUserId}) async =>
      _res(status, {
        'data': {'_id': 'doc1', 'userId': ownerUserId}
      });
}

class _FakeChannelRepo extends ChannelRepo {
  @override
  Future<ResponseModel> getChannelDetails(
          {required String channelOrUserId}) async =>
      _res(404, {'message': 'No channel'});
}

class _FakePropertyRepo extends PropertyRepo {
  _FakePropertyRepo(this.status);

  final int status;

  @override
  Future<ResponseModel> deleteProperty(String id) async =>
      _res(status, {'message': 'Has bookings'});
}

class _FakeUserRepo extends UserRepo {
  _FakeUserRepo({this.status = 200, this.fail = false});

  final int status;
  final bool fail;

  @override
  Future<ResponseModel> followUser({required String? followUserId}) async {
    if (fail) throw Exception('offline');
    return _res(status, {});
  }
}

void main() {
  group('PublicProfileService', () {
    test('an earn profile of the asked type, or nothing', () async {
      final repo = _FakeEarnRepo({
        'data': {'_id': 'e1'}
      });
      final service = PublicProfileService(earnRepo: repo);

      expect(await service.earnProfile('u1', profileType: 'homeService'),
          isNotNull);
      expect(repo.query, {'profileType': 'homeService'});

      expect(
          await PublicProfileService(earnRepo: _FakeEarnRepo({'data': []}))
              .earnProfile('u1', profileType: 'homeService'),
          isNull);
    });

    test('a doctor profile, or nothing for the usual 404', () async {
      final found = await PublicProfileService(doctorRepo: _FakeDoctorRepo(200))
          .doctorProfile('u1');
      expect(found?.id, 'doc1');

      expect(
          await PublicProfileService(doctorRepo: _FakeDoctorRepo(404))
              .doctorProfile('u1'),
          isNull);
    });
  });

  test('OwnChannelService finds no channel when the lookup fails', () async {
    expect(
        await OwnChannelService(repo: _FakeChannelRepo()).fetch('u1'), isNull);
  });

  test('PropertyEditService.delete passes a refusal message on', () async {
    expect(await PropertyEditService(repo: _FakePropertyRepo(200)).delete('p1'),
        isNull);
    expect(await PropertyEditService(repo: _FakePropertyRepo(409)).delete('p1'),
        'Has bookings');
  });

  test('FollowService treats a refusal and a failed call alike', () async {
    expect(await FollowService(repo: _FakeUserRepo()).follow('u1'), isTrue);
    expect(await FollowService(repo: _FakeUserRepo(status: 500)).follow('u1'),
        isFalse);
    expect(await FollowService(repo: _FakeUserRepo(fail: true)).follow('u1'),
        isFalse);
  });
}
