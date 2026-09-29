import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/food/service/food_variant_inventory_service.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

/// Answers with [status] and records what was written.
class _FakeFoodRepo extends FoodRepo {
  _FakeFoodRepo({this.status = 200, this.price});

  final int status;
  final Map<String, dynamic>? price;
  Map<String, dynamic>? written;
  final List<String> flipped = [];
  final List<String> deleted = [];

  @override
  Future<ResponseModel> getKitchenInventoryByIdRepo(
          {required String inventoryId}) async =>
      _res(200, {
        'data': {'price': price}
      });

  @override
  Future<ResponseModel> updateKitchenInventoryVariantRepo(
      {required String inventoryId,
      required Map<String, dynamic> params}) async {
    written = params;
    return _res(status, {'message': 'nope'});
  }

  @override
  Future<ResponseModel> flipOutOfStockRepo(
      {required List<String> inventoryIds}) async {
    flipped.addAll(inventoryIds);
    return _res(status, {'message': 'nope'});
  }

  @override
  Future<ResponseModel> deleteKitchenInventoryRepo(
      {required String inventoryId}) async {
    deleted.add(inventoryId);
    return _res(status, {'message': 'nope'});
  }
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  // The sheet edits its own copy of a variant; the shared product holds
  // another object for the same inventory record.
  FoodVariants variant() =>
      FoodVariants(inventoryId: 'inv1', mrp: 100, baseSellingPrice: 90);
  CategoryFoodProductData product() => CategoryFoodProductData(
      variants: [variant(), FoodVariants(inventoryId: 'inv2')]);

  test('a price edit keeps the charges it did not touch', () async {
    final repo = _FakeFoodRepo(
        price: {'mrp': 100, 'sellingPrice': 90, 'packingCharges': 20});
    final p = product();
    final item = variant();

    final error = await FoodVariantInventoryService(repo: repo)
        .updatePrice(p, item, sellingPrice: 80, mrp: 120);

    expect(error, isNull);
    expect(repo.written, {
      'price': {'mrp': 120, 'sellingPrice': 80, 'packingCharges': 20}
    });
    expect((item.mrp, item.baseSellingPrice), (120, 80));
    expect(
        (p.variants!.first.mrp, p.variants!.first.baseSellingPrice), (120, 80));
  });

  test('a price edit aborts when the current price cannot be read', () async {
    final repo = _FakeFoodRepo(price: null);
    final item = variant();

    final error = await FoodVariantInventoryService(repo: repo)
        .updatePrice(product(), item, sellingPrice: 80, mrp: 120);

    expect(error, isNotNull);
    expect(repo.written, isNull);
    expect(item.mrp, 100);
  });

  test('a stock flip mirrors onto the shared product only when accepted',
      () async {
    final ok = _FakeFoodRepo();
    final p = product();
    expect(
        await FoodVariantInventoryService(repo: ok)
            .setOutOfStock(p, variant(), true),
        isNull);
    expect(ok.flipped, ['inv1']);
    expect(p.variants!.first.isOutOfStock, isTrue);

    final refused = product();
    expect(
        await FoodVariantInventoryService(repo: _FakeFoodRepo(status: 500))
            .setOutOfStock(refused, variant(), true),
        isNotNull);
    expect(refused.variants!.first.isOutOfStock, isNull);
  });

  test('a delete drops the variant from the shared product', () async {
    final repo = _FakeFoodRepo();
    final p = product();

    expect(await FoodVariantInventoryService(repo: repo).delete(p, variant()),
        isNull);
    expect(repo.deleted, ['inv1']);
    expect(p.variants!.map((v) => v.inventoryId), ['inv2']);

    final kept = product();
    expect(
        await FoodVariantInventoryService(repo: _FakeFoodRepo(status: 500))
            .delete(kept, variant()),
        isNotNull);
    expect(kept.variants, hasLength(2));
  });
}
