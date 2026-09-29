import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/common_bloc/place/service/place_lookup_service.dart';
import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/saved_address_controller.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:hive/hive.dart';

class _FakePlaceRepo extends PlaceRepo {
  _FakePlaceRepo({this.status = 200});

  final int status;
  final List<String> searched = [];

  @override
  Future<ResponseModel> autoCompleteSearch({required String query}) async {
    searched.add(query);
    return ResponseModel(
      statusCode: status,
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: status,
        data: {
          'predictions': [
            {'description': 'Hazratganj, Lucknow', 'place_id': 'p1'},
          ],
        },
      ),
    );
  }

  @override
  Future<ResolvedPlace?> resolvePlace(String? placeId) async =>
      placeId == 'p1' ? const ResolvedPlace(lat: 26.85, lng: 80.94) : null;
}

void main() {
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync().path));
  setUp(Get.reset);
  tearDown(Get.reset);

  group('PlaceLookupService', () {
    test('returns predictions, and nothing for a blank query or failure',
        () async {
      final repo = _FakePlaceRepo();
      final places = PlaceLookupService(repo: repo);

      expect((await places.search('Hazrat')).single.placeId, 'p1');
      expect(await places.search('  '), isEmpty);
      expect(repo.searched, ['Hazrat']);

      expect(
          await PlaceLookupService(repo: _FakePlaceRepo(status: 500))
              .search('Hazrat'),
          isEmpty);
    });

    test('resolves a tapped prediction to coordinates', () async {
      final places = PlaceLookupService(repo: _FakePlaceRepo());

      final resolved = await places.resolve('p1');
      expect((resolved?.lat, resolved?.lng), (26.85, 80.94));
      expect(await places.resolve('unknown'), isNull);
    });
  });

  group('SavedAddressController', () {
    test('one address book outlives the sheet that opened it first', () {
      final book = SavedAddressController.to;

      // What GetX does when the route under that sheet closes.
      Get.delete<SavedAddressController>();

      expect(SavedAddressController.to, same(book));
    });

    test('logout drops it, so the next account reads its own', () {
      SavedAddressController.to;

      LogoutHelper.resetAccountControllers();

      expect(Get.isRegistered<SavedAddressController>(), isFalse);
    });
  });
}
