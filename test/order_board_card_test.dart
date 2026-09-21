import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_card_ui.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_lifecycle_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// **The BlueEra 2026 board, as the card renders it.**
///
/// The three order boards (`Customer Order Self / Cash / UPI`, `Business Side
/// Order Self / Cash / UPI`, `Order By Rider`) are one design applied to two
/// readers. These tests hold the parts of it a person actually reads off the
/// card — the status pill, the identity row, the summary and the money strip —
/// against the states that produce them.
///
/// They are deliberately *not* layout tests. Nothing here asserts a padding or
/// a colour; each one asserts a claim the card makes: that a `submitted`
/// payment is never shown as settled, that a shop's cash line says "Not Paid
/// Yet" until the cash is in, that the opening card lists what was ordered and
/// the later ones stop repeating it.

Future<void> _pump(
  WidgetTester tester, {
  required OrderLifecycle lifecycle,
  bool isOwner = false,
  String? deliveryType,
  OrderPaymentSummary? paymentSummary,
  String? pickupCode,
  List<String> actions = const [],
  List<OrderCardItem> items = const [],
  VoidCallback? onShopAgain,
  VoidCallback? onViewDetails,
  VoidCallback? onGetDirection,
  VoidCallback? onRate,
}) async {
  OrderLifecycleController.instance.orders['o1'] = OrderActionsModel(
    orderId: 'o1',
    orderNumber: '0D1247',
    actor: isOwner ? OrderActor.owner : OrderActor.customer,
    availableActions: actions,
    lifecycle: lifecycle,
    deadlines: lifecycle.deadlines,
    deliveryType: deliveryType,
    paymentSummary: paymentSummary,
    pickupCode: pickupCode,
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
                orderNumber: '0D1247',
                placedAtLabel: 'Today, 9:30 AM',
                shopName: 'Fresh Mart',
                shopAddress: 'sector 18 Market, Noida - 201301',
                items: items,
                onShopAgain: onShopAgain,
                onViewDetails: onViewDetails,
                onGetDirection: onGetDirection,
                onRate: onRate,
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

const _items = [
  OrderCardItem(name: 'Supreme Traditional Sugar', variant: '1kg', price: 200, mrp: 350),
  OrderCardItem(name: 'Supreme Traditional Rice', variant: '1kg', price: 200, mrp: 350),
];

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(OrderLifecycleController(), permanent: true);
  });

  tearDown(Get.reset);

  group('the header says who is waiting on whom', () {
    testWidgets('the customer gets a status pill; the shop gets the clock',
        (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'placed'}));
      expect(find.text('Order #0D1247'), findsOneWidget);
      expect(find.text('Waiting for acceptance'), findsOneWidget);

      await _pump(tester,
          lifecycle: _lc({'orderStatus': 'placed'}), isOwner: true);
      // The shop is the one being waited ON, so telling it that it is waiting
      // would be backwards. It gets the time the order landed instead.
      expect(find.text('Waiting for acceptance'), findsNothing);
      expect(find.text('Today, 9:30 AM'), findsOneWidget);
    });

    testWidgets('every live state has a pill, and it is never invented',
        (tester) async {
      for (final pair in const [
        ['accepted', 'Preparing'],
        ['in-progress', 'Preparing'],
        ['ready', 'Ready for pickup'],
        ['dispatched', 'Order Picked Up'],
        ['completed', 'Completed'],
        ['cancelled', 'Cancelled'],
      ]) {
        await _pump(tester, lifecycle: _lc({'orderStatus': pair[0]}));
        // `findsWidgets`: a cancelled card repeats the word in its details
        // table, which is the table's job.
        expect(find.text(pair[1]), findsWidgets,
            reason: '${pair[0]} should read "${pair[1]}"');
      }

      // A status this build has never heard of gets NO status pill rather
      // than a guessed one — the same rule the step strip keeps. (The money
      // strip still draws its own pill: an unpaid cash order is unpaid
      // whatever the server has decided to call the stage.)
      await _pump(tester, lifecycle: _lc({'orderStatus': 'awaiting_kyc'}));
      for (final label in const [
        'Waiting for acceptance',
        'Preparing',
        'Ready for pickup',
        'Order Picked Up',
        'Completed',
        'Cancelled',
      ]) {
        expect(find.text(label), findsNothing,
            reason: 'awaiting_kyc must not be guessed as "$label"');
      }
    });

    testWidgets('the identity row appears once the order is real',
        (tester) async {
      // `placed` is still a question, and the board keeps the method inside
      // the summary where the customer can still act on it.
      await _pump(tester, lifecycle: _lc({'orderStatus': 'placed'}));
      expect(find.text('Today, 9:30 AM'), findsOneWidget);
      expect(find.byType(OrderMetaRow), findsNothing);

      await _pump(tester, lifecycle: _lc({'orderStatus': 'ready'}));
      expect(find.byType(OrderMetaRow), findsWidgets);
      expect(find.text('Self Pickup'), findsWidgets);
      expect(find.text('Cash at Shop'), findsWidgets);
    });

    testWidgets('a doorstep order says so, on both ends', (tester) async {
      await _pump(tester,
          lifecycle: _lc({'orderStatus': 'accepted', 'paymentMethod': 'upi'}),
          deliveryType: 'rider');
      expect(find.text('Order By Rider'), findsWidgets);
      expect(find.text('Self Pickup'), findsNothing);
    });
  });

  group('the order summary stops repeating itself', () {
    testWidgets('the opening card lists what was ordered', (tester) async {
      await _pump(tester,
          lifecycle: _lc({'orderStatus': 'placed'}), items: _items);

      expect(find.text('Order summary'), findsOneWidget);
      expect(find.text('Supreme Traditional Sugar'), findsOneWidget);
      // The three method rows the board draws under the items.
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('Pickup Method'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
    });

    testWidgets('from `accepted` on, it is a thumbnail strip and a total',
        (tester) async {
      await _pump(tester,
          lifecycle: _lc({'orderStatus': 'accepted'}), items: _items);

      // By now the question is "where is it", not "what did I order".
      expect(find.text('Supreme Traditional Sugar'), findsNothing);
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('₹600'), findsWidgets);
    });
  });

  group('the money strip never says paid before it is', () {
    testWidgets('cash owes until the shop says otherwise', (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'accepted'}));
      expect(find.text('Not Paid Yet'), findsOneWidget);

      await _pump(tester, lifecycle: _lc({'orderStatus': 'ready'}));
      expect(find.text('Pending at Shop'), findsOneWidget);

      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'dispatched',
          'cashCollectedAt': '2026-09-15T10:00:00Z',
        }),
      );
      expect(find.text('Payment Completed'), findsWidgets);
    });

    testWidgets('a submitted UPI screenshot is not a settled payment',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'accepted',
          'paymentMethod': 'upi',
          'paymentState': 'submitted',
        }),
      );
      // No green strip, no "Payment Completed" — the shop has not looked yet.
      expect(find.text('Payment Completed'), findsNothing);
      expect(find.text('Payment Details Submitted'), findsOneWidget);
    });
  });

  group('the collection sequence differs by who is holding the goods', () {
    testWidgets('the customer sees how to collect, then the code',
        (tester) async {
      await _pump(tester, lifecycle: _lc({'orderStatus': 'ready'}));
      expect(find.text('When you arrive at the shop'), findsOneWidget);
      expect(find.text('Show Code'), findsOneWidget);
      // The digits are not on the card until they are asked for.
      expect(find.byType(OrderCodeBoxes), findsNothing);

      await _pump(tester,
          lifecycle: _lc({'orderStatus': 'ready'}), pickupCode: '2222');
      expect(find.text('Pickup Verification'), findsOneWidget);
      expect(find.byType(OrderCodeBoxes), findsOneWidget);
      expect(find.text('2'), findsNWidgets(4));
    });

    testWidgets('the shop enters the code, THEN takes the money',
        (tester) async {
      // Code first, money second, goods last. A shop that hands the bag over
      // first has no leverage left to collect with.
      await _pump(
        tester,
        isOwner: true,
        lifecycle: _lc({
          'orderStatus': 'ready',
          'ownerActions': ['CONFIRM_HANDOVER'],
        }),
        actions: const ['CONFIRM_HANDOVER'],
      );
      expect(find.text('Verify Pickup Code'), findsOneWidget);
      expect(find.text('Collect ₹600 from Customer'), findsNothing);

      await _pump(
        tester,
        isOwner: true,
        lifecycle: _lc({
          'orderStatus': 'ready',
          'pickupVerifiedAt': '2026-09-15T10:00:00Z',
        }),
      );
      expect(find.text('Verify Pickup Code'), findsNothing);
      expect(find.text('Collect ₹600 from Customer'), findsOneWidget);
    });

    testWidgets('a doorstep order has no counter to collect at',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'orderStatus': 'ready', 'paymentMethod': 'upi'}),
        deliveryType: 'rider',
      );
      expect(find.text('When you arrive at the shop'), findsNothing);
      expect(find.text('Show Code'), findsNothing);
    });
  });

  group('the board draws buttons the state machine has no action for', () {
    testWidgets('completed offers View Details and Shop Again',
        (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'orderStatus': 'completed'}),
        onViewDetails: () {},
        onShopAgain: () {},
      );
      expect(find.text('Order Completed!'), findsOneWidget);
      expect(find.text('View Details'), findsWidgets);
      expect(find.text('Shop Again'), findsOneWidget);
    });

    testWidgets('cancelled offers Continue Shopping', (tester) async {
      await _pump(
        tester,
        lifecycle: _lc({'orderStatus': 'cancelled'}),
        onShopAgain: () {},
      );
      expect(find.text('Order Cancelled'), findsOneWidget);
      expect(find.text('Continue Shopping'), findsOneWidget);
    });

    testWidgets('a handler that was not supplied draws no button',
        (tester) async {
      // Better a missing button than one that goes nowhere.
      await _pump(tester, lifecycle: _lc({'orderStatus': 'completed'}));
      expect(find.text('Shop Again'), findsNothing);
      expect(find.text('View Details'), findsNothing);
    });

    testWidgets('the shop never gets the customer\'s navigation buttons',
        (tester) async {
      await _pump(
        tester,
        isOwner: true,
        lifecycle: _lc({'orderStatus': 'completed'}),
        onShopAgain: () {},
        onViewDetails: () {},
      );
      expect(find.text('Shop Again'), findsNothing);
    });
  });

  group('the server still owns the words', () {
    testWidgets('a banner renders even when a panel is on screen',
        (tester) async {
      // The 60-second sweep's nudges arrive as banner text and nothing else
      // (guide §8), so suppressing it because a panel is drawn is how an order
      // silently stops explaining itself.
      await _pump(
        tester,
        lifecycle: _lc({
          'orderStatus': 'accepted',
          'banner': 'Taking longer than expected — ready in ~25 min',
        }),
      );
      expect(
        find.text('Taking longer than expected — ready in ~25 min'),
        findsOneWidget,
      );
    });
  });
}
