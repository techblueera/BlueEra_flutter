import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/model/food_home_res_model.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The owner's screens and the pages for visiting other stores share these
/// controllers. Asking for a different store has to drop the previous store's
/// lists BEFORE the first await, or the next page paints them (and keeps them
/// if its own fetch fails).
///
/// Only that synchronous part is under test; the fetch that follows goes to
/// the network, so it is left to run out and whatever it ends in is ignored.
void _ignore(Future<void> f) => unawaited(f.catchError((_) {}));

final _done = ApiResponse.complete('loaded');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(Get.reset);
  tearDown(Get.reset);

  group('GroceryController', () {
    GroceryController loadedWith(String store) {
      final c = GroceryController();
      _ignore(c.fetchAllGroceryDataIfNeeded(store, otherStore: true));
      c.groceryCategoryList.add(GroceryCategoryWithInventoryModel.fromJson({}));
      c.groceryBusinessProductsList.add(BusinessProductData.fromJson({}));
      c.fetchMyGroceryCategoryResponse.value = _done;
      c.fetchGroceryBusinessProductsResponse.value = _done;
      return c;
    }

    test('another store drops the previous store at once', () {
      final c = loadedWith('store-a');
      _ignore(c.fetchAllGroceryDataIfNeeded('store-b', otherStore: true));

      expect(c.groceryCategoryList, isEmpty);
      expect(c.groceryBusinessProductsList, isEmpty);
      expect(c.fetchMyGroceryCategoryResponse.value.status, Status.INITIAL);
      expect(
          c.fetchGroceryBusinessProductsResponse.value.status, Status.INITIAL);
    });

    test('the same store keeps what it has', () {
      final c = loadedWith('store-a');
      _ignore(c.fetchAllGroceryDataIfNeeded('store-a', otherStore: true));

      expect(c.groceryCategoryList, hasLength(1));
      expect(c.groceryBusinessProductsList, hasLength(1));
    });
  });

  group('RestaurantController', () {
    RestaurantController loadedWith(String store) {
      final c = RestaurantController();
      _ignore(c.fetchHomeAndDiscountIfNeeded(businessId: store));
      c.restaurantData.value = FoodData.fromJson({});
      c.foodMenuNestedCategory.add(GroceryNestedCategoryModel.fromJson({}));
      c.foodHomeDataResponse.value = _done;
      return c;
    }

    test('another restaurant drops the previous menu at once', () {
      final c = loadedWith('store-a');
      _ignore(c.fetchHomeAndDiscountIfNeeded(businessId: 'store-b'));

      expect(c.restaurantData.value, isNull);
      expect(c.foodMenuNestedCategory, isEmpty);
      expect(c.foodHomeDataResponse.value.status, Status.INITIAL);
    });

    test('the same restaurant keeps its menu', () {
      final c = loadedWith('store-a');
      _ignore(c.fetchHomeAndDiscountIfNeeded(businessId: 'store-a'));

      expect(c.restaurantData.value, isNotNull);
      expect(c.foodMenuNestedCategory, hasLength(1));
    });
  });

  group('InventoryController', () {
    InventoryController loadedWith(String store) {
      final c = InventoryController();
      _ignore(c.fetchAllProductDataIfNeeded(visitUserId: store));
      c.productNestedCategoryList
          .add(ProductCategoryWithInventoryModel.fromJson({}));
      c.allProducts.add(GetProductData.fromJson({}));
      c.fetchProductCategoryResponse.value = _done;
      c.ownDraftAndPublicProductResponse.value = _done;
      return c;
    }

    test('another store drops the previous store at once', () {
      final c = loadedWith('store-a');
      _ignore(c.fetchAllProductDataIfNeeded(visitUserId: 'store-b'));

      expect(c.productNestedCategoryList, isEmpty);
      expect(c.allProducts, isEmpty);
      expect(c.fetchProductCategoryResponse.value.status, Status.INITIAL);
      expect(c.ownDraftAndPublicProductResponse.value.status, Status.INITIAL);
    });

    test('a direct, non-silent load of another store also switches', () {
      final c = loadedWith('store-a');
      _ignore(c.fetchAllProductData(visitUserId: 'store-b'));

      expect(c.productNestedCategoryList, isEmpty);
      expect(c.allProducts, isEmpty);
    });

    test("the owner's silent write-back never wipes the page", () {
      final c = loadedWith('store-a');
      _ignore(c.fetchAllProductData(silent: true));

      expect(c.productNestedCategoryList, hasLength(1));
      expect(c.allProducts, hasLength(1));
    });
  });

  group('AutomotiveInventoryController', () {
    test('another store drops the previous store at once', () {
      final c = AutomotiveInventoryController();
      _ignore(c.fetchAllProductData(visitUserId: 'store-a'));
      c.productNestedCategoryList
          .add(AutomotiveProductCategoryWithInventoryModel.fromJson({}));
      c.allProducts.add(GetProductData.fromJson({}));

      _ignore(c.fetchAllProductData(visitUserId: 'store-b'));

      expect(c.productNestedCategoryList, isEmpty);
      expect(c.allProducts, isEmpty);
    });
  });

  group('ManufacturerInventoryController', () {
    test('another store drops the previous store at once', () {
      final c = ManufacturerInventoryController();
      _ignore(c.fetchAllProductData(visitBusinessId: 'store-a'));
      c.productNestedCategoryList
          .add(ProductCategoryWithInventoryModel.fromJson({}));
      c.allProducts.add(GetProductData.fromJson({}));

      _ignore(c.fetchAllProductData(visitBusinessId: 'store-b'));

      expect(c.productNestedCategoryList, isEmpty);
      expect(c.allProducts, isEmpty);
    });
  });
}
