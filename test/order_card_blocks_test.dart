import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_journey_strip.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_lifecycle_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/widget/upi_qr_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The card blocks the three order boards draw and the card did not:
/// the step strip, the arrival instructions, the rider-fee QR and the
/// cancellation table.
///
/// Every test here is about a **claim the card makes to a person**, not about
/// layout: that a paid customer is never told to pay again, that a QR with no
/// VPA behind it is not drawn, that "₹0 collected" is stated rather than
/// implied.
Future<void> _pump(
  WidgetTester tester, {
  required OrderLifecycle lifecycle,
  bool isOwner = false,
  String? deliveryType,
  OrderPaymentSummary? paymentSummary,
  OrderCancellationInfo? cancellation,
}) async {
  OrderLifecycleController.instance.orders['o1'] = OrderActionsModel(
    orderId: 'o1',
    actor: isOwner ? OrderActor.owner : OrderActor.customer,
    availableActions: const [],
    lifecycle: lifecycle,
    deadlines: lifecycle.deadlines,
    deliveryType: deliveryType,
    paymentSummary: paymentSummary,
    cancellation: cancellation,
  );

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
                orderTotal: 600,
              ),
              fallbackLifecycle: lifecycle,
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

  group('the step strip', () {
    testWidgets('draws on any order the server has given a status',
        (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'ready'}));
      expect(find.byType(OrderJourneyStrip), findsOneWidget);
    });

    testWidgets('draws nothing for a status this build does not know',
        (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'awaiting_kyc'}));
      expect(find.byType(OrderJourneyStrip), findsNothing);
    });
  });

  group('when you arrive at the shop', () {
    testWidgets('cash: five steps, including paying at the counter',
        (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'ready'}));
      expect(find.text('When you arrive at the shop'), findsOneWidget);
      expect(find.text('Pay the final amount in cash'), findsOneWidget);
      expect(find.text('Collect your order'), findsOneWidget);
      expect(
        find.text('Pickup code will be available when you arrive'),
        findsOneWidget,
      );
    });

    testWidgets('UPI: never tells a customer who already paid to pay again',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'ready',
          'paymentMethod': 'upi',
          'paymentState': 'verified',
        }),
      );
      expect(find.text('When you arrive at the shop'), findsOneWidget);
      // The one line that must not appear: that money is already with the shop.
      expect(find.text('Pay the final amount in cash'), findsNothing);
    });

    testWidgets('not before the order is ready', (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'accepted'}));
      expect(find.text('When you arrive at the shop'), findsNothing);
    });

    testWidgets('never on the shop\'s own card', (tester) async {
      await _pump(tester,
          lifecycle: _lc({'orderStatus': 'ready'}), isOwner: true);
      expect(find.text('When you arrive at the shop'), findsNothing);
    });

    testWidgets('never on a doorstep order — the rider collects, not the buyer',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'orderStatus': 'ready', 'paymentMethod': 'upi'}),
        deliveryType: 'rider',
      );
      expect(find.text('When you arrive at the shop'), findsNothing);
    });
  });

  group('the rider fee', () {
    Map<String, dynamic> riderPaymentLifecycle({
      String state = 'pending',
      Object? upiId = 'amit@okaxis',
      num? amount = 100,
    }) =>
        {
          'orderStatus': 'delivered',
          'paymentMethod': 'upi',
          'paymentState': 'verified',
          'riderPayment': {
            'state': state,
            if (upiId != null) 'upiId': upiId,
            if (amount != null) 'amount': amount,
            'payeeName': 'Amit',
          },
        };

    testWidgets('renders the fee, a QR and a copyable VPA', (tester) async {
      await _pump(tester,
          lifecycle: _lc(riderPaymentLifecycle()), deliveryType: 'rider');
      expect(find.text('Delivery fee'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);
      expect(find.text('amit@okaxis'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    test('the amount rides inside the UPI link, so nobody types it', () {
      // The QR the block draws is built from this payload. A fee typed by hand
      // is a fee typed wrong, and then argued about at the door.
      final link =
          upiQrPayload('amit@okaxis', payeeName: 'Amit', amount: 100);
      expect(link, contains('pa=amit%40okaxis'));
      expect(link, contains('am=100.00'));
      expect(link, contains('pn=Amit'));
      // No amount → no `am=`, so the payer is not shown a figure of ₹0.
      expect(upiQrPayload('amit@okaxis'), isNot(contains('am=')));
      expect(upiQrPayload('amit@okaxis', amount: 0), isNot(contains('am=')));
    });

    testWidgets('no VPA — no block, rather than an empty frame',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc(riderPaymentLifecycle(upiId: null)),
        deliveryType: 'rider',
      );
      expect(find.text('Delivery fee'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('a submitted payment is a claim, never a settled fee',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc(riderPaymentLifecycle(state: 'submitted')),
        deliveryType: 'rider',
      );
      expect(
        find.text('Waiting for your delivery partner to confirm the payment'),
        findsOneWidget,
      );
    });

    testWidgets('paid — the block is gone', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc(riderPaymentLifecycle(state: 'paid')),
        deliveryType: 'rider',
      );
      expect(find.text('Delivery fee'), findsNothing);
    });

    testWidgets('never asks the shop to pay the rider', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc(riderPaymentLifecycle()),
        deliveryType: 'rider',
        isOwner: true,
      );
      expect(find.text('Delivery fee'), findsNothing);
    });
  });

  group('cancellation details', () {
    testWidgets('cash, cancelled before collection — ₹0 is stated outright',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'orderStatus': 'cancelled', 'reasonCode': 'CHANGED_MY_MIND'}),
        cancellation: const OrderCancellationInfo(
          cancelledBy: 'customer',
          reasonCode: 'CHANGED_MY_MIND',
        ),
      );
      expect(find.text('Cancellation details'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Changed my mind'), findsOneWidget);
      expect(find.text('Cash at shop'), findsOneWidget);
      expect(find.text('Cash collected'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('a free-text note wins over the code', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'orderStatus': 'cancelled'}),
        cancellation: const OrderCancellationInfo(
          cancelledBy: 'owner',
          reasonCode: 'OTHER',
          comment: 'Shop closed early today',
        ),
      );
      expect(find.text('Shop closed early today'), findsOneWidget);
      expect(find.text('Other'), findsNothing);
    });

    testWidgets('a refund in play owns the money line — the table drops it',
        (tester) async {
      // One money line per card: the refund block above is already saying who
      // owes what. Stating the same rupees twice, in two tenses, is how a
      // customer ends up believing they are owed it twice or not at all.
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'paymentMethod': 'upi',
          'paymentState': 'refund_pending',
          'refundDue': true,
        }),
        paymentSummary: OrderPaymentSummary.fromJson(const {
          'state': 'refund_pending',
          'amountDue': 600,
          'amountPaid': 600,
        }),
        cancellation: const OrderCancellationInfo(cancelledBy: 'owner'),
      );
      expect(find.text('Cancellation details'), findsOneWidget);
      expect(find.text('Amount paid'), findsNothing);
      // And it certainly never reports money that WAS paid as ₹0.
      expect(find.text('₹0'), findsNothing);
    });

    testWidgets('UPI with nothing paid still states ₹0', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'cancelled',
          'paymentMethod': 'upi',
          'paymentState': 'pending',
        }),
        cancellation: const OrderCancellationInfo(cancelledBy: 'customer'),
      );
      expect(find.text('Amount paid'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('expired says Expired, not Cancelled', (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'expired'}));
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('a live order has no epitaph', (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'ready'}));
      expect(find.text('Cancellation details'), findsNothing);
    });
  });
}
