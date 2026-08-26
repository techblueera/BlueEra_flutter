import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_broadcast_search_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The live search block (guide §7.3), checked against the two honesty rules
/// that make it trustworthy rather than decorative.
Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(
          body: SingleChildScrollView(
            child: OrderBroadcastSearchSection(
              orderId: 'o1',
              onTryAgain: () {},
              onCollectMyself: () {},
            ),
          ),
        );
      }),
    ),
  );
  await tester.pump();
}

BroadcastSearch _search({DateTime? startedAt}) => BroadcastSearch(
      productOrderId: 'o1',
      rideOrderId: 'ride1',
      startedAt: startedAt ?? DateTime.now(),
      fare: 84,
      etaLabel: '17–32 min',
    );

void main() {
  late OrderBroadcastController c;

  setUp(() {
    Get.testMode = true;
    c = Get.put(OrderBroadcastController(), permanent: true);
  });

  tearDown(Get.reset);

  testWidgets('no search, nothing rendered — the zone only exists while '
      'something is happening', (tester) async {
    await _pump(tester);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('partner'), findsNothing);
  });

  testWidgets('a running search shows round, radius and a cumulative count',
      (tester) async {
    final s = _search()
      ..applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 9))
      ..applyRound(const BroadcastRound(index: 2, radiusKm: 6, notified: 8));
    c.searches['o1'] = s;

    await _pump(tester);

    expect(find.text('Finding a delivery partner'), findsOneWidget);
    expect(find.text('within 6 km'), findsOneWidget);
    expect(find.text('round 2 of 3'), findsOneWidget);
    // Cumulative, and stated as a complete sentence.
    expect(find.text('17 partners called'), findsOneWidget);
    // Determinate: we know exactly how long this takes.
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, isNotNull);
  });

  testWidgets('NO invented denominator — never "17 of N"', (tester) async {
    c.searches['o1'] = _search()
      ..applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 9));
    await _pump(tester);

    expect(find.textContaining('9 of'), findsNothing);
    expect(find.text('9 partners called'), findsOneWidget);
  });

  testWidgets('ridersNotified:0 reads "widening the search", never '
      '"0 partners called"', (tester) async {
    c.searches['o1'] = _search()
      ..applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 0));
    await _pump(tester);

    expect(find.text('Widening the search…'), findsOneWidget);
    expect(find.text('0 partners called'), findsNothing);
    // The round row says what happened rather than going silent.
    expect(find.text('round 1 · 3 km — none nearby'), findsOneWidget);
  });

  testWidgets('the round timeline appends: done, current, up next',
      (tester) async {
    c.searches['o1'] = _search()
      ..applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 9))
      ..applyRound(const BroadcastRound(index: 2, radiusKm: 6, notified: 8));
    await _pump(tester);

    expect(find.text('round 1 · 3 km — 9 called'), findsOneWidget);
    expect(find.text('round 2 · 6 km — 8 more called'), findsOneWidget);
    expect(find.text('round 3 — up next'), findsOneWidget);
  });

  testWidgets('the fee and ETA stay pinned to what the customer agreed to',
      (tester) async {
    c.searches['o1'] = _search()
      ..applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 2));
    await _pump(tester);
    expect(find.text('₹84 · 17–32 min'), findsOneWidget);
    expect(find.text('Cancel search'), findsOneWidget);
  });

  testWidgets('exhausted is NOT a cancellation — the goods are packed',
      (tester) async {
    c.searches['o1'] = _search()..exhausted = true;
    await _pump(tester);

    expect(find.text('No delivery partner found'), findsOneWidget);
    expect(
      find.textContaining('packed and waiting at the shop'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Collect it myself'), findsOneWidget);
    // The words a failure card would use are absent.
    expect(find.textContaining('cancelled'), findsNothing);
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('an assigned partner collapses the zone — the rider cards take '
      'over', (tester) async {
    c.searches['o1'] = _search()..assigned = true;
    await _pump(tester);
    expect(find.text('Finding a delivery partner'), findsNothing);
    expect(find.text('No delivery partner found'), findsNothing);
  });

  testWidgets('a dispatch in flight says so instead of showing an empty card',
      (tester) async {
    c.dispatching.add('o1');
    await _pump(tester);
    expect(find.textContaining('Sending this to nearby'), findsOneWidget);
  });

  testWidgets('a dispatch that could not start is honest about it',
      (tester) async {
    c.undispatchable.add('o1');
    await _pump(tester);
    expect(find.textContaining("couldn't start the delivery search"),
        findsOneWidget);
    expect(find.text('Collect it myself'), findsOneWidget);
  });
}
