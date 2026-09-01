import 'dart:io';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// What is under test here is the FOLDER MECHANIC — a section collapsing to a
/// tile in the landing grid, and expanding back into its full card inside the
/// sheet. It is not the app's category catalogue.
///
/// These tests used to assert against `discoverGroceryCategories` ("Kirana
/// Store", "Home Essentials"). Grocery moved to the onboarding API, that list
/// was deleted, and the tests were patched to compile by passing `items: []` —
/// which left them asserting that empty lists render tiles. They could not pass.
///
/// So the fixtures below belong to the test. The names are the test's own, so a
/// rename in the shipped catalogue can never break it again; the ICONS are
/// borrowed from a real category because [DiscoverFolderIcon] resolves them
/// through `Image.asset`, and a made-up path would fail to load.
final List<String> _realIcons = discoverHomeServicesCategories
    .map((e) => e.icon)
    .whereType<String>()
    .where((e) => e.isNotEmpty)
    .toList();

const String _firstTile = 'Kirana Store';
const String _secondTile = 'Home Essentials';

/// [count] categories, the first two named so the tests can assert on them.
List<CollapsibleGridModel> _categories(int count) {
  final names = [_firstTile, _secondTile];
  return [
    for (var i = 0; i < count; i++)
      CollapsibleGridModel(
        name: i < names.length ? names[i] : 'Category ${i + 1}',
        slugId: 'TEST',
        icon: _realIcons[i % _realIcons.length],
      ),
  ];
}

/// Renders at a narrow phone width — the landing grid puts two folders per row,
/// so the 800x600 test default would hide overflows a real device shows.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
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
      items: _categories(2),
      onItemTap: (_) {},
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    // The folder caption picks its contrast from the user's chosen app
    // background, which means it resolves AppBackgroundController — and that
    // controller opens a Hive box in onInit. Without a storage path every test
    // that renders a caption threw "You need to initialize Hive".
    tempDir = await Directory.systemTemp.createTemp('discover_folder_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('section collapses to a folder tile inside the scope',
      (tester) async {
    await _pump(tester, _asFolder(_grocerySection()));

    expect(find.byType(DiscoverFolderTile), findsOneWidget);
    // findsWidgets, not findsOneWidget: the caption is OUTLINED, and Flutter's
    // TextStyle takes `color` OR a stroke `foreground` Paint but never both —
    // so the title is drawn as two stacked Texts (stroke layer, then fill).
    // Asserting on the count here would pin the outline technique rather than
    // the behaviour, which is simply "the tile is captioned with the section".
    expect(find.text('Grocery'), findsWidgets);
    // The full card's tiles are NOT rendered in folder mode.
    expect(find.text(_firstTile), findsNothing);
  });

  testWidgets('section renders its full card when the scope is off',
      (tester) async {
    await _pump(
      tester,
      DiscoverFolderScope(enabled: false, child: _grocerySection()),
    );

    expect(find.byType(DiscoverFolderTile), findsNothing);
    expect(find.text(_firstTile), findsOneWidget);
  });

  testWidgets('more than four categories pack the last slot as a mini grid',
      (tester) async {
    // Ten categories: three full-size slots, then the next four packed into a
    // mini 2x2 in the fourth slot = seven icons in total.
    await _pump(
      tester,
      _asFolder(DiscoverCategorySection(
        title: 'Restaurant & Food',
        items: _categories(10),
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
        items: _categories(4),
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
    expect(find.text(_firstTile), findsOneWidget);
    expect(find.text(_secondTile), findsOneWidget);
  });
}
