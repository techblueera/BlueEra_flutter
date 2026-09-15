import 'dart:math';

import 'package:BlueEra/features/common/reel/view/shorts/shorts_player_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The spacing between interstitial breaks in the shorts feed.
///
/// The interval is rolled rather than fixed so the break is felt rather than
/// counted — one that lands on exactly the 10th, 20th and 30th short reads as
/// a meter running. What must never happen is a short interval: at 0 or below,
/// every swipe would request an interstitial, which is the pattern AdMob
/// suspends a unit for.
void main() {
  group('rollShortsAdInterval', () {
    test('stays within the requested band across many rolls', () {
      final random = Random(1234);

      for (var i = 0; i < 1000; i++) {
        final interval = rollShortsAdInterval(random);
        expect(interval, inInclusiveRange(8, 12));
      }
    });

    test('actually varies — a fixed cadence defeats the point', () {
      final random = Random(7);
      final seen = <int>{
        for (var i = 0; i < 200; i++) rollShortsAdInterval(random),
      };

      expect(seen.length, greaterThan(1));
    });

    test('covers the whole band, so 10 is the centre and not the floor', () {
      final random = Random(99);
      final seen = <int>{
        for (var i = 0; i < 2000; i++) rollShortsAdInterval(random),
      };

      expect(seen, containsAll(<int>[8, 9, 10, 11, 12]));
    });

    test('no jitter gives exactly the base', () {
      final random = Random(3);

      for (var i = 0; i < 50; i++) {
        expect(rollShortsAdInterval(random, base: 10, jitter: 0), 10);
      }
    });

    test('honours a custom band', () {
      final random = Random(42);

      for (var i = 0; i < 500; i++) {
        expect(
          rollShortsAdInterval(random, base: 20, jitter: 5),
          inInclusiveRange(15, 25),
        );
      }
    });

    /// The guard that matters. An interval of 0 fires an ad on every swipe.
    test('never returns an interval that would ad-bomb every swipe', () {
      final random = Random(11);

      for (var i = 0; i < 500; i++) {
        expect(rollShortsAdInterval(random, base: 1, jitter: 5),
            greaterThanOrEqualTo(1));
        expect(rollShortsAdInterval(random, base: 0, jitter: 0),
            greaterThanOrEqualTo(1));
        expect(rollShortsAdInterval(random, base: -5, jitter: 2),
            greaterThanOrEqualTo(1));
      }
    });

    test('a negative jitter is read as its magnitude, not as a bug', () {
      final random = Random(5);

      for (var i = 0; i < 200; i++) {
        expect(
          rollShortsAdInterval(random, base: 10, jitter: -2),
          inInclusiveRange(8, 12),
        );
      }
    });
  });
}
