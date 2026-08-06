import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Renders at a narrow phone width — the landing grid puts two folders per row,
/// so the 800x600 test default would hide overflows a real device shows.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(body: SingleChildScrollView(child: child));
      }),
    ),
  );
  await tester.pump();
}

/// A section as the landing grid mounts it: inside a host (so the sheet can
/// mount it live) and inside an enabled folder scope.
Widget _asFolder(Widget section) {
  return DiscoverFolderScope(
    enabled: true,
    child: SizedBox(width: 170, child: DiscoverFolderHost(section: section)),
  );
}

DiscoverCategorySection _grocerySection() => DiscoverCategorySection(
      title: 'Grocery',
      items: [],
      onItemTap: (_) {},
    );

void main() {
  testWidgets('section collapses to a folder tile inside the scope',
      (tester) async {
    await _pump(tester, _asFolder(_grocerySection()));

    expect(find.byType(DiscoverFolderTile), findsOneWidget);
    expect(find.text('Grocery'), findsOneWidget);
    // The full card's tiles are NOT rendered in folder mode.
    expect(find.text('Kirana Store'), findsNothing);
  });

  testWidgets('section renders its full card when the scope is off',
      (tester) async {
    await _pump(
      tester,
      DiscoverFolderScope(enabled: false, child: _grocerySection()),
    );

    expect(find.byType(DiscoverFolderTile), findsNothing);
    expect(find.text('Kirana Store'), findsOneWidget);
  });

  testWidgets('more than four categories pack the last slot as a mini grid',
      (tester) async {
    // discoverFoodCategories has 10 entries: 3 full plates + 4 mini plates.
    await _pump(
      tester,
      _asFolder(DiscoverCategorySection(
        title: 'Restaurant & Food',
        items: [],
        onItemTap: (_) {},
      )),
    );

    expect(find.byType(DiscoverFolderIcon), findsNWidgets(7));
  });

  testWidgets('four or fewer categories fill the four slots', (tester) async {
    await _pump(
      tester,
      _asFolder(DiscoverCategorySection(
        title: 'Home Services',
        items: discoverHomeServicesCategories, // 4 entries
        onItemTap: (_) {},
      )),
    );

    expect(find.byType(DiscoverFolderIcon), findsNWidgets(4));
  });

  testWidgets('tapping a folder opens the section\'s full card in a sheet',
      (tester) async {
    await _pump(tester, _asFolder(_grocerySection()));

    await tester.tap(find.byType(DiscoverFolderTile));
    await tester.pumpAndSettle();

    // The sheet mounts the section again with the scope off, so every original
    // tile — and therefore its original routing — is present.
    expect(find.text('Kirana Store'), findsOneWidget);
    expect(find.text('Home Essentials'), findsOneWidget);
  });
}
