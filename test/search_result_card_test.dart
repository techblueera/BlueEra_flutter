import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/common/search/widget/search_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// A shop row as the search service returns it. Overrides let each test strip
/// fields back to null/empty to check the degraded rendering.
SearchResultItem _item([Map<String, dynamic> overrides = const {}]) {
  return SearchResultItem.fromJson({
    '_id': 'r1',
    'entityType': 'business',
    'title': 'Gupta General Store',
    'subtitle': 'General Store',
    'imageUrl': null,
    'rating': 4.8,
    'distanceMeters': 4500,
    'distanceText': '4.5 Km',
    'address': 'Sastri Nagar, Lucknow, Uttar Pradesh, 226001',
    'productCount': 10000,
    ...overrides,
  });
}

/// Pumps the card at a real device width. The test default (800x600) is wider
/// than any phone, so it would hide exactly the overflows this card has to
/// survive.
Future<void> _pump(
  WidgetTester tester,
  SearchResultItem item, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SearchResultCard(item: item, onTap: () {}),
            ),
          ),
        );
      }),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders a fully-populated shop row', (tester) async {
    await _pump(tester, _item());

    expect(find.text('Gupta General Store'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('General Store'), findsOneWidget);
    expect(find.text('4.5 Km'), findsOneWidget);
    expect(find.text('Sastri Nagar, Lucknow, Uttar Pradesh, 226001'),
        findsOneWidget);
    // 10,000 products abbreviates to the badge's "10K".
    expect(find.text('10K'), findsOneWidget);
    expect(find.text(AppStrings.globalSearchProducts.tr), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to an entity placeholder when there is no image',
      (tester) async {
    await _pump(tester, _item({'imageUrl': ''}));
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row with nothing but an id still renders placeholders',
      (tester) async {
    await _pump(
      tester,
      _item({
        'title': '',
        'subtitle': null,
        'rating': null,
        'distanceMeters': null,
        'distanceText': null,
        'address': null,
        'productCount': null,
      }),
    );

    expect(find.text(AppStrings.globalSearchUntitled.tr), findsOneWidget);
    expect(find.text(AppStrings.globalSearchNoRating.tr), findsOneWidget);
    expect(find.text(AppStrings.globalSearchLocationUnavailable.tr),
        findsOneWidget);
    // No count and no price — the badge is dropped rather than left empty.
    expect(find.text(AppStrings.globalSearchProducts.tr), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a catalogue row shows its price and drops the location line',
      (tester) async {
    await _pump(
      tester,
      _item({
        'entityType': 'product',
        'title': 'Aashirvaad Atta 5kg',
        'subtitle': null,
        'category': 'Grocery',
        'price': 250,
        'mrp': 300,
        'distanceMeters': null,
        'distanceText': null,
        'address': null,
        'productCount': null,
      }),
    );

    expect(find.text('₹250'), findsOneWidget);
    expect(find.text('Grocery'), findsOneWidget);
    // A product legitimately has no address, so the line is dropped entirely
    // instead of claiming the location is unavailable.
    expect(find.text(AppStrings.globalSearchLocationUnavailable.tr),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('half-populated rows collapse only the missing half',
      (tester) async {
    // Distance without an address.
    await _pump(tester, _item({'address': null}));
    expect(find.text('4.5 Km'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Address without a distance.
    await _pump(tester, _item({'distanceMeters': null, 'distanceText': null}));
    expect(find.text('4.5 Km'), findsNothing);
    expect(find.text('Sastri Nagar, Lucknow, Uttar Pradesh, 226001'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long values do not overflow, from small phone to tablet',
      (tester) async {
    final long = _item({
      'title':
          'Gupta General Store & Wholesale Kirana Suppliers Since 1974 Pvt Ltd',
      'subtitle': 'General Store, Wholesale Kirana, Household Essentials',
      'distanceText': '1,234.5 Km',
      'address':
          'Shop 14, Sastri Nagar Main Road, Near Bus Depot, Lucknow, Uttar Pradesh, 226001, India',
      'productCount': 12500000,
      'sponsored': true,
      'assured': true,
    });

    for (final width in [320.0, 360.0, 411.0, 768.0]) {
      await _pump(tester, long, width: width);
      expect(tester.takeException(), isNull,
          reason: 'card overflowed at ${width}px wide');
    }
  });
}
