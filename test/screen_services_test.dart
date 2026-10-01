import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/business/auth/service/profile_rating_service.dart';
import 'package:BlueEra/features/common/delivery_partner/service/customer_identity_service.dart';
import 'package:BlueEra/features/common/reel/service/video_actions.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:BlueEra/features/common/rental/service/property_edit_service.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/repo/ride_booking_repo.dart';
import 'package:BlueEra/features/ride_booking/service/ride_feedback_service.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakeRideRepo extends RideBookingRepo {
  _FakeRideRepo({this.fail = false});

  final bool fail;
  final List<String> calls = [];

  @override
  Future<RideRatingResult?> rateRide({
    required String orderId,
    required int rating,
    List<String> tags = const [],
    String? comment,
  }) async {
    calls.add('rate:$orderId:$rating:${tags.join(',')}');
    if (fail) throw Exception('offline');
    return const RideRatingResult(success: true, riderAverage: 4.5);
  }

  @override
  Future<RideReportResult?> reportRide(
      {required String orderId,
      required String reason,
      String? comment}) async {
    calls.add('report:$orderId:$reason');
    if (fail) throw Exception('offline');
    return const RideReportResult(success: true, reportId: 'R1');
  }
}

/// Serves one user profile (and, for businesses, a business profile), and
/// counts the lookups.
class _FakeUserRepo extends UserRepo {
  _FakeUserRepo(this.profile, {this.followStatus = 200});

  final Map<String, dynamic> profile;
  final int followStatus;
  int lookups = 0;
  final List<String> follows = [];

  @override
  Future<ResponseModel> getUserById({required String? userId}) async {
    lookups++;
    return _res(200, {'user': profile});
  }

  @override
  Future<ResponseModel> followUser({required String? followUserId}) async {
    follows.add('follow:$followUserId');
    return _res(followStatus, {'message': 'nope'});
  }

  @override
  Future<ResponseModel> unfollowUser({required String? followUserId}) async {
    follows.add('unfollow:$followUserId');
    return _res(followStatus, {'message': 'nope'});
  }
}

class _FakeBusinessRepo extends BusinessProfileRepo {
  @override
  Future<ResponseModel> viewBusinessProfileById(String? userId) async =>
      _res(200, {
        'data': {
          'category_details': {'name': 'Restaurant'},
          'sub_category_details': {'name': 'Bakery'},
        },
      });
}

/// Records ratings and answers with [status].
class _FakeRatingRepo extends BusinessProfileRepo {
  _FakeRatingRepo(this.status);

  final int status;
  final List<String> sent = [];

  @override
  Future<ResponseModel> submitRatingToBusinessAccount(
      String businessId, Map<String, dynamic> params) async {
    sent.add('business:$businessId:${params['rating']}:${params['comment']}');
    return _res(status, {'message': 'Already rated'});
  }

  @override
  Future<ResponseModel> submitRatingToPersonal(
      String userId, Map<String, dynamic> params) async {
    sent.add('person:$userId:${params['rating']}');
    return _res(status, {'message': 'Already rated'});
  }
}

class _FakePropertyRepo extends PropertyRepo {
  _FakePropertyRepo({this.status = 200});

  final int status;
  Map<String, dynamic>? written;

  @override
  Future<ResponseModel> updateProperty(String id, Map<String, dynamic> body,
      {bool isMultipart = false}) async {
    written = body;
    return _res(status, {'message': 'Not allowed'});
  }

  @override
  Future<ResponseModel> getPropertyById(String id) async => _res(200, {
        'data': {'_id': id, 'propertyName': 'Sunny flat'}
      });
}

