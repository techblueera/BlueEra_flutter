import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Renders the bar for [actions] and returns the tester.
Future<void> _pump(WidgetTester tester, List<String> actions,
    {bool isOwner = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(
          body: OrderActionBar(
            actions: actions,
            ctx: OrderCardContext(
              orderId: 'o1',
              isOwner: isOwner,
              otherUserId: 'u2',
              otherUserName: 'Sharma Kirana',
            ),
          ),
        );
      }),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(OrderLifecycleController(), permanent: true);
  });

  tearDown(Get.reset);

  group('OrderActionBar renders exactly what the server offered', () {
    testWidgets('owner actions map to their documented labels',
        (tester) async {
      await _pump(tester, [
        'ACCEPT_ORDER',
        'REJECT_ORDER',
        'SET_PREP_ETA',
        'CONTACT_CUSTOMER',
      ]);

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text("Can't take it"), findsOneWidget);
      expect(find.text('Update time'), findsOneWidget);
      expect(find.byIcon(Icons.call), findsOneWidget);
    });

    testWidgets('customer actions map to their documented labels',
        (tester) async {
      await _pump(
        tester,
        [
          'SUBMIT_PAYMENT',
          'VIEW_PICKUP_CODE',
          'FIND_RIDER',
          'CANCEL_ORDER',
          'RAISE_ISSUE',
        ],
        isOwner: false,
      );

      // Primaries first, then the low-emphasis ways out. Only three buttons
      // stay on the card; the rest fold into the ⋯ menu (guide §3.3).
      expect(find.text('Pay now'), findsOneWidget);
      expect(find.text('Show pickup code'), findsOneWidget);
      // FIND_RIDER is a text link now, never a button that leaves the chat
      // (guide §5.5).
      expect(find.text("Can't come? Get it delivered"), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      // Cancel and Report are in the overflow, not gone.
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('the overflow menu carries what the cap pushed off',
        (tester) async {
      await _pump(
        tester,
        [
          'SUBMIT_PAYMENT',
          'VIEW_PICKUP_CODE',
          'FIND_RIDER',
          'CANCEL_ORDER',
          'RAISE_ISSUE',
        ],
        isOwner: false,
      );

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.text('Cancel order'), findsOneWidget);
      expect(find.text('Report a problem'), findsOneWidget);
    });

    testWidgets('every remaining owner action in the contract renders',
        (tester) async {
      await _pump(tester, [
        'MARK_READY',
        'VERIFY_PAYMENT',
        'REJECT_PAYMENT',
        'CONFIRM_HANDOVER',
        'REPORT_NO_SHOW',
        'MARK_REFUND_SENT',
      ]);

      // Three primaries are visible; the destructive and low-priority ones
      // are one tap away rather than crowding the card.
      expect(find.text('Order packed'), findsOneWidget);
      expect(find.text('Payment received'), findsOneWidget);
      expect(find.text('Handed over'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.text('Not received'), findsOneWidget);
      expect(find.text("Customer didn't come"), findsOneWidget);
      expect(find.text('I sent the refund'), findsOneWidget);
    });

    testWidgets('CONFIRM_REFUND_RECEIVED renders for the customer',
        (tester) async {
      await _pump(tester, ['CONFIRM_REFUND_RECEIVED'], isOwner: false);
      expect(find.text('I received the refund'), findsOneWidget);
    });

    testWidgets(
        'an action this build does not know renders NOTHING — never a guess',
        (tester) async {
      await _pump(tester, ['ESCALATE_TO_REGIONAL_MANAGER_V3']);

      // No button, no placeholder, no crash.
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('a mix of known and unknown renders only the known ones',
        (tester) async {
      await _pump(tester, ['ACCEPT_ORDER', 'TELEPORT_ORDER', 'REJECT_ORDER']);

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text("Can't take it"), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Accept only
    });

    testWidgets('an empty action list renders no bar at all', (tester) async {
      await _pump(tester, const []);
      expect(find.byType(Wrap), findsNothing);
    });
  });

  group('per-action busy state', () {
    testWidgets('only the tapped action disables; the others stay live',
        (tester) async {
      final controller = OrderLifecycleController.instance;
      await _pump(tester, ['ACCEPT_ORDER', 'REJECT_ORDER']);

      // Simulate Accept being in flight.
      controller.busyKeys.add('o1:ACCEPT_ORDER');
      controller.busyKeys.refresh();
      await tester.pump();

      final accept = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(accept.onPressed, isNull, reason: 'tapped button must disable');

      final reject = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(reject.onPressed, isNotNull,
          reason: 'the other party\'s updates must keep landing');
    });

    testWidgets('a busy action shows a spinner in place of its label',
        (tester) async {
      final controller = OrderLifecycleController.instance;
      await _pump(tester, ['MARK_READY']);
      expect(find.text('Order packed'), findsOneWidget);

      controller.busyKeys.add('o1:MARK_READY');
      controller.busyKeys.refresh();
      await tester.pump();

      expect(find.text('Order packed'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('terminal orders still render their action bar', () {
    testWidgets('a cancelled order that owes money keeps its refund buttons',
        (tester) async {
      // A cancelled order that owes money is not finished business.
      await _pump(tester, ['MARK_REFUND_SENT', 'CONTACT_CUSTOMER']);

      expect(find.text('I sent the refund'), findsOneWidget);
      expect(find.byIcon(Icons.call), findsOneWidget);
    });
  });
}
