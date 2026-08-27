import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The findings from `ORDER_FLOW_CLIENT_CONTRACT_REVIEW.md`, each pinned to a
/// test so a future refactor cannot quietly undo them.
///
/// `/track` is the third plane and the awkward one: it answers the same
/// questions as `/actions` under **different key names**, and omits things the
/// action responses carry. Everything here is about not losing information when
/// those payloads land on top of each other.
void main() {
  /// A realistic `GET /:orderId/track` body, keys exactly as the service sends
  /// them: `viewerRole` rather than `actor`, `paymentSummary` rather than
  /// `payment`, and a `needsAttention` object with **no `flagged`**.
  Map<String, dynamic> trackBody({
    Map<String, dynamic>? needsAttention,
    Map<String, dynamic>? paymentSummary,
    String viewerRole = 'owner',
    String? orderStatus = 'ready',
  }) =>
      {
        'success': true,
        'data': {
          'orderId': 'o1',
          'orderNumber': 'PROD260826',
          'viewerRole': viewerRole,
          if (orderStatus != null) 'orderStatus': orderStatus,
          'availableActions': ['CONFIRM_HANDOVER', 'CONTACT_CUSTOMER'],
          'paymentSummary': paymentSummary ??
              {
                'method': 'upi',
                'state': 'verified',
                'amountDue': 500,
                'amountPaid': 500,
                'utrNo': '4429XXXX9921',
                'screenshotUrl': 'https://s3/shot.png',
                'submittedAt': '2026-08-26T10:00:00Z',
                'verifiedAt': '2026-08-26T10:04:00Z',
              },
          if (needsAttention != null) 'needsAttention': needsAttention,
        },
      };

  // ── Finding 2 ────────────────────────────────────────────────────────
  group('/track answers viewerRole, not actor', () {
    test('the role is read, so nothing falls back to the card heuristic', () {
      final m = OrderActionsModel.fromJson(trackBody());
      expect(m.actor, 'owner');
      expect(m.isOwner, isTrue);
      expect(m.isOwnerOrNull, isTrue);
    });

    test('a customer viewer is read the same way', () {
      final m = OrderActionsModel.fromJson(trackBody(viewerRole: 'customer'));
      expect(m.isOwnerOrNull, isFalse);
    });

    test('actor still wins where both could appear', () {
      final m = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'actor': 'customer',
          'viewerRole': 'owner',
          'orderStatus': 'ready',
        }
      });
      expect(m.actor, 'customer');
    });

    test('an admin viewing through /track is still an admin', () {
      final m = OrderActionsModel.fromJson(trackBody(viewerRole: 'admin'));
      expect(m.isAdmin, isTrue);
      expect(m.isOwner, isFalse);
    });
  });

  // ── Finding 3 ────────────────────────────────────────────────────────
  group('/track needsAttention has no flagged key — presence IS the flag', () {
    test('the object alone raises the strip', () {
      final m = OrderActionsModel.fromJson(trackBody(needsAttention: {
        'reason': 'PAYMENT_REVIEW',
        'flaggedAt': '2026-08-26T11:00:00Z',
      }));
      expect(m.needsAttention, isTrue);
    });

    test('null means not flagged', () {
      final m = OrderActionsModel.fromJson(trackBody());
      expect(m.needsAttention, isFalse);
    });

    test('an action response still uses the explicit flag, both ways', () {
      final on = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderStatus': 'ready',
          'needsAttention': {'flagged': true, 'reason': 'DISPUTED'},
        }
      });
      final off = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderStatus': 'ready',
          'needsAttention': {'flagged': false, 'reason': 'DISPUTED'},
        }
      });
      expect(on.needsAttention, isTrue);
      // An explicit `flagged: false` is an answer, and it is "no".
      expect(off.needsAttention, isFalse);
    });

    test('/actions sends a bare bool', () {
      final m = OrderActionsModel.fromJson({
        'data': {'orderId': 'o1', 'orderStatus': 'ready', 'needsAttention': true}
      });
      expect(m.needsAttention, isTrue);
    });

    test('the internal reason code is never carried onto the model', () {
      final m = OrderActionsModel.fromJson(trackBody(needsAttention: {
        'reason': 'CUSTOMER_NO_SHOW',
      }));
      // The strip is neutral by contract; nothing in the model can leak an ops
      // taxonomy that half the time accuses somebody.
      expect(m.needsAttention, isTrue);
      expect(m.toString(), isNot(contains('CUSTOMER_NO_SHOW')));
    });
  });

  // ── Finding 4 ────────────────────────────────────────────────────────
  group('/track carries no refund fields — a refresh must not erase them', () {
    OrderActionsModel refundPending() => OrderActionsModel.fromJson({
          'data': {
            'orderId': 'o1',
            'actor': 'customer',
            'orderStatus': 'cancelled',
            'payment': {
              'method': 'upi',
              'state': 'refund_pending',
              'amountDue': 500,
              'amountPaid': 500,
              'refundOwedBy': 'shop',
              'refundRequestedAt': '2026-08-26T12:00:00Z',
              'refundInitiatedAt': '2026-08-26T12:30:00Z',
              'refundReference': 'UTR-REFUND-1',
            },
          }
        });

    test('step 2 survives a cold /track refresh', () {
      final live = refundPending();
      expect(live.paymentSummary?.refundInitiatedAt, isNotNull);

      final track = OrderActionsModel.fromJson(trackBody(
        viewerRole: 'customer',
        orderStatus: 'cancelled',
        paymentSummary: {
          'method': 'upi',
          'state': 'refund_pending',
          'amountDue': 500,
          'amountPaid': 500,
          // …and nothing else. No refund keys at all.
        },
      ));
      expect(track.paymentSummary?.refundInitiatedAt, isNull,
          reason: '/track really does omit them');

      final merged = live.mergedWith(track);
      // The distinction between "the shop owes you ₹500" and "the shop says it
      // sent ₹500" is exactly this field.
      expect(merged.paymentSummary?.refundInitiatedAt, isNotNull);
      expect(merged.paymentSummary?.refundReference, 'UTR-REFUND-1');
      expect(merged.paymentSummary?.refundOwedBy, 'shop');
      // …while what /track DOES say still lands.
      expect(merged.paymentSummary?.state, 'refund_pending');
    });

    test('a newer value still overwrites an older one', () {
      final live = refundPending();
      final settled = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderStatus': 'cancelled',
          'payment': {
            'state': 'refunded',
            'refundedAt': '2026-08-26T13:00:00Z',
            'refundReference': 'UTR-REFUND-2',
          },
        }
      });
      final merged = live.mergedWith(settled);
      expect(merged.paymentSummary?.state, 'refunded');
      expect(merged.paymentSummary?.refundReference, 'UTR-REFUND-2');
      expect(merged.paymentSummary?.refundedAt, isNotNull);
      // Untouched keys are still there.
      expect(merged.paymentSummary?.amountPaid, 500);
    });

    test('refundDue from Plane A is not cleared by a payload that never '
        'mentions it', () {
      final card = OrderActionsModel(
        orderId: 'o1',
        availableActions: const [],
        lifecycle: OrderLifecycle.fromJson({
          'orderStatus': 'cancelled',
          'paymentState': 'refund_pending',
          'refundDue': true,
          'banner': 'Cancelled — the shop will return ₹500',
        }),
        deadlines: const OrderDeadlines(),
      );
      expect(card.lifecycle.refundDue, isTrue);

      // `/actions` says nothing about refunds.
      final actions = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'actor': 'customer',
          'orderStatus': 'cancelled',
          'availableActions': ['CONFIRM_REFUND_RECEIVED'],
        }
      });
      expect(actions.lifecycle.refundDue, isFalse);
      expect(actions.lifecycle.refundDueStated, isFalse);

      final merged = card.mergedWith(actions);
      expect(merged.lifecycle.refundDue, isTrue,
          reason: 'a silent false must not close a refund');
      expect(merged.availableActions, ['CONFIRM_REFUND_RECEIVED']);
    });
  });

  // ── The banner, which /actions does not carry at all ─────────────────
  group('/actions carries no banner — a refresh must not blank the card', () {
    test('the server-authored status line survives a refresh', () {
      final card = OrderActionsModel(
        orderId: 'o1',
        availableActions: const [],
        lifecycle: OrderLifecycle.fromJson({
          'orderStatus': 'ready',
          'paymentMethod': 'upi',
          'paymentState': 'verified',
          'banner': 'Payment verified by the shop',
          'customerActions': ['VIEW_PICKUP_CODE'],
        }),
        deadlines: const OrderDeadlines(),
      );

      final actions = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderNumber': 'PROD260826',
          'actor': 'customer',
          'orderStatus': 'ready',
          'sellerStatus': 'ready',
          'paymentMethod': 'upi',
          'paymentState': 'verified',
          'deliveryType': 'self-pickup',
          'isTerminal': false,
          'needsAttention': false,
          'deadlines': {'pickupBy': '2026-08-26T14:30:00Z'},
          'availableActions': ['VIEW_PICKUP_CODE', 'CONTACT_SHOP'],
          'cancellationReasons': ['CHANGED_MIND'],
        }
      });
      expect(actions.lifecycle.banner, isNull, reason: '/actions has no banner');

      final merged = card.mergedWith(actions);
      expect(merged.lifecycle.banner, 'Payment verified by the shop');
      expect(merged.availableActions, ['VIEW_PICKUP_CODE', 'CONTACT_SHOP']);
      expect(merged.deadlines.pickupBy, isNotNull);
      expect(merged.cancellationReasons.single.code, 'CHANGED_MIND');
      expect(merged.deliveryType, 'self-pickup');
    });

    test('a newer banner does replace the old one', () {
      final card = OrderActionsModel(
        orderId: 'o1',
        availableActions: const [],
        lifecycle: OrderLifecycle.fromJson(
            {'orderStatus': 'accepted', 'banner': 'Preparing'}),
        deadlines: const OrderDeadlines(),
      );
      final socket = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderStatus': 'ready',
          'banner': 'Your order is ready for pickup',
        }
      });
      expect(card.mergedWith(socket).lifecycle.banner,
          'Your order is ready for pickup');
    });

    test('an empty action list from a payload that described the state is '
        'honoured — "nothing to do" is a real answer', () {
      final card = OrderActionsModel(
        orderId: 'o1',
        availableActions: const ['SUBMIT_PAYMENT'],
        lifecycle: OrderLifecycle.fromJson({'orderStatus': 'accepted'}),
        deadlines: const OrderDeadlines(),
      );
      final noActions = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderStatus': 'accepted',
          'paymentState': 'submitted',
          'availableActions': <String>[],
        }
      });
      expect(card.mergedWith(noActions).availableActions, isEmpty);
    });
  });

  // ── Finding 1, client side ───────────────────────────────────────────
  group('the shop can still decline when the reason list is empty', () {
    // The server-side cause is fixed (a pending order now returns the OWNER
    // list), but the client must not be the thing that stalls either — an
    // empty list is always possible, e.g. an /actions call that failed.
    testWidgets('an empty list degrades to a note and submits OTHER',
        (tester) async {
      OrderReasonChoice? choice;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              SizeConfig.init(context);
              return ElevatedButton(
              onPressed: () async {
                choice = await showOrderReasonSheet(
                  context,
                  title: "Why can't you take this order?",
                  reasons: const [],
                  confirmLabel: "Can't take it",
                  fallbackReasonCode: 'OTHER',
                );
              },
                child: const Text('open'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Nothing to pick, so the note carries the reason instead.
      await tester.enterText(find.byType(TextField).first, 'Out of stock');
      await tester.tap(find.text("Can't take it"));
      await tester.pumpAndSettle();

      expect(choice, isNotNull);
      expect(choice!.reasonCode, 'OTHER');
      expect(choice!.comment, 'Out of stock');
    });

    testWidgets('with a list, a bare string reason is pickable and submits '
        'its code', (tester) async {
      OrderReasonChoice? choice;
      final reasons = ['ITEM_UNAVAILABLE', 'SHOP_CLOSED']
          .map(OrderCancellationReason.fromJson)
          .toList();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              SizeConfig.init(context);
              return ElevatedButton(
              onPressed: () async {
                choice = await showOrderReasonSheet(
                  context,
                  title: "Why can't you take this order?",
                  reasons: reasons,
                  confirmLabel: "Can't take it",
                );
              },
                child: const Text('open'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Item unavailable'), findsOneWidget);
      await tester.tap(find.text('Item unavailable'));
      await tester.pump();
      await tester.tap(find.text("Can't take it"));
      await tester.pumpAndSettle();

      expect(choice!.reasonCode, 'ITEM_UNAVAILABLE');
    });
  });
}