void main() {
  setUp(() {
    Get.reset();
    CustomerIdentityService.clearCache();
  });
  tearDown(Get.reset);

  group('RideFeedbackService', () {
    test('rates and reports the ride', () async {
      final repo = _FakeRideRepo();
      final feedback = RideFeedbackService(repo: repo);

      final rating = await feedback.rate(
          orderId: 'o1', rating: 5, tags: ['polite'], comment: 'Great');
      final report = await feedback.report(orderId: 'o1', reasonSlug: 'rude');

      expect(rating?.riderAverage, 4.5);
      expect(report?.reportId, 'R1');
      expect(repo.calls, ['rate:o1:5:polite', 'report:o1:rude']);
    });

    test('fails soft, and skips a ride with no order id', () async {
      final repo = _FakeRideRepo(fail: true);
      final feedback = RideFeedbackService(repo: repo);

      expect(await feedback.rate(orderId: 'o1', rating: 4, tags: []), isNull);
      expect(await feedback.report(orderId: '', reasonSlug: 'rude'), isNull);
      expect(repo.calls, ['rate:o1:4:']);
    });
  });

  group('CustomerIdentityService', () {
    test('an individual reads as their profession, looked up once', () async {
      final users = _FakeUserRepo({'profession': 'Plumber'});
      final service = CustomerIdentityService(userRepo: users);

      final identities =
          await Future.wait([service.fetch('u1'), service.fetch('u1')]);
      await service.fetch('u1');

      expect(identities.map((i) => i?.label), ['Plumber', 'Plumber']);
      expect(identities.first?.isBusiness, isFalse);
      expect(CustomerIdentityService.cached('u1')?.label, 'Plumber');
      expect(users.lookups, 1);
    });

    test('a business reads as its category and sub-category', () async {
      final service = CustomerIdentityService(
        userRepo: _FakeUserRepo({'account_type': 'BUSINESS'}),
        businessRepo: _FakeBusinessRepo(),
      );

      final identity = await service.fetch('b1');

      expect(identity?.label, 'Restaurant · Bakery');
      expect(identity?.isBusiness, isTrue);
    });

    test('a sub-category that repeats the category is dropped', () {
      expect(
          CustomerIdentity.of('Bakery', secondary: 'bakery')?.label, 'Bakery');
      expect(CustomerIdentity.of('  '), isNull);
    });
  });

  group('VideoActions.setFollowing', () {
    test('follows or unfollows, and reports a refusal', () async {
      final users = _FakeUserRepo(const {});
      expect(
          await VideoActions(userRepo: users).setFollowing('a1', follow: true),
          isTrue);
      expect(
          await VideoActions(userRepo: users).setFollowing('a1', follow: false),
          isTrue);
      expect(users.follows, ['follow:a1', 'unfollow:a1']);

      final refusing = _FakeUserRepo(const {}, followStatus: 500);
      expect(
          await VideoActions(userRepo: refusing)
              .setFollowing('a1', follow: true),
          isFalse);
    });
  });

  group('ProfileRatingService', () {
    test('rates a business and a person, trimming the comment', () async {
      final repo = _FakeRatingRepo(200);
      final ratings = ProfileRatingService(repo: repo);

      expect(await ratings.rateBusiness('b1', stars: 5, comment: '  Lovely  '),
          isNull);
      expect(await ratings.ratePerson('u1', stars: 4), isTrue);
      expect(repo.sent, ['business:b1:5:Lovely', 'person:u1:4']);
    });

    test('a refusal carries the server message', () async {
      final ratings = ProfileRatingService(repo: _FakeRatingRepo(409));

      expect(await ratings.rateBusiness('b1', stars: 3), 'Already rated');
      expect(await ratings.ratePerson('u1', stars: 3), isFalse);
    });
  });

  group('PropertyEditService', () {
    test('an accepted edit comes back with the re-read listing', () async {
      final repo = _FakePropertyRepo();

      final result = await PropertyEditService(repo: repo)
          .updateFields('p1', {'title': 'Sunny flat'});

      expect(result.ok, isTrue);
      expect(repo.written, {'title': 'Sunny flat'});
      expect(result.property?.id, 'p1');
    });

    test('a refused edit carries the server message', () async {
      final result =
          await PropertyEditService(repo: _FakePropertyRepo(status: 403))
              .updateFields('p1', {'title': 'x'});

      expect(result.ok, isFalse);
      expect(result.property, isNull);
      expect(result.message, 'Not allowed');
    });
  });
}
