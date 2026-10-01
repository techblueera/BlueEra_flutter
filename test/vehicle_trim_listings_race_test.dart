import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_buyer_controller_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/repo/vehicle_v3_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

/// Answers each trim's listings only when the test says so, so a test can make
/// the first trim's response land after the second trim was opened.
class _ControlledRepo extends VehicleV3Repo {
  final pending = <String, Completer<ResponseModel>>{};

  @override
  Future<ResponseModel> browseListings({
    String? productId,
    String? productVariant,
    String? condition,
    String? pincode,
    double? lat,
    double? lng,
    num? range,
    int page = 1,
    int limit = 20,
  }) =>
      (pending[productId!] = Completer<ResponseModel>()).future;

  void answer(String productId, List<String> listingIds) =>
      pending[productId]!.complete(ResponseModel(
        statusCode: 200,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {
            'data': [
              for (final id in listingIds) {'_id': id},
            ],
          },
        ),
      ));

  void fail(String productId) => pending[productId]!.complete(ResponseModel(
        statusCode: 500,
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
      ));
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test("a late response for the trim the user left doesn't replace this one",
      () async {
    final repo = _ControlledRepo();
    final c = VehicleBuyerControllerV3(repo: repo);

    final first = c.fetchListingsForTrim('trim-a');
    final second = c.fetchListingsForTrim('trim-b');

    repo.answer('trim-b', ['b-1', 'b-2']);
    await second;
    repo.answer('trim-a', ['a-1']); // the slow one, arriving last
    await first;

    expect(c.trimListings.map((l) => l.id), ['b-1', 'b-2']);
    expect(c.trimListingsStatus.value, Status.COMPLETE);
  });

  test("a late failure for the trim the user left doesn't flip this page",
      () async {
    final repo = _ControlledRepo();
    final c = VehicleBuyerControllerV3(repo: repo);

    final first = c.fetchListingsForTrim('trim-a');
    final second = c.fetchListingsForTrim('trim-b');

    repo.answer('trim-b', ['b-1']);
    await second;
    repo.fail('trim-a');
    await first;

    expect(c.trimListingsStatus.value, Status.COMPLETE);
    expect(c.trimListings.map((l) => l.id), ['b-1']);
  });

  test('the current trim still loads normally', () async {
    final repo = _ControlledRepo();
    final c = VehicleBuyerControllerV3(repo: repo);

    final load = c.fetchListingsForTrim('trim-a');
    repo.answer('trim-a', ['a-1']);
    await load;

    expect(c.trimListings.map((l) => l.id), ['a-1']);
    expect(c.trimListingsStatus.value, Status.COMPLETE);
  });
}
