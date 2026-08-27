import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_track_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_vertical_capabilities.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/grocery_order_msg_card.dart';
import 'package:BlueEra/features/chat/view/widget/order_card_dedupe.dart';
import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// `lib/docs/ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md`, case by case.
///
/// The payloads below are the ones the audit captured against the live
/// backend on 27 Aug 2026 — `metadata.order` as a bare string, no `lifecycle`
/// key at all, `orderStatus` disagreeing with `currentStage`. They are the
/// contract, not accidents, so each one gets a test that fails loudly if the
/// app ever starts assuming otherwise.
void main() {
  // ═══════════════════════════════════════════════════════════════════
  //  §2.1 / §2.2 — the message envelope, exactly as captured
  // ═══════════════════════════════════════════════════════════════════

  Messages groceryMessage({
    dynamic order,
    dynamic orderStatus,
    bool isCancelled = false,
    String? groceryOrderId,
    String createdAt = '2026-08-27T06:35:15.852Z',
    bool myMessage = true,
    bool deleted = false,
    String id = 'm1',
  }) {
    return Messages.fromJson({
      '_id': id,
      'message': 'New grocery order',
      'message_type': 'grocery_order',
      'sub_type': 'grocery_order',
      'conversation_id': null,
      'senderId': 's1',
      'created_at': createdAt,
      'my_message': myMessage,
      'delete_from_everyone': deleted,
      'metadata': {
        'order': order,
        'order_status': orderStatus,
        'is_cancelled': isCancelled,
        if (groceryOrderId != null) 'groceryOrderId': groceryOrderId,
        'user': null,
        'receiverUser': null,
        'rider': null,
        'otp': null,
        'missed_call': false,
        'is_announcement': false,
      },
    });
  }

  group('C3 · metadata.order as a bare String never crashes the parse', () {
    test('a string id lands in orderRefId, never in order', () {
      final m = groceryMessage(order: '6a8fda1d0000000000000000');

      expect(m.metadata?.order, isNull,
          reason: 'a String is an id, not an order object');
      expect(m.metadata?.orderRefId, '6a8fda1d0000000000000000');
      expect(GroceryOrderMsgCard.orderIdOf(m), '6a8fda1d0000000000000000');
    });

    test('the card renders from an id alone', () {
      final m = groceryMessage(order: '6a8fda1d0000000000000000');
      expect(GroceryOrderMsgCard.canRender(m), isTrue);
      expect(GroceryOrderMsgCard.snapshotOf(m), isNull);
    });

    test('an order OBJECT still parses into the snapshot', () {
      final m = groceryMessage(
        order: {
          'orderId': 'o9',
          'businessId': 'b1',
          'grandTotal': 48,
          'totalItems': 3,
          'items': [
            {
              'productName': 'Act II Popcorn',
              'quantity': 2,
              'mrp': 26,
              'sellingPrice': 24,
            }
          ],
        },
        groceryOrderId: 'o9',
      );
      expect(GroceryOrderMsgCard.snapshotOf(m)?.grandTotal, 48);
      expect(GroceryOrderMsgCard.orderIdOf(m), 'o9');
    });
  });

  group('C1 / C2 · an orphan card is a text bubble, not an empty card', () {
    test('no order and no id → nothing to draw', () {
      final m = groceryMessage(order: null);
      expect(GroceryOrderMsgCard.orderIdOf(m), isEmpty);
      expect(GroceryOrderMsgCard.canRender(m), isFalse);
    });

    test('C11 · a deleted message never draws the card', () {
      final m = groceryMessage(order: 'o1', deleted: true);
      expect(GroceryOrderMsgCard.canRender(m), isFalse);
    });
  });

  group('§2.2 · order_status arrives as a STRING on this card', () {
    test("'ready' does not throw, and reads as ready", () {
      final m = groceryMessage(order: 'o1', orderStatus: 'ready');
      expect(m.metadata?.orderStatusText, 'ready');
      expect(m.metadata?.orderStatus, isTrue);
    });

    test("'placed' is not ready", () {
      final m = groceryMessage(order: 'o1', orderStatus: 'placed');
      expect(m.metadata?.orderStatusText, 'placed');
      expect(m.metadata?.orderStatus, isFalse);
    });

    test('a bool still round-trips for the verticals that send one', () {
      final m = groceryMessage(order: 'o1', orderStatus: true);
      expect(m.metadata?.orderStatus, isTrue);
      expect(m.metadata?.orderStatusText, isNull);
      expect(m.metadata?.toJson()['order_status'], isTrue);
    });

    test('a state this build has never seen is neither ready nor not-ready',
        () {
      final m = groceryMessage(order: 'o1', orderStatus: 'quantum');
      expect(m.metadata?.orderStatus, isNull);
      expect(m.metadata?.orderStatusText, 'quantum');
    });

    test('the string shape survives a toJson round-trip', () {
      final m = groceryMessage(order: 'o1', orderStatus: 'ready');
      expect(m.metadata?.toJson()['order_status'], 'ready');
    });
  });

  group('C5 · lifecycle absent and lifecycle null are the same thing', () {
    test('the grocery payload has no lifecycle key at all', () {
      final m = groceryMessage(order: 'o1');
      expect(m.metadata?.lifecycle, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  C12 — de-duplication
  // ═══════════════════════════════════════════════════════════════════

  group('C12 · one card per order id, newest created_at wins', () {
    test('a replayed socket card collapses onto the newer one', () {
      final older = groceryMessage(
          id: 'm1', order: 'o1', createdAt: '2026-08-27T06:00:00.000Z');
      final newer = groceryMessage(
          id: 'm2', order: 'o1', createdAt: '2026-08-27T06:35:00.000Z');

      final out = OrderCardDedupe.apply([older, newer]);

      expect(out.length, 1);
      expect(out.single.id, 'm2');
    });

    test('the survivor keeps the newest occurrence\'s POSITION', () {
      final older = groceryMessage(
          id: 'm1', order: 'o1', createdAt: '2026-08-27T06:00:00.000Z');
      final text = Messages.fromJson({
        '_id': 'mt',
        'message': 'hi',
        'message_type': 'text',
        'created_at': '2026-08-27T06:10:00.000Z',
      });
      final newer = groceryMessage(
          id: 'm2', order: 'o1', createdAt: '2026-08-27T06:35:00.000Z');

      final out = OrderCardDedupe.apply([older, text, newer]);

      expect(out.map((m) => m.id).toList(), ['mt', 'm2'],
          reason: 'the card must not jump up the thread');
    });

    test('two different orders both survive', () {
      final a = groceryMessage(id: 'm1', order: 'o1');
      final b = groceryMessage(id: 'm2', order: 'o2');
      expect(OrderCardDedupe.apply([a, b]).length, 2);
    });

    test('two orphans are never merged — they may be different orders', () {
      final a = groceryMessage(id: 'm1', order: null);
      final b = groceryMessage(id: 'm2', order: null);
      expect(OrderCardDedupe.apply([a, b]).length, 2);
    });

    test('plain messages pass through untouched and in order', () {
      List<Messages> texts = List.generate(
          3,
          (i) => Messages.fromJson({
                '_id': 't$i',
                'message_type': 'text',
                'created_at': '2026-08-27T06:0$i:00.000Z',
              }));
      final out = OrderCardDedupe.apply(texts);
      expect(identical(out, texts), isTrue,
          reason: 'no duplicates → no allocation, no reordering');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  §6 — the steps payload
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> trackBody({
    List<Map<String, dynamic>>? stages,
    String? orderStatus = 'placed',
    String? currentStage,
    bool? isTerminal,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? rider,
    Map<String, dynamic>? riderLeg,
    Map<String, dynamic>? rideOrder,
    List<Map<String, dynamic>>? items,
    num? grandTotal,
  }) =>
      {
        'success': true,
        'data': {
          'orderId': 'o1',
          'orderNumber': 'GRO260827120009UXCQHL',
          'orderStatus': orderStatus,
          if (currentStage != null) 'currentStage': currentStage,
          if (isTerminal != null) 'isTerminal': isTerminal,
          'deliveryType': 'self-pickup',
          'grandTotal': grandTotal ?? 48,
          if (items != null) 'items': items,
          if (stages != null) 'stages': stages,
          if (payment != null) 'payment': payment,
          if (rider != null) 'rider': rider,
          if (riderLeg != null) 'riderLeg': riderLeg,
          if (rideOrder != null) 'rideOrder': rideOrder,
        },
      };

  OrderTrackModel track(Map<String, dynamic> body) =>
      OrderTrackModel.fromJson(body, fallbackOrderId: 'o1');

  final groceryStages = [
    {
      'key': 'placed',
      'label': 'Order placed',
      'done': true,
      'at': '2026-08-27T12:00:00.000Z'
    },
    {
      'key': 'ready_for_pickup',
      'label': 'Ready for pickup',
      'done': true,
      'at': '2026-08-27T12:01:00.000Z'
    },
    {'key': 'completed', 'label': 'Completed', 'done': false, 'at': null},
  ];

  group('S1 · stages: [] falls back to the chip, with no stepper', () {
    test('an empty array is empty, not an error', () {
      final t = track(trackBody(stages: []));
      expect(t.stages, isEmpty);
      expect(t.currentIndex, -1);
      expect(t.orderStatus, 'placed');
    });

    test('an absent stages key is the same as an empty one', () {
      expect(track(trackBody()).stages, isEmpty);
    });
  });

  group('S2 · an unknown stage key still renders, via its label', () {
    test('a fourth step nobody shipped an app for', () {
      final t = track(trackBody(stages: [
        ...groceryStages,
        {'key': 'quality_checked', 'label': 'Quality checked', 'done': false},
      ]));
      expect(t.stages.length, 4);
      expect(t.stages.last.label, 'Quality checked');
    });

    test('a stage with no label at all humanises its key', () {
      final t = track(trackBody(stages: [
        {'key': 'ready_for_pickup', 'done': false},
      ]));
      expect(t.stages.single.label, 'Ready for pickup');
    });

    test('camelCase keys humanise too', () {
      expect(OrderStage.humaniseStageKey('readyForPickup'), 'Ready for pickup');
      expect(OrderStage.humaniseStageKey(''), 'Step');
    });
  });

  group('S3 · done with no timestamp shows the tick and hides the time', () {
    test('at: null on a done stage parses as done', () {
      final t = track(trackBody(stages: [
        {'key': 'placed', 'label': 'Order placed', 'done': true, 'at': null},
      ]));
      expect(t.stages.single.done, isTrue);
      expect(t.stages.single.at, isNull);
    });
  });

  group('S4 · array order is layout order — never re-sorted', () {
    test('a later stage done before an earlier one keeps its position', () {
      final t = track(trackBody(stages: [
        {'key': 'placed', 'label': 'Order placed', 'done': false},
        {'key': 'ready_for_pickup', 'label': 'Ready', 'done': true},
      ]));
      expect(
          t.stages.map((s) => s.key).toList(), ['placed', 'ready_for_pickup']);
      expect(t.lastDoneIndex, 1);
    });
  });

  group('S5 · orderStatus and currentStage may disagree — the stage wins', () {
    test('the real capture: placed + ready_for_pickup', () {
      final t = track(trackBody(
        orderStatus: 'placed',
        currentStage: 'ready_for_pickup',
        stages: groceryStages,
      ));
      expect(t.orderStatus, 'placed', reason: 'the chip follows this');
      expect(t.currentIndex, 1, reason: 'the stepper follows currentStage');
    });

    test('with no currentStage it is the first stage not done', () {
      final t = track(trackBody(stages: groceryStages));
      expect(t.currentIndex, 2);
    });

    test('a currentStage naming a stage that is not in the array is ignored',
        () {
      final t =
          track(trackBody(currentStage: 'teleported', stages: groceryStages));
      expect(t.currentIndex, 2);
    });

    test('everything done → the last node is where it stands', () {
      final t = track(trackBody(stages: [
        {'key': 'placed', 'label': 'Placed', 'done': true},
        {'key': 'completed', 'label': 'Completed', 'done': true},
      ]));
      expect(t.currentIndex, 1);
    });
  });

  group('S6 · isTerminal is read fresh, never inferred and never cached', () {
    test('an explicit false beats a terminal-looking status', () {
      final t = track(trackBody(orderStatus: 'completed', isTerminal: false));
      expect(t.isTerminal, isFalse,
          reason: 'the order reopened; the server said so');
    });

    test('with no flag it falls back to the status', () {
      expect(track(trackBody(orderStatus: 'completed')).isTerminal, isTrue);
      expect(track(trackBody(orderStatus: 'placed')).isTerminal, isFalse);
    });
  });

  group('S7 · multi-shop sub-rows', () {
    test('per-business status parses and reads', () {
      final t = track(trackBody(stages: [
        {
          'key': 'ready_for_pickup',
          'label': 'Ready for pickup',
          'done': false,
          'businesses': [
            {'businessId': 'b1', 'name': 'Singh Store', 'status': 'ready'},
            {'businessId': 'b2', 'name': 'Verma Store', 'status': 'pending'},
          ],
        },
      ]));
      final businesses = t.stages.single.businesses;
      expect(businesses.length, 2);
      expect(businesses.first.isReady, isTrue);
      expect(businesses.last.isReady, isFalse);
      expect(t.isMultiShop, isTrue);
    });

    test('a single-shop order is not multi-shop', () {
      expect(track(trackBody(stages: groceryStages)).isMultiShop, isFalse);
    });
  });

  group('S9 · a cancelled order keeps its history', () {
    test('the last done stage is where the stepper stops', () {
      final t = track(trackBody(orderStatus: 'cancelled', stages: [
        {'key': 'placed', 'label': 'Order placed', 'done': true},
        {'key': 'ready_for_pickup', 'label': 'Ready', 'done': false},
        {'key': 'completed', 'label': 'Completed', 'done': false},
      ]));
      expect(t.isCancelled, isTrue);
      expect(t.lastDoneIndex, 0);
    });
  });

  group('S10 · no rider means no rider block', () {
    test('all three rider keys null → null', () {
      expect(track(trackBody()).rider, isNull);
    });

    test('an empty rider object is still not a rider', () {
      expect(track(trackBody(rider: {})).rider, isNull);
    });

    test('a rider with only a name is a rider', () {
      final t = track(trackBody(rider: {'name': 'Ramesh'}));
      expect(t.rider?.name, 'Ramesh');
      expect(t.rider?.hasLocation, isFalse);
    });

    test('GeoJSON coordinates are read lng-first', () {
      final t = track(trackBody(rider: {
        'name': 'Ramesh',
        'location': {
          'type': 'Point',
          'coordinates': [77.21, 28.61],
        },
      }));
      expect(t.rider?.longitude, 77.21);
      expect(t.rider?.latitude, 28.61);
    });

    test('riderLeg and rideOrder are accepted in rider\'s place', () {
      expect(track(trackBody(riderLeg: {'name': 'A'})).rider?.name, 'A');
      expect(track(trackBody(rideOrder: {'riderName': 'B'})).rider?.name, 'B');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  §6.4 — payment
  // ═══════════════════════════════════════════════════════════════════

  group('§6.4 · the payment row', () {
    test('P3 · an absent payment key hides the whole row', () {
      expect(track(trackBody()).payment, isNull);
    });

    test('P1 · grocery: not applicable, with a note to print verbatim', () {
      final t = track(trackBody(payment: {
        'customer': {
          'applicable': false,
          'note': 'Paid at the store counter on pickup.',
          'isPaid': false,
        },
      }));
      final side = t.payment!.customer!;
      expect(side.applicable, isFalse);
      expect(side.note, 'Paid at the store counter on pickup.');
      expect(side.isPaid, isFalse,
          reason: 'P7 — the flag is there; the UI must simply not show it');
    });

    test('P4 · submitted and under_review both mean "waiting"', () {
      for (final state in ['submitted', 'under_review']) {
        final t = track(trackBody(payment: {
          'customer': {'applicable': true, 'paymentState': state},
        }));
        expect(t.payment!.customer!.isSubmitted, isTrue, reason: state);
      }
    });

    test('P5 · rejected carries its reason', () {
      final t = track(trackBody(payment: {
        'customer': {
          'applicable': true,
          'paymentState': 'rejected',
          'rejectionReason': 'UTR not found',
        },
      }));
      expect(t.payment!.customer!.isRejected, isTrue);
      expect(t.payment!.customer!.rejectionReason, 'UTR not found');
    });

    test('P6 · refund_pending names the SHOP as the payer', () {
      final t = track(trackBody(payment: {
        'customer': {
          'applicable': true,
          'paymentState': 'refund_pending',
          'refundOwedBy': 'shop',
        },
      }));
      expect(t.payment!.customer!.isRefundPending, isTrue);
      expect(t.payment!.customer!.refundOwedBy, 'shop');
    });

    test('a flat payment block is read as the customer side', () {
      final t = track(trackBody(payment: {
        'applicable': false,
        'note': 'Paid at the counter.',
      }));
      expect(t.payment!.customer!.note, 'Paid at the counter.');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  §4 — actions
  // ═══════════════════════════════════════════════════════════════════

  group('C6 / B2 · empty action lists are valid and common', () {
    test('no lifecycle and no availableActions → no buttons', () {
      final t = track(trackBody(stages: groceryStages));
      expect(t.actionsFor(isOwner: true), isEmpty);
      expect(t.actionsFor(isOwner: false), isEmpty);
    });

    test('a caller-scoped availableActions is used as-is for either role', () {
      final t = OrderTrackModel.fromJson({
        'data': {
          'orderId': 'o1',
          'availableActions': ['MARK_READY'],
        }
      });
      expect(t.actionsFor(isOwner: true), ['MARK_READY']);
    });

    test('B3 · a role-split lifecycle is sliced by the viewer', () {
      final t = OrderTrackModel.fromJson({
        'data': {
          'orderId': 'o1',
          'lifecycle': {
            'orderStatus': 'placed',
            'customerActions': ['CANCEL_ORDER'],
            'ownerActions': ['ACCEPT_ORDER', 'REJECT_ORDER'],
          },
        }
      });
      expect(t.actionsFor(isOwner: false), ['CANCEL_ORDER']);
      expect(t.actionsFor(isOwner: true), ['ACCEPT_ORDER', 'REJECT_ORDER']);
    });

    test('actor decides the role when the server states it', () {
      final owner = OrderTrackModel.fromJson({
        'data': {'orderId': 'o1', 'actor': 'owner'}
      });
      final customer = OrderTrackModel.fromJson({
        'data': {'orderId': 'o1', 'actor': 'customer'}
      });
      final silent = OrderTrackModel.fromJson({
        'data': {'orderId': 'o1'}
      });
      expect(owner.actorIsOwner, isTrue);
      expect(customer.actorIsOwner, isFalse);
      expect(silent.actorIsOwner, isNull,
          reason: 'the caller keeps its own guess');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  §7 — the vertical gate
  // ═══════════════════════════════════════════════════════════════════

  group('§7 · what each vertical can actually do', () {
    setUp(OrderVerticalCapabilities.resetLearnedRoutes);

    test('lifecycle and /actions are product-service only', () {
      expect(
          OrderVerticalCapabilities.hasLifecycle(
              OrderServiceApi.productOrderService),
          isTrue);
      expect(
          OrderVerticalCapabilities.hasLifecycle(
              OrderServiceApi.groceryOrderService),
          isFalse);
      expect(
          OrderVerticalCapabilities.hasActions(
              OrderServiceApi.groceryOrderService),
          isFalse);
    });

    test('/track is product, grocery and food', () {
      for (final s in [
        OrderServiceApi.productOrderService,
        OrderServiceApi.groceryOrderService,
        OrderServiceApi.foodOrderService,
      ]) {
        expect(OrderVerticalCapabilities.hasTrack(s), isTrue, reason: s);
      }
      expect(
          OrderVerticalCapabilities.hasTrack(
              OrderServiceApi.medicalOrderService),
          isFalse);
    });

    test('grocery has no socket updates — refresh on focus instead', () {
      expect(
          OrderVerticalCapabilities.hasSocketUpdates(
              OrderServiceApi.groceryOrderService),
          isFalse);
    });

    test('grocery offers Mark Ready and Mark Collected, and nothing else', () {
      const grocery = OrderServiceApi.groceryOrderService;
      expect(
          OrderVerticalCapabilities.allowsAction(
              grocery, OrderAction.markReady),
          isTrue);
      expect(
          OrderVerticalCapabilities.allowsAction(
              grocery, kOrderActionMarkCollected),
          isTrue);
      for (final hidden in [
        OrderAction.acceptOrder,
        OrderAction.rejectOrder,
        OrderAction.setPrepEta,
        OrderAction.cancelOrder,
        OrderAction.confirmHandover,
        OrderAction.reportNoShow,
        OrderAction.viewPickupCode,
        OrderAction.submitPayment,
        OrderAction.verifyPayment,
      ]) {
        expect(OrderVerticalCapabilities.allowsAction(grocery, hidden), isFalse,
            reason: hidden);
      }
    });

    test('a ported vertical offers whatever the server listed', () {
      expect(
          OrderVerticalCapabilities.allowsAction(
              OrderServiceApi.productOrderService, OrderAction.confirmHandover),
          isTrue);
    });
  });

  group('B8 · a 404 HTML page hides that button for that vertical', () {
    setUp(OrderVerticalCapabilities.resetLearnedRoutes);

    test('an Express "Cannot POST" page is a missing ROUTE', () {
      expect(
          OrderVerticalCapabilities.isRouteMissingResponse(
              404, 'Cannot POST /chat/order-status'),
          isTrue);
      expect(
          OrderVerticalCapabilities.isRouteMissingResponse(
              404, '<!DOCTYPE html><html>…'),
          isTrue);
    });

    test('a typed 404 is about the ORDER, and must not blame the route', () {
      expect(
          OrderVerticalCapabilities.isRouteMissingResponse(
              404, {'code': 'ORDER_NOT_FOUND'}),
          isFalse);
    });

    test('a non-404 is never a missing route', () {
      expect(
          OrderVerticalCapabilities.isRouteMissingResponse(
              409, 'Cannot POST /x'),
          isFalse);
    });

    test('once learned, the action is hidden for that vertical only', () {
      const grocery = OrderServiceApi.groceryOrderService;
      OrderVerticalCapabilities.markRouteMissing(
          grocery, OrderAction.markReady);
      expect(
          OrderVerticalCapabilities.allowsAction(
              grocery, OrderAction.markReady),
          isFalse);
      expect(
          OrderVerticalCapabilities.allowsAction(
              OrderServiceApi.productOrderService, OrderAction.markReady),
          isTrue,
          reason: 'one vertical\'s missing route says nothing about another');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  §3.1 — the card body
  // ═══════════════════════════════════════════════════════════════════

  group('§3.1 · totals and items come from the payload, never computed', () {
    test('grandTotal is taken as sent, even when it disagrees with the lines',
        () {
      final t = track(trackBody(
        grandTotal: 48,
        items: [
          {
            'name': 'Act II Popcorn',
            'quantity': 2,
            'mrp': 26,
            'sellingPrice': 24
          },
          {'name': 'Salt', 'quantity': 1, 'sellingPrice': 20},
        ],
      ));
      expect(t.grandTotal, 48, reason: '2×24 + 20 = 68 — and we do not care');
    });

    test('C15 · the image falls back variant → product → nothing', () {
      final variantOnly = OrderTrackItem.fromJson({
        'quantity': 1,
        'productVariant': {
          'images': [
            {'url': 'https://cdn/variant.png'}
          ],
          'product': {
            'images': [
              {'url': 'https://cdn/product.png'}
            ]
          },
        },
      });
      expect(variantOnly.imageUrl, 'https://cdn/variant.png');

      final productFallback = OrderTrackItem.fromJson({
        'quantity': 1,
        'productVariant': {
          'images': <dynamic>[],
          'product': {
            'name': 'Act II Popcorn',
            'images': [
              {'url': 'https://cdn/product.png'}
            ]
          },
        },
      });
      expect(productFallback.imageUrl, 'https://cdn/product.png');
      expect(productFallback.name, 'Act II Popcorn');

      final none = OrderTrackItem.fromJson({'quantity': 1});
      expect(none.imageUrl, isNull,
          reason: 'the row draws a placeholder tile, never an empty box');
    });

    test('a struck-through MRP only when it is genuinely higher', () {
      expect(
          OrderTrackItem.fromJson(
              {'quantity': 1, 'mrp': 26, 'sellingPrice': 24}).isDiscounted,
          isTrue);
      expect(
          OrderTrackItem.fromJson(
              {'quantity': 1, 'mrp': 24, 'sellingPrice': 24}).isDiscounted,
          isFalse);
    });

    test('the line total multiplies the price actually charged', () {
      final item = OrderTrackItem.fromJson(
          {'quantity': 2, 'mrp': 26, 'sellingPrice': 24});
      expect(item.lineTotal, 48);
    });
  });

  group('envelopes · /track is served in four shapes', () {
    test('bare, {data}, {order} and {data:{order}} all parse', () {
      const number = 'GRO260827120009UXCQHL';
      final bare =
          OrderTrackModel.fromJson({'orderId': 'o1', 'orderNumber': number});
      final wrapped = OrderTrackModel.fromJson({
        'data': {'orderId': 'o1', 'orderNumber': number}
      });
      final nested = OrderTrackModel.fromJson({
        'order': {'_id': 'o1', 'orderNumber': number}
      });
      final both = OrderTrackModel.fromJson({
        'data': {
          'order': {'_id': 'o1', 'orderNumber': number}
        }
      });
      for (final t in [bare, wrapped, nested, both]) {
        expect(t.orderId, 'o1');
        expect(t.orderNumber, number);
      }
    });

    test('stages beside `order` rather than inside it are still found', () {
      final t = OrderTrackModel.fromJson({
        'data': {
          'order': {'_id': 'o1'},
          'stages': groceryStages,
        }
      });
      expect(t.stages.length, 3);
    });

    test('an unparseable body falls back to the id the caller knew', () {
      expect(OrderTrackModel.fromJson({}, fallbackOrderId: 'o1').orderId, 'o1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  §8 — the copy table
  // ═══════════════════════════════════════════════════════════════════

  group('§8 · the copy table ships, word for word', () {
    late Map<String, dynamic> en;

    setUpAll(() {
      en = jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;
    });

    test('every situation in the table has its exact sentence', () {
      const table = {
        AppStrings.orderWaitingShopConfirm: 'Waiting for the shop to confirm',
        AppStrings.orderReadyCollectIt: 'Ready! Collect it from the shop',
        AppStrings.orderWaitingCustomerCollect:
            'Waiting for the customer to collect',
        AppStrings.orderCompletedCopy: 'Order completed',
        AppStrings.orderCancelledCopy: 'Order cancelled',
        AppStrings.orderAlreadyClosed: 'This order is already closed.',
        AppStrings.orderNotAParty: "You can't act on this order.",
        AppStrings.orderNoLongerExists: 'This order no longer exists.',
        AppStrings.orderGenericError: 'Something went wrong. Please try again.',
        AppStrings.orderOfflineCopy: 'No connection. Pull to refresh.',
      };
      table.forEach((key, sentence) {
        expect(en[key], sentence, reason: key);
      });
    });

    test('the refund copy names the SHOP, never "we"', () {
      final copy =
          (en[AppStrings.orderRefundPendingFromShop] as String).toLowerCase();
      expect(copy, contains('shop'));
      expect(copy, isNot(contains('we ')));
      expect(copy, isNot(contains('we will')));
    });

    test('every order key this build renders exists in the bundle', () {
      const keys = [
        AppStrings.orderStatusPlaced,
        AppStrings.orderStatusAccepted,
        AppStrings.orderStatusInProgress,
        AppStrings.orderStatusReadyForPickup,
        AppStrings.orderStatusOnTheWay,
        AppStrings.orderStatusCompleted,
        AppStrings.orderStatusCancelled,
        AppStrings.orderStatusExpired,
        AppStrings.orderStepsTitle,
        AppStrings.orderStepsItemsHeading,
        AppStrings.orderStepsTotal,
        AppStrings.orderStepsMoreItems,
        AppStrings.orderStepsShopHeading,
        AppStrings.orderStepsCustomerHeading,
        AppStrings.orderStepsRiderHeading,
        AppStrings.orderStepsPaymentHeading,
        AppStrings.orderStepsPickupCode,
        AppStrings.orderStepsViewOrder,
        AppStrings.orderStepsRetry,
        AppStrings.orderStepsEmptyStages,
        AppStrings.orderMarkReady,
        AppStrings.orderMarkCollected,
        AppStrings.orderMarkCollectedTitle,
        AppStrings.orderMarkCollectedBody,
        AppStrings.orderMarkedReadyToast,
        AppStrings.orderMarkedCollectedToast,
        AppStrings.orderPaymentSubmittedWaiting,
        AppStrings.orderPaymentRejected,
        AppStrings.orderRefundPendingFromShop,
        AppStrings.orderRefundReceivedCopy,
        AppStrings.orderCardNewOrder,
        AppStrings.orderCardDeleted,
        AppStrings.orderCardCollectFromShop,
        AppStrings.orderCardDoorstep,
      ];
      for (final key in keys) {
        expect(en[key], isA<String>(), reason: key);
        expect((en[key] as String).trim(), isNotEmpty, reason: key);
      }
    });

    test('the collapse label carries its @count placeholder', () {
      expect(en[AppStrings.orderStepsMoreItems], contains('@count'));
    });

    test('no copy leaks an error code or an action key', () {
      for (final entry in en.entries) {
        if (!entry.key.startsWith('order')) continue;
        final value = entry.value.toString();
        expect(value, isNot(contains('ACTION_NOT_AVAILABLE')),
            reason: entry.key);
        expect(value, isNot(contains('MARK_REFUND_SENT')), reason: entry.key);
        expect(value, isNot(contains('Invalid order ID')), reason: entry.key);
      }
    });
  });
}
