import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/Discover/repo/favorite_location_repo.dart';
import 'package:BlueEra/features/common/Discover/service/favourite_location_service.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';

/// Answers the save with [status] and [data].
class _FakeFavoriteRepo extends FavoriteLocationRepo {
  _FakeFavoriteRepo(this.status, this.data);

  final int status;
  final Object? data;

  @override
  Future<ResponseModel> addFavoriteLocation({
    required String address,
    required double latitude,
    required double longitude,
    required String tag,
    String? label,
    Map<String, dynamic>? metadata,
  }) async =>
      ResponseModel(
        statusCode: status,
        response: Response(
            requestOptions: RequestOptions(), statusCode: status, data: data),
      );
}

Map<String, dynamic> _fav(String id) => {
      '_id': id,
      'address': 'Office',
      'tag': 'office',
      'location': {
        'coordinates': [80.9, 26.8]
      },
    };

void main() {
  Future<dynamic> save(int status, Object? data) =>
      FavouriteLocationService(repo: _FakeFavoriteRepo(status, data)).add(
          address: 'Office', latitude: 26.8, longitude: 80.9, tag: 'office');

  test('reads the saved favourite whether or not it is nested', () async {
    expect((await save(200, _fav('f1'))).id, 'f1');
    expect((await save(200, {'favorite': _fav('f2')})).id, 'f2');
  });

  test('falls back to a local copy when the response has no favourite',
      () async {
    final saved = await save(200, {'message': 'ok'});
    expect(saved.address, 'Office');
    expect(saved.tag, 'office');
  });

  test('a refusal throws with the server message', () async {
    await expectLater(
      save(400, {'message': 'Already saved'}),
      throwsA(isA<FavouriteSaveError>()
          .having((e) => e.message, 'message', 'Already saved')),
    );
  });
}
