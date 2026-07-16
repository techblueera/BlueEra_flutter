import 'package:BlueEra/features/common/search/model/store_match_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape per docs/backend/SEARCH_ORDER_FLUTTER_GUIDE.md step 2.
Map<String, dynamic> _store() => {
      'businessId': 'biz_1',
      'businessName': 'Sharma Kirana',
      'matchingVariantCount': 2,
      'minSellingPrice': 45,
      'totalStock': 30,
      'inventories': [
        {
          'inventoryId': 'inv_500g',
          'productVariant': {
            '_id': 'var_500g',
            'variantName': 'Tata Salt 500g Pack',
            'unit': 'g',
            'quantity': '500',
            'isVegetarian': true,
            'pricing': [
              {'mrp': 60, 'sellingPrice': 50, 'currency': 'INR'}
            ],
          },
          'batches': [
            {'quantity': '12', 'mrp': 60, 'sellingPrice': 45},
            {'quantity': '8', 'mrp': 60, 'sellingPrice': 47},
          ],
        },
        {
          'inventoryId': 'inv_1kg',
          'productVariant': {
            '_id': 'var_1kg',
            'unit': 'kg',
            'quantity': '1',
            'pricing': [
              {'mrp': 100, 'sellingPrice': 85}
            ],
          },
          'isOutOfStock': true,
          'batches': [],
        },
      ],
    };

void main() {
  test('parses grocery pack size, price and stock from inventory rows', () {
    final store = StoreMatch.fromJson(_store());
    expect(store.variantOptions.length, 2);

    final small = store.variantOptions.first;
    expect(small.packLabel, '500 g'); // quantity + unit, not the variant name
    expect(small.sellingPrice, 45); // batch price wins over pricing[]
    expect(small.mrp, 60);
    expect(small.discountPercent, 25);
    expect(small.stock, 20); // summed across batches
    expect(small.inStock, isTrue);
    expect(small.isVegetarian, isTrue);

    final large = store.variantOptions[1];
    expect(large.packLabel, '1 kg');
    expect(large.sellingPrice, 85); // falls back to pricing[] with no batches
    expect(large.stock, 0); // isOutOfStock flag
    expect(large.inStock, isFalse);
    expect(large.isVegetarian, isNull); // absent => unknown, not "non-veg"
  });

  test('unknown stock stays null rather than reading as out of stock', () {
    final raw = _store();
    (raw['inventories'] as List).clear();
    (raw['inventories'] as List).add({
      'inventoryId': 'inv_x',
      'productVariant': {'_id': 'var_x', 'unit': 'ml', 'quantity': '200'},
    });
    final option = StoreMatch.fromJson(raw).variantOptions.single;
    expect(option.stock, isNull);
    expect(option.inStock, isNull);
    expect(option.packLabel, '200 ml');
  });

  test('order line pins the selected pack', () {
    final store = StoreMatch.fromJson(_store());

    final picked = store.orderLineFor('var_1kg')!;
    expect(picked.inventoryId, 'inv_1kg');
    expect(picked.productVariantId, 'var_1kg');
    expect(picked.sellingPrice, 85);

    // No selection => first orderable line, as before.
    expect(store.firstOrderableLine!.inventoryId, 'inv_500g');
    // A pack this store doesn't carry => no line (caller falls back).
    expect(store.orderLineFor('var_missing'), isNull);
    expect(store.stocksVariant('var_500g'), isTrue);
    expect(store.stocksVariant('var_missing'), isFalse);
  });

  // The backend has been seen to stop populating the top-level rollups (the
  // sibling business-products response hit the same thing). A null rollup must
  // not read as zero — that made every store show "Out of stock".
  test('missing stock rollup falls back to the inventory rows', () {
    final raw = _store()
      ..remove('totalStock')
      ..remove('minSellingPrice');
    final store = StoreMatch.fromJson(raw);

    expect(store.reportedTotalStock, isNull);
    expect(store.totalStock, 20); // 20 in batches + the out-of-stock 1 kg row
    expect(store.inStock, isTrue, reason: 'stocked store must not read empty');
    expect(store.minSellingPrice, 45); // cheapest row, not 0
  });

  test('stock reads unknown — not out of stock — when nothing reports it', () {
    final raw = _store()
      ..remove('totalStock')
      ..remove('minSellingPrice');
    raw['inventories'] = [
      {
        'inventoryId': 'inv_x',
        'productVariant': {
          '_id': 'var_x',
          'unit': 'kg',
          'quantity': '1',
          'pricing': [
            {'sellingPrice': 99}
          ],
        },
      },
    ];
    final store = StoreMatch.fromJson(raw);

    expect(store.totalStock, isNull);
    expect(store.inStock, isNull);
    expect(store.minSellingPrice, 99);
  });

  test('an explicit zero rollup still means out of stock', () {
    final raw = _store();
    raw['totalStock'] = 0;
    expect(StoreMatch.fromJson(raw).inStock, isFalse);
  });

  test('rows without an inventoryId are skipped, not half-parsed', () {
    final raw = _store();
    (raw['inventories'] as List).add({
      'productVariant': {'_id': 'var_orphan', 'unit': 'kg', 'quantity': '5'},
    });
    final store = StoreMatch.fromJson(raw);
    expect(store.variantOptions.map((o) => o.variantId),
        isNot(contains('var_orphan')));
  });
}
