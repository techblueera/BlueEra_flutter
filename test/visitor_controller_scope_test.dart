import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Stand-in for the store controllers (Grocery, Restaurant, Inventory, …):
/// all that matters here is which instance a screen ends up holding.
class _StoreController extends GetxController {
  final products = <String>[].obs;
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test("a visitor page never gets the owner's instance", () {
    final owner = getOrPut(() => _StoreController())
      ..products.add('my own product');

    final (visitor, created) =
        putVisitor<_StoreController>('store-b', () => _StoreController());

    expect(created, isTrue);
    expect(visitor, isNot(same(owner)));
    expect(visitor.products, isEmpty);
    expect(owner.products, ['my own product']);
  });

  test('a store page and the sub-pages it opens share one instance', () {
    final (page, pageCreated) =
        putVisitor<_StoreController>('store-b', () => _StoreController());
    page.products.add('store b product');

    // "View all" for the same store builds the same tag.
    final (subPage, subPageCreated) =
        putVisitor<_StoreController>('store-b', () => _StoreController());

    expect(subPage, same(page));
    expect(subPage.products, ['store b product']);
    // Only the page that created it deletes it on dispose.
    expect(pageCreated, isTrue);
    expect(subPageCreated, isFalse);
  });

  test('two different stores never share', () {
    final (b, _) =
        putVisitor<_StoreController>('store-b', () => _StoreController());
    final (c, _) =
        putVisitor<_StoreController>('store-c', () => _StoreController());

    expect(c, isNot(same(b)));
  });

  test("closing the visitor page leaves the owner's instance alone", () {
    final owner = getOrPut(() => _StoreController());
    putVisitor<_StoreController>('store-b', () => _StoreController());

    deleteIfRegistered<_StoreController>(tag: visitTag('store-b'));

    expect(Get.isRegistered<_StoreController>(tag: visitTag('store-b')),
        isFalse);
    expect(Get.isRegistered<_StoreController>(), isTrue);
    expect(Get.find<_StoreController>(), same(owner));
  });
}
