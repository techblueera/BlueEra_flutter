import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/profile_share_preview/repo/share_profile_overview_repo.dart';
import 'package:BlueEra/features/common/profile_share_preview/service/share_preview_service.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical/service/medical_profile_service.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakeMedicalRepo extends MedicalRepo {
  _FakeMedicalRepo(this.status);

  final int status;

  @override
  Future<ResponseModel> fetchMedicalProfileFd(
          {required String businessId}) async =>
      _res(status, {
        'data': {
          'gallery': [
            {
              'imageUrls': ['a.jpg']
            }
          ],
        },
      });
}

class _FakeFoodRepo extends FoodRepo {
  _FakeFoodRepo(this.body);

  final Object? body;

  @override
  Future<ResponseModel> fetchSingleFoodProductDetailsRepo(
          {required String foodID}) async =>
      _res(200, body);
}

class _FakeGroceryRepo extends GroceryRepo {
  @override
  Future<ResponseModel> fetchGroceryProductByIdRepo(String productId) async =>
      _res(200, {'_id': productId, 'name': 'Basmati rice'});
}

class _FakeProfileRepo extends ShareProfileOverviewRepo {
  _FakeProfileRepo(this.status);

  final int status;

  @override
  Future<ResponseModel> getShareProfileOverview(String userId) async =>
      _res(status, {
        'success': true,
        'user': {'_id': userId, 'name': 'Asha'},
        'totalPosts': 3,
      });
}

void main() {
  group('MedicalProfileService', () {
    test('returns the profile and its raw gallery', () async {
      final result =
          await MedicalProfileService(repo: _FakeMedicalRepo(200)).fetch('b1');

      expect(result, isNotNull);
      expect(result!.gallery, hasLength(1));
    });

    test('null when the load fails', () async {
      expect(
          await MedicalProfileService(repo: _FakeMedicalRepo(500)).fetch('b1'),
          isNull);
    });
  });

  group('SharePreviewService', () {
    test('a product comes back whether or not it is wrapped in data', () async {
      final wrapped = await SharePreviewService(
          foodRepo: _FakeFoodRepo({
        'data': {'_id': 'f1', 'name': 'Paneer tikka'}
      })).foodProduct('f1');
      final bare = await SharePreviewService(
              foodRepo: _FakeFoodRepo({'_id': 'f2', 'name': 'Dal'}))
          .foodProduct('f2');
      final grocery = await SharePreviewService(groceryRepo: _FakeGroceryRepo())
          .groceryProduct('g1');

      expect((wrapped?.id, wrapped?.name), ('f1', 'Paneer tikka'));
      expect(bare?.id, 'f2');
      expect((grocery?.sId, grocery?.name), ('g1', 'Basmati rice'));
    });

    test('nothing to show for a non-object body', () async {
      expect(
          await SharePreviewService(foodRepo: _FakeFoodRepo('oops'))
              .foodProduct('f1'),
          isNull);
    });

    test('the profile overview, or null when the load fails', () async {
      final ok = await SharePreviewService(profileRepo: _FakeProfileRepo(200))
          .profileOverview('u1');
      expect(ok?.totalPosts, 3);

      expect(
          await SharePreviewService(profileRepo: _FakeProfileRepo(404))
              .profileOverview('u1'),
          isNull);
    });
  });
}
