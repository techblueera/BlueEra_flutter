import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/active_orders_controller.dart';
import 'package:BlueEra/features/chat/auth/model/active_order_summary.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:BlueEra/features/chat/view/order_track/order_steps_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/ongoing_style_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **"Your order is waiting on you"** — on Discover, with its clock.
///
/// ## Why this is on Discover and not only in the chat
///
/// Every deadline in this app was already server-authored and already drawn
/// correctly. The gap was that it was only ever drawn **inside the chat thread
/// carrying the order's card**. A customer who placed an order and closed that
/// conversation had no way to learn it was ready — and for grocery, whose
/// self-pickup orders expire an hour after they are placed, **978 of 1,099
/// production orders expired** (guide §12). The countdown was never the
/// problem; nobody was on the screen it lived on.
///
/// Discover is where a customer already is. So the clock goes here.
///
/// ## What it may and may not do
///
/// It shows **state and a countdown, and nothing else**. No Accept, no Pay, no
/// Hand over. The rule in §0 is that `GET /actions` decides which buttons
/// exist, and the list endpoint behind this rail returns no `availableActions`
/// at all — so any button here would be the app deciding legality for itself,
/// which is the one thing the whole design forbids. Every tap opens the order
/// screen, which asks `/actions` and knows.
///
/// Two consequences that look like omissions and are not:
///
///  * **A countdown reaching zero changes nothing here.** It re-reads and lets
///    the server decide, exactly as §8.1 rule 1 requires. The rail never
///    removes an order because its clock ran out.
///  * **A cancelled order can still appear** — when money is still owed on it.
///    §7: the order is dead, the refund conversation is not.
///
/// Collapses to [SizedBox.shrink] when nothing is in flight, which is the
/// common case for most people on most days.
class PendingOrderChip extends StatefulWidget {
  const PendingOrderChip({super.key, this.maxRows = 2, this.padding});

  /// Outer spacing. Null keeps the inset this chip has always drawn itself
  /// with, so v1 is unaffected; Discover v2 passes [EdgeInsets.zero] and
  /// spaces it from outside, on the same rule as every other section.
  final EdgeInsets? padding;

  /// Orders shown before the rail stops. It sits above the entire Discover
  /// feed; a customer with nine live orders must not have to scroll past all
  /// nine to reach the app.
  final int maxRows;

  @override
  State<PendingOrderChip> createState() => _PendingOrderChipState();
}

class _PendingOrderChipState extends State<PendingOrderChip>
    with WidgetsBindingObserver {
  ActiveOrdersController get _controller => ActiveOrdersController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.refreshOrders();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Focus-refresh is the fallback the guide keeps for every vertical (§13),
    // and the only cue grocery had before its four socket events were wired.
    if (state == AppLifecycleState.resumed) _controller.refreshOrders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final all = _controller.orders;
      if (all.isEmpty) return const SizedBox.shrink();
      final shown = all.take(widget.maxRows).toList();

      return Padding(
        padding: widget.padding ?? const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final order in shown) ...[
              _OrderRow(
                order: order,
                onElapsed: () => _controller.refreshOrders(),
              ),
              if (order != shown.last) const SizedBox(height: 8),
            ],
          ],
        ),
      );
    });
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onElapsed});

  final ActiveOrderSummary order;
  final VoidCallback onElapsed;

  @override
  Widget build(BuildContext context) {
    final copy = PendingOrderCopy.of(order);

    return OngoingStyleCard(
      accent: copy.urgent
          ? OngoingStyleCard.liveAccent
          : OngoingStyleCard.orderAccent,
      gradient: copy.urgent
          ? OngoingStyleCard.liveGradient
          : OngoingStyleCard.orderGradient,
      onTap: () => Get.toNamed(
        RouteHelper.getOrderStepsScreenRoute(),
        arguments: OrderStepsArgs(
          orderId: order.orderId,
          service: order.service,
          // The rail is the customer's own; `/track`'s `actor` corrects it the
          // moment it lands, so this is only the first frame's guess (§18.6).
          isOwner: false,
        ),
      ),
      child: Row(
        children: [
          Icon(copy.icon,
              size: 20,
              color: copy.urgent
                  ? OngoingStyleCard.liveAccent
                  : OngoingStyleCard.orderAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
                if (copy.subtitle != null)
                  Text(
                    copy.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.grayText,
                    ),
                  ),
                // A null deadline draws nothing at all — no dash, no empty row
                // (§8.1 rule 2).
                if (order.deadline != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OrderDeadlineCountdown(
                      deadline: order.deadline,
                      label: copy.deadlineLabel,
                      // Re-read; never conclude. The sweeper owns expiry.
                      onElapsed: onElapsed,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.grayText),
        ],
      ),
    );
  }
}

