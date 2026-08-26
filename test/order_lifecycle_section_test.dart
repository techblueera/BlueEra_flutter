import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_lifecycle_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> _pump(
  WidgetTester tester, {
  required OrderLifecycle? lifecycle,
  bool isOwner = false,
  OrderPaymentSummary? paymentSummary,
  Widget? legacyFallback,
}) async {
  // Seed the store the way `/actions` would, including **`actor`** — the
  // server's own answer to "whose buttons are these" (guide §2.2). Without it
  // the section asks the server on mount, exactly as it does in the app.
  if (lifecycle != null) {
    OrderLifecycleController.instance.orders['o1'] = OrderActionsModel(
      orderId: 'o1',
      actor: isOwner ? OrderActor.owner : OrderActor.customer,
      availableActions: const [],
      lifecycle: lifecycle,
      deadlines: lifecycle.deadlines,
      paymentSummary: paymentSummary,
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return Scaffold(
          body: SingleChildScrollView(
            child: OrderLifecycleSection(
              ctx: OrderCardContext(
                orderId: 'o1',
                isOwner: isOwner,
                otherUserId: 'u2',
                orderTotal: 500,
              ),
              fallbackLifecycle: lifecycle,
              legacyFallback: legacyFallback,
            ),
          ),
        );
      }),
    ),
  );
  await tester.pump();
}

