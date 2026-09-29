import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/features/common/Discover/binding/search_address_binding.dart';
import 'package:BlueEra/features/common/Discover/controller/search_address_controller.dart';
import 'package:BlueEra/features/common/Discover/repo/favorite_location_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

Map<String, dynamic> _fav(String id, String address) => {
      '_id': id,
      'address': address,
      'tag': 'Home',
      'location': {
        'coordinates': [80.9, 26.8]
      },
    };

class _FakePlaceRepo extends PlaceRepo {
  final List<String> searched = [];
  final List<String?> resolved = [];

  @override
  Future<ResponseModel> autoCompleteSearch({required String query}) async {
    searched.add(query);
    return _res(200, {
      'predictions': [
        {'description': '$query Road', 'place_id': 'p1'},
      ],
    });
  }

  @override
  Future<ResolvedPlace?> resolvePlace(String? placeId) async {
    resolved.add(placeId);
    return placeId == 'missing' ? null : const ResolvedPlace(lat: 1, lng: 2);
  }
}

class _FakeFavoriteRepo extends FavoriteLocationRepo {
  _FakeFavoriteRepo({this.failDelete = false});

  final bool failDelete;
  final List<String> deleted = [];

  @override
  Future<ResponseModel> listFavorites(
          {String? tag, String? search, int page = 1, int limit = 50}) async =>
      _res(200, {
        'favorites': [_fav('f1', 'Office')]
      });

  @override
  Future<ResponseModel> deleteFavorite(String id) async {
    deleted.add(id);
    return failDelete ? _res(500, {'message': 'nope'}) : _res(200, {});
  }

  @override
  Future<ResponseModel> addFavoriteLocation({
    required String address,
    required double latitude,
    required double longitude,
    required String tag,
    String? label,
    Map<String, dynamic>? metadata,
  }) async =>
      _res(200, {'favorite': _fav('f2', address)});
}

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);

  Future<SearchAddressController> ready(
      {_FakePlaceRepo? place, _FakeFavoriteRepo? fav}) async {
    final c = SearchAddressController(
        placeRepo: place ?? _FakePlaceRepo(),
        favoriteRepo: fav ?? _FakeFavoriteRepo());
    c.onInit();
    await c.loadFavourites();
    return c;
  }

  test('loads favourites and recent searches on open', () async {
    SharedPreferences.setMockInitialValues({
      SearchAddressController.recentSearchesKey: [
        '{"lat":1.0,"lng":2.0,"address":"Station"}'
      ],
    });
    final c = await ready();
    await c.loadRecentSearches();

    expect(c.favourites.map((f) => f.id), ['f1']);
    expect(c.isFavourited('Office'), isTrue);
    expect(c.recentSearches.single['address'], 'Station');
  });

  test('typing searches once after the pause, clearing empties it', () async {
    final place = _FakePlaceRepo();
    final c = await ready(place: place);

    c.onQueryChanged('Ha');
    c.onQueryChanged('Hazrat ');
    await Future<void>.delayed(SearchAddressController.searchDebounce * 2);

    expect(place.searched, ['Hazrat']);
    expect(c.searchQuery.value, 'Hazrat');
    expect(c.predictions.single.placeId, 'p1');

    c.clearSearch();
    expect(c.predictions, isEmpty);
    expect(c.searchQuery.value, isEmpty);
  });

  test('selecting resolves coordinates once and reports failures', () async {
    final place = _FakePlaceRepo();
    final c = await ready(place: place);
    final p = PlacePrediction(description: 'Somewhere', placeId: 'p1');

    expect(await c.selectPrediction(p), isTrue);
    expect((p.lat, p.lng), (1.0, 2.0));
    // Favouriting the same row now needs no second lookup.
    expect(await c.resolveCoordinates(p), isTrue);
    expect(place.resolved, ['p1']);
    expect(c.resolvingPlaceId.value, isNull);

    final missing = PlacePrediction(description: 'Nowhere', placeId: 'missing');
    expect(await c.selectPrediction(missing), isFalse);
  });

  test('recent searches move to the top and are capped', () async {
    final c = await ready();
    for (var i = 0; i < 12; i++) {
      await c.saveRecentSearch(0, 0, 'Place $i');
    }
    await c.saveRecentSearch(0, 0, 'Place 5');

    expect(c.recentSearches.length, SearchAddressController.maxRecentSearches);
    expect(c.recentSearches.first['address'], 'Place 5');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(SearchAddressController.recentSearchesKey),
        hasLength(SearchAddressController.maxRecentSearches));
  });

  test('adding and removing favourites keeps the list in step', () async {
    final fav = _FakeFavoriteRepo();
    final c = await ready(fav: fav);

    final added = await c.addFavourite(
        address: 'Gym',
        latitude: 1,
        longitude: 2,
        tag: 'Gym',
        isCustomTag: true);
    expect(added.id, 'f2');
    expect(c.favourites.first.address, 'Gym');

    expect(await c.removeFavourite(c.findFavourite('Office')!), isNull);
    expect(fav.deleted, ['f1']);
    expect(c.isFavourited('Office'), isFalse);
  });

  test('a failed removal keeps the favourite', () async {
    final c = await ready(fav: _FakeFavoriteRepo(failDelete: true));

    expect(await c.removeFavourite(c.findFavourite('Office')!), isNotNull);
    expect(c.isFavourited('Office'), isTrue);
  });

  test('the binding gives each visit a fresh controller', () {
    SearchAddressBinding().dependencies();
    final first = Get.find<SearchAddressController>();
    Get.delete<SearchAddressController>();
    SearchAddressBinding().dependencies();

    expect(Get.find<SearchAddressController>(), isNot(same(first)));
  });
}