/// The sentence each state gets on the rail.
///
/// Presentation only — this chooses **wording for a state the server already
/// decided**, which is what §8.1's own copy table does. It never decides
/// whether an action is allowed; nothing here renders an action.
///
/// Split out from the widget so the copy rules are testable without pumping a
/// Discover screen, and so the ordering of the cases — which is the whole
/// design — is readable in one place.
class PendingOrderCopy {
  final String title;
  final String? subtitle;
  final String deadlineLabel;
  final IconData icon;

  /// Whether this order is waiting on **the customer** rather than the shop.
  /// Only these are allowed to be loud; an order the shop is still preparing
  /// is not the customer's problem to solve.
  final bool urgent;

  const PendingOrderCopy({
    required this.title,
    this.subtitle,
    this.deadlineLabel = '',
    required this.icon,
    this.urgent = false,
  });

  static PendingOrderCopy of(ActiveOrderSummary o) {
    final at = o.shopName == null ? '' : ' · ${o.shopName}';
    final l = o.lifecycle;

    // ① Money still owed on a dead order. First, because it is the only state
    //    that survives the order itself and the easiest one to lose (§7).
    if (o.hasOpenRefund) {
      return PendingOrderCopy(
        title: 'Refund pending$at',
        subtitle: l.refundInitiatedAt != null
            ? 'The shop says it sent your refund — confirm when it arrives'
            : 'The shop needs to return your money',
        icon: Icons.currency_rupee,
      );
    }

    // ② The shop could not confirm the payment. The customer can pay again and
    //    is the only one who can (§5).
    if (l.paymentState == PaymentStateValue.rejected) {
      return PendingOrderCopy(
        title: "Payment wasn't confirmed$at",
        subtitle: 'Tap to try paying again',
        deadlineLabel: 'Pay within',
        icon: Icons.error_outline,
        urgent: true,
      );
    }

    // ③ Waiting for the customer's money. Never shown on a cash order: the
    //    server never puts a UPI payment state on one.
    if (l.paymentMethod == 'upi' &&
        (l.paymentState == PaymentStateValue.pending ||
            l.paymentState == PaymentStateValue.expired) &&
        !o.isTerminal) {
      return PendingOrderCopy(
        title: 'Pay to confirm your order$at',
        subtitle: 'The shop is holding it for you',
        deadlineLabel: 'Pay within',
        icon: Icons.qr_code_2,
        urgent: true,
      );
    }

    // ④ **The headline case.** Ready, self-pickup: the customer is the only
    //    person who can move this forward, and if they do not, it expires.
    if (l.orderStatus == OrderStatusValue.ready && o.isSelfPickup) {
      return PendingOrderCopy(
        title: 'Ready — go and collect it$at',
        subtitle: 'Show your pickup code at the counter',
        deadlineLabel: 'Collect by',
        icon: Icons.shopping_bag_outlined,
        urgent: true,
      );
    }

    // ⑤ A screenshot is not a payment. This says "waiting", never "paid" (§5).
    if (l.paymentState == PaymentStateValue.submitted ||
        l.paymentState == PaymentStateValue.underReview) {
      return PendingOrderCopy(
        title: 'Waiting for the shop to confirm your payment$at',
        icon: Icons.hourglass_bottom,
      );
    }

    // ⑥ Doorstep, packed, no rider yet — still searching, not failed (§6 C0).
    if (l.orderStatus == OrderStatusValue.ready && !o.isSelfPickup) {
      return PendingOrderCopy(
        title: o.riderAssigned
            ? 'A delivery partner is collecting your order$at'
            : 'Finding a delivery partner$at',
        icon: Icons.delivery_dining,
      );
    }

    switch (l.orderStatus) {
      case OrderStatusValue.placed:
        return PendingOrderCopy(
          title: 'Waiting for the shop to accept$at',
          deadlineLabel: 'Shop confirms within',
          icon: Icons.storefront,
        );
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        return PendingOrderCopy(
          title: 'Your order is being prepared$at',
          deadlineLabel: 'Ready by',
          icon: Icons.inventory_2_outlined,
        );
      case OrderStatusValue.dispatched:
        return PendingOrderCopy(
          title: 'On the way to you$at',
          deadlineLabel: 'Arrives by',
          icon: Icons.local_shipping_outlined,
        );
      default:
        // A status this build has never heard of still deserves a way back to
        // the order — but it is described in the neutral terms of what we do
        // know, never by echoing a raw status code at a customer.
        return PendingOrderCopy(
          title: o.orderNumber == null
              ? 'Your order$at'
              : 'Order ${o.orderNumber}$at',
          icon: Icons.receipt_long_outlined,
        );
    }
  }
}

/// Kept beside the chip so a reader looking for "which service does the rail
/// ask" finds it next to the thing that asks.
const List<String> kPendingOrderServices = [
  OrderServiceApi.productOrderService,
  OrderServiceApi.groceryOrderService,
];
