import 'package:BlueEra/features/common/Discover/widget/discover_video_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

/// [DiscoverVideoSlide]'s contract with the banner around it.
///
/// There is no video platform in a unit test, so every `initialize()` here
/// fails — which is exactly the path worth pinning: a clip that cannot load
/// must degrade to the artwork it replaced and must still release the
/// carousel, or a guest is left staring at a black box on a card that has
/// stopped rotating.
void main() {
  const fallbackKey = Key('fallback-artwork');

  Widget host({
    required bool alive,
    bool hasFocus = true,
    VoidCallback? onFinished,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 160,
          child: DiscoverVideoSlide(
            url: 'https://example.test/intro.mp4',
            alive: alive,
            hasFocus: hasFocus,
            onFinished: onFinished,
            fallback: const ColoredBox(
              key: fallbackKey,
              color: Color(0xFF123456),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the fallback and builds no player while not alive',
      (tester) async {
    await tester.pumpWidget(host(alive: false));
    await tester.pump();

    expect(find.byKey(fallbackKey), findsOneWidget);
    expect(
      find.byType(VideoPlayer),
      findsNothing,
      reason: 'a slide that is not alive must not hold a decoder',
    );
  });

  testWidgets('a clip that cannot load falls back to the artwork',
      (tester) async {
    await tester.pumpWidget(host(alive: true));
    await tester.pumpAndSettle();

    expect(find.byKey(fallbackKey), findsOneWidget);
    expect(find.byType(VideoPlayer), findsNothing);
  });

  testWidgets('a failed clip releases the carousel exactly once',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(host(alive: true, onFinished: () => finished++));
    await tester.pumpAndSettle();

    expect(
      finished,
      1,
      reason: 'the banner must be told to resume auto-advance, and only once',
    );
  });

  testWidgets('going from alive to not alive tears down without throwing',
      (tester) async {
    await tester.pumpWidget(host(alive: true));
    await tester.pumpAndSettle();

    await tester.pumpWidget(host(alive: false));
    await tester.pumpAndSettle();

    expect(find.byKey(fallbackKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('losing focus does not tear the slide down', (tester) async {
    await tester.pumpWidget(host(alive: true, hasFocus: true));
    await tester.pumpAndSettle();

    // Scrolling the carousel to another slide. This must change sound only —
    // the slide staying mounted is what stops the clip vanishing and
    // re-downloading on every swipe.
    await tester.pumpWidget(host(alive: true, hasFocus: false));
    await tester.pumpAndSettle();

    expect(find.byType(DiscoverVideoSlide), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unmounting disposes cleanly', (tester) async {
    await tester.pumpWidget(host(alive: true));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(find.byType(DiscoverVideoSlide), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
