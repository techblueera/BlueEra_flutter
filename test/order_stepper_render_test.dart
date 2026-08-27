import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/order_track_model.dart';
import 'package:BlueEra/features/chat/view/order_track/widgets/order_status_chip.dart';
import 'package:BlueEra/features/chat/view/order_track/widgets/order_stepper.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The stepper and the status chip, rendered — `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md`
/// §6.1 to §6.3.
///
/// The parsing rules live in `order_chat_and_steps_edge_cases_test.dart`; this
/// file is about what actually reaches the screen: which labels, which
/// timestamps, how many ticks, and what a cancelled order looks like.
void main() {
  // The real `assets/translations/en.json`, registered the way the app
  // registers it. Two things at once: the widgets render the sentences a user
  // would actually see rather than raw keys, and a copy key that never made it
  // into the bundle fails here instead of shipping.
  setUpAll(() {
    final raw = File('assets/translations/en.json').readAsStringSync();
    final map = Map<String, String>.from(
        (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', '$v')));
    Get.addTranslations({'en': map});
    Get.locale = const Locale('en');
    Get.fallbackLocale = const Locale('en');
  });

  OrderTrackModel model(Map<String, dynamic> data) =>
      OrderTrackModel.fromJson({'data': data}, fallbackOrderId: 'o1');

  Future<void> pumpStepper(WidgetTester tester, OrderTrackModel order) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(
          body: SingleChildScrollView(child: OrderStepper(order: order)),
        );
      }),
    ));
    await tester.pump();
  }

  final groceryStages = [
    {
      'key': 'placed',
      'label': 'Order placed',
      'done': true,
      'at': '2026-08-27T12:00:00.000Z',
    },
    {
      'key': 'ready_for_pickup',
      'label': 'Ready for pickup',
      'done': true,
      'at': '2026-08-27T12:01:00.000Z',
    },
    {'key': 'completed', 'label': 'Completed', 'done': false, 'at': null},
  ];

  group('§6.2 · the three grocery steps', () {
    testWidgets('every server label renders, verbatim', (tester) async {
      await pumpStepper(
          tester,
          model({
            'orderStatus': 'in-progress',
            'currentStage': 'completed',
            'stages': groceryStages,
          }));

      expect(find.text('Order placed'), findsOneWidget);
      expect(find.text('Ready for pickup'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('done steps get a tick, the future step does not',
        (tester) async {
      await pumpStepper(tester, model({'stages': groceryStages}));
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('a future step shows an em dash instead of a time',
        (tester) async {
      await pumpStepper(tester, model({'stages': groceryStages}));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('S3 · done with at: null shows the tick and no time row',
        (tester) async {
      await pumpStepper(
          tester,
          model({
            'stages': [
              {
                'key': 'placed',
                'label': 'Order placed',
                'done': true,
                'at': null
              },
            ]
          }));
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });
  });

  group('§6.3 · the edge cases, on screen', () {
    testWidgets('S1 · no stages renders a sentence, not an empty frame',
        (tester) async {
      await pumpStepper(
          tester, model({'stages': <dynamic>[], 'orderStatus': 'placed'}));
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('S2 · an unknown stage key renders via its label',
        (tester) async {
      await pumpStepper(
          tester,
          model({
            'stages': [
              ...groceryStages,
              {
                'key': 'quality_checked',
                'label': 'Quality checked',
                'done': false,
              },
            ]
          }));
      expect(find.text('Quality checked'), findsOneWidget);
    });

    testWidgets(
        'S4 · array order is layout order, even when done is out of order',
        (tester) async {
      await pumpStepper(
          tester,
          model({
            'stages': [
              {'key': 'placed', 'label': 'First', 'done': false},
              {'key': 'ready_for_pickup', 'label': 'Second', 'done': true},
            ]
          }));

      final first = tester.getTopLeft(find.text('First'));
      final second = tester.getTopLeft(find.text('Second'));
      expect(first.dy, lessThan(second.dy),
          reason: 'the array decided the order, not `done`');
    });

    testWidgets('S7 · a multi-shop stage renders one sub-row per shop',
        (tester) async {
      await pumpStepper(
          tester,
          model({
            'stages': [
              {
                'key': 'ready_for_pickup',
                'label': 'Ready for pickup',
                'done': false,
                'businesses': [
                  {
                    'businessId': 'b1',
                    'name': 'Singh Store',
                    'status': 'ready'
                  },
                  {
                    'businessId': 'b2',
                    'name': 'Verma Store',
                    'status': 'pending'
                  },
                ],
              },
            ]
          }));

      expect(find.text('Singh Store'), findsOneWidget);
      expect(find.text('Verma Store'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('S9 · cancelled keeps the history and appends a grey node',
        (tester) async {
      await pumpStepper(
          tester,
          model({
            'orderStatus': 'cancelled',
            'stages': [
              {
                'key': 'placed',
                'label': 'Order placed',
                'done': true,
                'at': '2026-08-27T12:00:00.000Z',
              },
              {
                'key': 'ready_for_pickup',
                'label': 'Ready for pickup',
                'done': false
              },
              {'key': 'completed', 'label': 'Completed', 'done': false},
            ],
          }));

      // History survives, in full.
      expect(find.text('Order placed'), findsOneWidget);
      expect(find.text('Ready for pickup'), findsOneWidget);
      // And the terminal node is appended, not substituted.
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('S12 · a timestamp in the future clamps to "Just now"',
        (tester) async {
      final future = DateTime.now().add(const Duration(days: 2));
      await pumpStepper(
          tester,
          model({
            'stages': [
              {
                'key': 'placed',
                'label': 'Order placed',
                'done': true,
                'at': future.toUtc().toIso8601String(),
              },
            ]
          }));
      expect(find.text('Just now'), findsOneWidget);
    });
  });

  // ── §6.1 · the status chip ────────────────────────────────────────────

  group('§6.1 · the status chip', () {
    testWidgets('every documented status has a label', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      const expected = {
        'placed': 'Placed',
        'accepted': 'Accepted',
        'in-progress': 'In progress',
        'ready': 'Ready for pickup',
        'dispatched': 'On the way',
        'completed': 'Completed',
        'cancelled': 'Cancelled',
        'expired': 'Expired',
      };
      expected.forEach((status, label) {
        expect(OrderStatusChip.labelFor(status), label, reason: status);
      });
    });

    testWidgets('a status this build does not know renders NO chip',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(OrderStatusChip.labelFor('teleporting'), isNull);
      expect(OrderStatusChip.labelFor(null), isNull);
    });

    testWidgets('C10 · is_cancelled beats a null order_status', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(OrderStatusChip.labelFor(null, isCancelled: true), 'Cancelled');
      expect(OrderStatusChip.labelFor('ready', isCancelled: true), 'Cancelled');
    });

    testWidgets(
        'in-progress reads as "Ready for pickup" once the stage says so',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(
          OrderStatusChip.labelFor('in-progress', stageKey: 'ready_for_pickup'),
          'Ready for pickup');
      expect(OrderStatusChip.labelFor('in-progress', stageKey: 'packing'),
          'In progress');
    });

    testWidgets('the chip pairs its colour with a word, always',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          SizeConfig.init(context);
          return const Scaffold(body: OrderStatusChip(orderStatus: 'placed'));
        }),
      ));
      await tester.pump();
      expect(find.text('Placed'), findsOneWidget);
    });

    testWidgets('an unknown status renders an empty box, never a raw enum',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          SizeConfig.init(context);
          return const Scaffold(body: OrderStatusChip(orderStatus: 'quantum'));
        }),
      ));
      await tester.pump();
      expect(find.text('quantum'), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  });
}
