import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_card_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Renders the bar for [actions] and returns the tester.
Future<void> _pump(
  WidgetTester tester,
  List<String> actions, {
  bool isOwner = true,
  Set<String> hidden = const {},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(
          body: OrderActionBar(
            actions: actions,
            hiddenActions: hidden,
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

/// The board's button for [label], or null when it is not on the card.
OrderButton? _button(WidgetTester tester, String label) {
  final found = find.widgetWithText(OrderButton, label);
  if (found.evaluate().isEmpty) return null;
  return tester.widget<OrderButton>(found);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(OrderLifecycleController(), permanent: true);
  });

  tearDown(Get.reset);

  group('OrderActionBar renders exactly what the server offered', () {
    testWidgets('owner actions map to the board\'s labels', (tester) async {
      await _pump(tester, [
        'ACCEPT_ORDER',
        'REJECT_ORDER',
      ]);

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('the primary sits on the RIGHT, as the board draws it',
        (tester) async {
      await _pump(tester, ['ACCEPT_ORDER', 'REJECT_ORDER']);

      final reject = tester.getCenter(find.text('Reject'));
      final accept = tester.getCenter(find.text('Accept'));
      expect(accept.dx, greaterThan(reject.dx),
          reason: 'every board pair reads "way out · do the thing"');
    });

    testWidgets('customer actions map to the board\'s labels', (tester) async {
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

      // The board never draws more than two buttons on a card; the rest fold
      // into the ⋯ menu.
      expect(find.text('Upload Screenshot'), findsOneWidget);
      expect(find.text('Show Code'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      expect(find.text('Cancel Order'), findsNothing);
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

      expect(find.text('Cancel Order'), findsOneWidget);
      expect(find.text('Need Help'), findsOneWidget);
      expect(find.text('Get it delivered'), findsOneWidget);
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

      // Two primaries are visible; everything else is one tap away rather
      // than crowding the card.
      expect(find.text('Mark as Ready'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text("Customer didn't come"), findsOneWidget);
      expect(find.text('I sent the refund'), findsOneWidget);
    });

    testWidgets('CONFIRM_REFUND_RECEIVED renders for the customer',
        (tester) async {
      await _pump(tester, ['CONFIRM_REFUND_RECEIVED'], isOwner: false);
      expect(find.text('I received the refund'), findsOneWidget);
    });

    testWidgets('contact is a labelled button, not a bare handset',
        (tester) async {
      // On the board's ready and payment screens "Contact Shop" is half of
      // the button pair, so it carries its name.
      await _pump(tester, ['CONTACT_SHOP'], isOwner: false);
      expect(find.text('Contact Shop'), findsOneWidget);

      await _pump(tester, ['CONTACT_CUSTOMER']);
      expect(find.text('Contact Customer'), findsOneWidget);
    });

    testWidgets(
        'an action this build does not know renders NOTHING — never a guess',
        (tester) async {
      await _pump(tester, ['ESCALATE_TO_REGIONAL_MANAGER_V3']);

      // No button, no placeholder, no crash.
      expect(find.byType(OrderButton), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('a mix of known and unknown renders only the known ones',
        (tester) async {
      await _pump(tester, ['ACCEPT_ORDER', 'TELEPORT_ORDER', 'REJECT_ORDER']);

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.byType(OrderButton), findsNWidgets(2));
    });

    testWidgets('an empty action list renders no bar at all', (tester) async {
      await _pump(tester, const []);
      expect(find.byType(OrderButtonRow), findsNothing);
    });
  });

  group('a panel that owns an action takes it off the bar', () {
    testWidgets('a hidden action is not drawn twice', (tester) async {
      // The board puts `Upload Screenshot` inside the payment panel and
      // `Show Code` inside the pickup panel. The server contract is
      // untouched — the action is still only offered when it is allowed —
      // but one control means one tap target.
      await _pump(
        tester,
        ['SUBMIT_PAYMENT', 'CANCEL_ORDER'],
        isOwner: false,
        hidden: {'SUBMIT_PAYMENT'},
      );

      expect(find.text('Upload Screenshot'), findsNothing);
      expect(find.text('Cancel Order'), findsOneWidget);
    });

    testWidgets('hiding every action leaves no bar', (tester) async {
      await _pump(
        tester,
        ['VIEW_PICKUP_CODE'],
        isOwner: false,
        hidden: {'VIEW_PICKUP_CODE'},
      );
      expect(find.byType(OrderButton), findsNothing);
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

      expect(_button(tester, 'Accept')?.onTap, isNull,
          reason: 'tapped button must disable');
      expect(_button(tester, 'Reject')?.onTap, isNotNull,
          reason: "the other party's updates must keep landing");
    });

    testWidgets('a busy action shows a spinner in place of its label',
        (tester) async {
      final controller = OrderLifecycleController.instance;
      await _pump(tester, ['MARK_READY']);
      expect(find.text('Mark as Ready'), findsOneWidget);

      controller.busyKeys.add('o1:MARK_READY');
      controller.busyKeys.refresh();
      await tester.pump();

      expect(find.text('Mark as Ready'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('terminal orders still render their action bar', () {
    testWidgets('a cancelled order that owes money keeps its refund buttons',
        (tester) async {
      // A cancelled order that owes money is not finished business.
      await _pump(tester, ['MARK_REFUND_SENT', 'CONTACT_CUSTOMER']);

      expect(find.text('I sent the refund'), findsOneWidget);
      expect(find.text('Contact Customer'), findsOneWidget);
    });
  });
}
