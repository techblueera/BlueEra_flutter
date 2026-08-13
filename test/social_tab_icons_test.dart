import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Social tab strip picks its glyph by selection state, so a typo in a path
/// or a malformed file shows up as a silently blank tab rather than as a build
/// error. These load each of the six assets for real and fail if any is missing
/// or unparseable.
void main() {
  const pairs = <String, List<String>>{
    'Feed': [AppIconAssets.tabFeed, AppIconAssets.tabFeedActive],
    'Bites': [AppIconAssets.tabBites, AppIconAssets.tabBitesActive],
    'My Post': [AppIconAssets.tabMyPost, AppIconAssets.tabMyPostActive],
  };

  for (final entry in pairs.entries) {
    final tab = entry.key;
    final resting = entry.value[0];
    final active = entry.value[1];

    testWidgets('$tab tab ships a resting and an active glyph that both parse',
        (tester) async {
      expect(resting, isNot(active),
          reason: '$tab would show the same glyph in both states');

      for (final path in entry.value) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SvgPicture.asset(path, height: 20, width: 20),
            ),
          ),
        );
        // The asset is decoded off the bundle asynchronously.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: '$path failed to load or parse');
        expect(find.byType(SvgPicture), findsOneWidget);
      }
    });
  }
}