OrderLifecycle _lc(Map<String, dynamic> overrides) =>
    OrderLifecycle.fromJson({
      'orderStatus': 'placed',
      'paymentMethod': 'cash',
      'paymentState': 'pending',
      'customerActions': <String>[],
      'ownerActions': <String>[],
      ...overrides,
    });

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(OrderLifecycleController(), permanent: true);
  });

  tearDown(Get.reset);

  group('the banner is server-authored and rendered verbatim', () {
    testWidgets('shows exactly the string the server sent', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'banner': 'Order cancelled by shop — item not available',
          'orderStatus': 'cancelled'}),
      );
      expect(
        find.text('Order cancelled by shop — item not available'),
        findsOneWidget,
      );
    });

    testWidgets('never builds its own string from orderStatus',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'orderStatus': 'ready', 'banner': 'Come and get it'}),
      );
      expect(find.text('Come and get it'), findsOneWidget);
      // No status-derived copy leaks in alongside it.
      expect(find.text('ready'), findsNothing);
      expect(find.text('Ready for Pickup'), findsNothing);
    });

    testWidgets('a legacy order with no lifecycle keeps its own UI',
        (tester) async {
      await _pump(
        tester,
        lifecycle: null,
        legacyFallback: const Text('LEGACY ROW'),
      );
      expect(find.text('LEGACY ROW'), findsOneWidget);
    });
  });

  group('deadlines drive the countdown', () {
    testWidgets('a placed order counts down to acceptBy', (tester) async {
      final acceptBy =
          DateTime.now().toUtc().add(const Duration(minutes: 7)).toIso8601String();
      await _pump(
        tester,
        isOwner: true,
        lifecycle: _lc({
          'banner': 'New order',
          'deadlines': {'acceptBy': acceptBy},
        }),
      );
      expect(find.byType(OrderDeadlineCountdown), findsOneWidget);
      expect(find.textContaining('Confirm within'), findsOneWidget);
    });

    testWidgets('no deadline means no countdown — not an expired card',
        (tester) async {
      await _pump(tester, lifecycle: _lc({'banner': 'New order'}));
      expect(find.byType(OrderDeadlineCountdown), findsNothing);
      expect(find.textContaining('Expired'), findsNothing);
      expect(find.textContaining('Order Closed'), findsNothing);
    });

    testWidgets('a terminal order shows no countdown at all', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'banner': 'Cancelled',
          'deadlines': {
            'acceptBy':
                DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String()
          },
        }),
      );
      expect(find.byType(OrderDeadlineCountdown), findsNothing);
    });
  });

  group('payment sub-states never collapse into one step', () {
    testWidgets('a submitted payment is a CLAIM on the customer side',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'accepted',
          'paymentMethod': 'upi',
          'paymentState': 'submitted',
          'banner': 'Preparing',
        }),
      );
      expect(
        find.text('Waiting for the shop to confirm your payment'),
        findsOneWidget,
      );
      // "Paid" must never appear for a submitted payment.
      expect(find.textContaining('Paid'), findsNothing);
    });

    testWidgets('the owner sees "says they paid", paid vs due, and a mismatch',
        (tester) async {
      await _pump(
        tester,
        isOwner: true,
        lifecycle: _lc({
          'orderStatus': 'accepted',
          'paymentMethod': 'upi',
          'paymentState': 'submitted',
          'banner': 'Preparing',
        }),
        paymentSummary: OrderPaymentSummary.fromJson({
          'amountDue': 500,
          'amountPaid': 450,
          'utrNo': 'UTR9988',
        }),
      );

      expect(find.text('Customer says they paid'), findsOneWidget);
      expect(find.text('₹450'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
      expect(
        find.textContaining('does not match the order total'),
        findsOneWidget,
      );
      expect(find.text('UTR UTR9988'), findsOneWidget);
    });

    testWidgets('a rejected payment shows the shop\'s reason', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'accepted',
          'paymentMethod': 'upi',
          'paymentState': 'rejected',
          'banner': 'Preparing',
        }),
        paymentSummary: OrderPaymentSummary.fromJson({
          'amountDue': 500,
          'rejectedReason': 'Nothing reached my account',
        }),
      );
      expect(
        find.text('Payment not confirmed: Nothing reached my account'),
        findsOneWidget,
      );
    });

    testWidgets('a cash order shows no payment block at all', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'accepted',
          'paymentMethod': 'cash',
          'paymentState': 'pending',
          'banner': 'Preparing',
        }),
      );
      expect(find.textContaining('says they paid'), findsNothing);
      expect(find.textContaining('confirm your payment'), findsNothing);
    });
  });

  group('refunds say WHO owes the money', () {
    testWidgets('step 1 names the shop, and never says "we will refund you"',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'paymentMethod': 'upi',
          'paymentState': 'refund_pending',
          'refundOwedBy': 'shop',
          'banner': 'Order cancelled',
        }),
        paymentSummary: OrderPaymentSummary.fromJson({'amountPaid': 500}),
      );

      expect(find.textContaining('returned by the shop'), findsOneWidget);
      expect(find.textContaining('₹500'), findsOneWidget);
      // The two phrasings that manufacture a complaint against us.
      expect(find.textContaining('we will refund'), findsNothing);
      expect(find.textContaining('refund is being processed'), findsNothing);
      expect(find.textContaining('Refund processed'), findsNothing);
    });

    testWidgets('step 2 is a CLAIM — the card does not settle', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'paymentMethod': 'upi',
          'paymentState': 'refund_pending',
          'refundOwedBy': 'shop',
          'refundInitiatedAt': '2026-08-21T12:00:00Z',
          'refundReference': 'UTR777',
          'customerActions': ['CONFIRM_REFUND_RECEIVED'],
          'banner': 'Order cancelled',
        }),
        paymentSummary: OrderPaymentSummary.fromJson({'amountPaid': 500}),
      );

      expect(find.textContaining("says they've sent"), findsOneWidget);
      expect(find.textContaining('UTR777'), findsOneWidget);
      // The confirm button is what actually closes it.
      expect(find.text('I received the refund'), findsOneWidget);
      expect(find.textContaining('Refund received ✓'), findsNothing);
    });

    testWidgets('the owner waits for the customer at step 2', (tester) async {
      await _pump(
        tester,
        isOwner: true,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'paymentMethod': 'upi',
          'paymentState': 'refund_pending',
          'refundInitiatedAt': '2026-08-21T12:00:00Z',
          'banner': 'Order cancelled',
        }),
        paymentSummary: OrderPaymentSummary.fromJson({'amountPaid': 500}),
      );
      expect(
        find.textContaining('Waiting for the customer to confirm'),
        findsOneWidget,
      );
    });

    testWidgets('step 3 settles on both sides', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'paymentMethod': 'upi',
          'paymentState': 'refunded',
          'banner': 'Order cancelled',
        }),
      );
      expect(find.text('Refund received ✓'), findsOneWidget);
    });
  });

  group('reminders and escalations', () {
    testWidgets('NEEDS_ATTENTION shows a neutral strip, never a reason code',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'banner': 'We are checking',
          'lastEvent': 'PRODUCT_ORDER_NEEDS_ATTENTION',
          'reasonCode': 'INTERNAL_SETTLEMENT_LAG',
        }),
      );
      expect(find.text("We're looking into this order."), findsOneWidget);
      // The internal code is never exposed to either party.
      expect(find.textContaining('INTERNAL_SETTLEMENT_LAG'), findsNothing);
    });
  });

  group('terminal orders keep their action bar', () {
    testWidgets('a cancelled order that owes money still shows buttons',
        (tester) async {
      await _pump(
        tester,
        isOwner: true,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'paymentMethod': 'upi',
          'paymentState': 'refund_pending',
          'ownerActions': ['MARK_REFUND_SENT', 'CONTACT_CUSTOMER'],
          'banner': 'Order cancelled — you owe a refund',
        }),
      );
      expect(find.text('I sent the refund'), findsOneWidget);
      expect(find.byIcon(Icons.call), findsOneWidget);
    });
  });
}
