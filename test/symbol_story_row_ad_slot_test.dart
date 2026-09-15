import 'package:BlueEra/features/common/home/view/widget/symbol_story_row.dart';
import 'package:flutter_test/flutter_test.dart';

/// The index remap that lets an ad card take a row in the symbol/story rail.
///
/// The rail's own comments record it getting this wrong once already — with a
/// placeholder occupying row 0, "tapping otherN opens otherN+1". That failure
/// is invisible until a user taps a face and someone else's symbols open, so
/// the arithmetic is pinned here rather than trusted.
void main() {
  group('symbolRowToStoryIndex', () {
    const adIndex = 3;

    test('rows before the ad are unchanged', () {
      for (var row = 0; row < adIndex; row++) {
        expect(symbolRowToStoryIndex(row, adIndex: adIndex), row);
      }
    });

    test('rows after the ad shift back by one', () {
      expect(symbolRowToStoryIndex(4, adIndex: adIndex), 3);
      expect(symbolRowToStoryIndex(5, adIndex: adIndex), 4);
      expect(symbolRowToStoryIndex(12, adIndex: adIndex), 11);
    });

    test('a negative adIndex leaves every row alone', () {
      for (var row = 0; row < 10; row++) {
        expect(symbolRowToStoryIndex(row, adIndex: -1), row);
      }
    });

    /// The property that actually matters: walking the whole rail must visit
    /// every story exactly once. An off-by-one here shows up as a duplicated
    /// or skipped card, which is the "opens the wrong person" bug.
    test('every story is reachable exactly once, and none is skipped', () {
      const storyCount = 9;
      const rowCount = storyCount + 1; // + the ad row

      final visited = <int>[];
      for (var row = 0; row < rowCount; row++) {
        if (row == adIndex) continue; // the ad row renders no story
        visited.add(symbolRowToStoryIndex(row, adIndex: adIndex));
      }

      expect(visited, List<int>.generate(storyCount, (i) => i));
      expect(visited.toSet().length, storyCount, reason: 'no duplicates');
    });

    test('with no ad the rail is a straight pass-through', () {
      const storyCount = 6;

      final visited = <int>[
        for (var row = 0; row < storyCount; row++)
          symbolRowToStoryIndex(row, adIndex: -1),
      ];

      expect(visited, List<int>.generate(storyCount, (i) => i));
    });

    /// The ad never displaces the viewer's own card, which is row 0 and is the
    /// way in to posting a symbol.
    test('row 0 is never the ad row in practice', () {
      expect(symbolRowToStoryIndex(0, adIndex: adIndex), 0);
      expect(adIndex, greaterThan(0));
    });
  });

  group('symbolRailAdIndex', () {
    int index({
      bool adsEnabled = true,
      bool sessionSpent = false,
      int storyCount = 10,
    }) =>
        symbolRailAdIndex(
          adsEnabled: adsEnabled,
          sessionSpent: sessionSpent,
          storyCount: storyCount,
        );

    test('takes the third slot when everything allows it', () {
      expect(index(), kSymbolRailAdSlot);
      expect(kSymbolRailAdSlot, greaterThan(0),
          reason: "the viewer's own card owns row 0");
    });

    test('no tile when ads are switched off for the build', () {
      expect(index(adsEnabled: false), -1);
    });

    /// The session cap. Once the one interstitial has been shown the tile is a
    /// control that would silently do nothing, so the row goes back to a story.
    test('no tile once the session cap is spent', () {
      expect(index(sessionSpent: true), -1);
    });

    test('the cap wins even on a long rail', () {
      expect(index(sessionSpent: true, storyCount: 500), -1);
    });

    test('no tile until the rail has more stories than the slot', () {
      for (var count = 0; count <= kSymbolRailAdSlot; count++) {
        expect(index(storyCount: count), -1,
            reason: 'a $count-card rail must not be mostly advertising');
      }
      expect(index(storyCount: kSymbolRailAdSlot + 1), kSymbolRailAdSlot);
    });

    test('a disabled build and a spent cap agree with each other', () {
      expect(index(adsEnabled: false, sessionSpent: true), -1);
    });
  });
}
