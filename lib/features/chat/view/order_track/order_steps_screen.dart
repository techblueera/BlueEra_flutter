import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_track_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_track_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_vertical_capabilities.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:BlueEra/features/chat/view/order_track/widgets/order_status_chip.dart';
import 'package:BlueEra/features/chat/view/order_track/widgets/order_stepper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Arguments for [OrderStepsScreen], passed through the named route.
class OrderStepsArgs {
  final String orderId;

  /// `grocery-service`, `product-service`, … — which vertical owns the order.
  final String service;

  /// The caller's guess at the viewer's role. `/track`'s `actor` overrides it
  /// the moment it lands (B3).
  final bool isOwner;

  const OrderStepsArgs({
    required this.orderId,
    this.service = OrderServiceApi.defaultOrderService,
    this.isOwner = false,
  });
}

/// **The order detail screen, fed by `/track`.**
///
/// For grocery this is the entire usable order UI: there is no order thread,
/// no chat card and no socket, so §7 of
/// `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` puts everything here — the
/// three-step stepper, the seller's Mark Ready, and Mark Collected behind a
/// confirm. Ported verticals get the same screen with whatever richer action
/// list their `/track` carries.
///
/// The screen refreshes on focus and on pull, and on nothing else: grocery has
/// no socket event, so a card left open would otherwise go stale in silence
/// (T7, S13).
class OrderStepsScreen extends StatefulWidget {
  final OrderStepsArgs args;

  const OrderStepsScreen({super.key, required this.args});

  @override
  State<OrderStepsScreen> createState() => _OrderStepsScreenState();
}

class _OrderStepsScreenState extends State<OrderStepsScreen>
    with WidgetsBindingObserver {
  late final OrderTrackController _controller;

  bool _poppedForGone = false;

  /// The `isGone` listener. Held so it can be disposed: the controller is
  /// ref-counted and may outlive this screen (the chat card holds it too), and
  /// a surviving worker would call `Get.back()` on whatever screen happened to
  /// be open when the order was later found to be missing.
  Worker? _goneWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Shared with the chat card for the same order, so both show one truth
    // and one fetch (C13).
    _controller = OrderTrackController.attach(
      orderId: widget.args.orderId,
      service: widget.args.service,
      isOwner: widget.args.isOwner,
    );
    // The card may have fetched a while ago; the screen always re-reads.
    _controller.silentRefresh();

    // S14 — the order was deleted while the screen was open. Say so once, then
    // leave; there is nothing left to render.
    _goneWorker = ever<bool>(_controller.isGone, (gone) {
      if (!gone || _poppedForGone || !mounted) return;
      _poppedForGone = true;
      commonSnackBar(message: AppStrings.orderNoLongerExists.tr);
      Get.back(result: OrderStepsResult.gone);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // D5 / T8 — recompute from the server on resume, never from a paused tick
    // or a card that has been sitting behind the home screen.
    if (state == AppLifecycleState.resumed) {
      _controller.silentRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goneWorker?.dispose();
    OrderTrackController.detach(
        orderId: widget.args.orderId, service: widget.args.service);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.mainTextColor),
        title: Obx(() {
          final number = _controller.track.value?.orderNumber;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.orderStepsTitle.tr,
                  style: OrderType.title
                      .copyWith(color: AppColors.mainTextColor, fontSize: 16)),
              if ((number ?? '').isNotEmpty)
                Text(number!,
                    style: OrderType.mono(size: 11)
                        .copyWith(color: AppColors.grayText)),
            ],
          );
        }),
      ),
      body: Obx(_body),
      bottomNavigationBar: Obx(_controlBar),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────

  Widget _body() {
    final order = _controller.track.value;

    if (_controller.isLoading.value && order == null) {
      return const Padding(
        padding: EdgeInsets.all(OrderSpace.l),
        child: OrderCardSkeleton(lines: 8),
      );
    }

    if (order == null) {
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            _emptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            OrderSpace.l, OrderSpace.l, OrderSpace.l, OrderSpace.xl),
        children: [
          if (_controller.isOffline.value) _offlineStrip(),
          _headerCard(order),
          const SizedBox(height: OrderSpace.m),
          _stepsCard(order),
          ..._riderCard(order),
          const SizedBox(height: OrderSpace.m),
          _itemsCard(order),
          ..._paymentCard(order),
          ..._partiesCard(order),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final failure = _controller.failure.value;
    final copy = switch (failure) {
      OrderTrackFailure.gone => AppStrings.orderNoLongerExists.tr,
      OrderTrackFailure.forbidden => AppStrings.orderNotAParty.tr,
      OrderTrackFailure.offline => AppStrings.orderOfflineCopy.tr,
      _ => AppStrings.orderGenericError.tr,
    };
    return Column(
      children: [
        Icon(
          failure == OrderTrackFailure.offline
              ? Icons.wifi_off_rounded
              : Icons.receipt_long_outlined,
          size: 40,
          color: AppColors.grayText,
        ),
        const SizedBox(height: OrderSpace.m),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: OrderSpace.xl),
          child: Text(copy,
              textAlign: TextAlign.center,
              style: OrderType.body.copyWith(color: AppColors.grayText)),
        ),
        const SizedBox(height: OrderSpace.m),
        TextButton(
          onPressed: _controller.refresh,
          child: Text(AppStrings.orderStepsRetry.tr),
        ),
      ],
    );
  }

  Widget _offlineStrip() => Container(
        margin: const EdgeInsets.only(bottom: OrderSpace.m),
        padding: const EdgeInsets.symmetric(
            horizontal: OrderSpace.m, vertical: OrderSpace.s),
        decoration: BoxDecoration(
          color: OrderTone.warning.surface,
          borderRadius: BorderRadius.circular(OrderRadius.inner),
          border: Border.all(color: OrderTone.warning.border),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 15, color: OrderTone.warning.color),
            const SizedBox(width: OrderSpace.s),
            Expanded(
              child: Text(AppStrings.orderOfflineCopy.tr,
                  style:
                      OrderType.label.copyWith(color: OrderTone.warning.color)),
            ),
          ],
        ),
      );

  // ── Cards ────────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(OrderSpace.l),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(OrderRadius.card),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: child,
      );

  Widget _headerCard(OrderTrackModel order) {
    final placed = order.createdAt;
    final stageKey = order.currentIndex >= 0 && order.stages.isNotEmpty
        ? order.stages[order.currentIndex].key
        : order.currentStage;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber ?? AppStrings.orderCardNewOrder.tr,
                      style: OrderType.mono(size: 14, weight: FontWeight.w700)
                          .copyWith(color: AppColors.mainTextColor),
                    ),
                    if (placed != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          DateFormat('d MMM yyyy, h:mm a').format(placed),
                          style: OrderType.label
                              .copyWith(color: AppColors.grayText),
                        ),
                      ),
                  ],
                ),
              ),
              // The chip is driven by `orderStatus`; the stepper below is
              // driven by `currentStage`. They are allowed to disagree (S5).
              OrderStatusChip(
                  orderStatus: order.orderStatus, stageKey: stageKey),
            ],
          ),
          const SizedBox(height: OrderSpace.m),
          Row(
            children: [
              Icon(
                order.isSelfPickup ? Icons.storefront : Icons.delivery_dining,
                size: 15,
                color: AppColors.grayText,
              ),
              const SizedBox(width: OrderSpace.xs),
              Text(
                order.isSelfPickup
                    ? AppStrings.orderCardCollectFromShop.tr
                    : AppStrings.orderCardDoorstep.tr,
                style: OrderType.label.copyWith(color: AppColors.grayText),
              ),
            ],
          ),
          // §4.3 — the countdown, and ONLY when the server sent a deadline.
          // Null means "no clock running for this step", which is not the same
          // as expired; grocery sends no deadlines at all, so this renders
          // nothing for it (D1).
          ..._deadline(order),
          // The one sentence the screen says on its own, and only when the
          // server did not send a banner of its own to say it better.
          if (_situationCopy(order) != null) ...[
            const SizedBox(height: OrderSpace.s),
            Text(
              _situationCopy(order)!,
              style: OrderType.body.copyWith(
                  color: AppColors.mainTextColor, fontWeight: FontWeight.w600),
            ),
          ],
          if ((order.pickupCode ?? '').isNotEmpty) ...[
            const SizedBox(height: OrderSpace.m),
            const OrderZoneDivider(),
            const SizedBox(height: OrderSpace.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.orderStepsPickupCode.tr,
                    style: OrderType.label.copyWith(color: AppColors.grayText)),
                Text(
                  order.pickupCode!,
                  style: OrderType.mono(size: 20, weight: FontWeight.w800)
                      .copyWith(
                          color: AppColors.mainTextColor, letterSpacing: 3),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The one deadline that matters at the stage the order is standing on.
  ///
  /// Never `createdAt + a constant`: every clock in this app is server-authored
  /// (§4.3). When it runs out the screen does **not** decide the order expired
  /// — it re-reads `/track` once and lets the server say so (D3). The widget
  /// anchors to the absolute deadline and ticks off one app-wide clock, so a
  /// wrong device clock stays sane (D4), a resume recomputes rather than
  /// resuming a paused tick (D5), and closing the screen leaks no timer (D6).
  List<Widget> _deadline(OrderTrackModel order) {
    final deadlines = order.lifecycle?.deadlines;
    if (deadlines == null) return _derivedDeadline(order);

    final isOwner = _controller.isOwner;
    DateTime? at;
    String label = '';
    bool pulse = false;
    switch (order.orderStatus) {
      case OrderStatusValue.placed:
        at = deadlines.acceptBy;
        label = isOwner ? 'Confirm within' : 'Shop confirms within';
        // The shop is the one being waited on; the customer is not.
        pulse = isOwner;
        break;
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        at = deadlines.readyBy ?? deadlines.payBy;
        label = 'Ready by';
        break;
      case OrderStatusValue.ready:
        at = deadlines.pickupBy;
        label = 'Collect by';
        break;
      case OrderStatusValue.dispatched:
        at = deadlines.deliverBy;
        label = 'Arrives by';
        break;
      default:
        return const [];
    }
    if (at == null) return const [];

    return [
      const SizedBox(height: OrderSpace.m),
      OrderDeadlineCountdown(
        deadline: at,
        label: label,
        pulse: pulse,
        // Exactly once, and it re-reads rather than concluding anything.
        onElapsed: _controller.silentRefresh,
      ),
    ];
  }

  /// The fallback for a vertical that sends no `deadlines` at all.
  ///
  /// Reached **only** when the server sent nothing, so a ported vertical's own
  /// clock can never be shadowed by this one. The rule itself — which vertical,
  /// which stage, how long — lives in [OrderVerticalCapabilities], because it
  /// is a fact about that service rather than about this screen.
  List<Widget> _derivedDeadline(OrderTrackModel order) {
    final at = OrderVerticalCapabilities.derivedPlacedExpiry(
      service: widget.args.service,
      orderStatus: order.orderStatus,
      createdAt: order.createdAt,
    );
    if (at == null) return const [];

    final isOwner = _controller.isOwner;
    return [
      const SizedBox(height: OrderSpace.m),
      OrderDeadlineCountdown(
        deadline: at,
        label: isOwner ? 'Confirm within' : 'Shop confirms within',
        // Past the hour the countdown reads "Nm over", amber — the sweep has
        // not necessarily run yet, so it must not read as a verdict.
        pulse: isOwner,
        onElapsed: _controller.silentRefresh,
      ),
    ];
  }

  /// The §8 copy table, and only when the server sent no banner of its own.
  String? _situationCopy(OrderTrackModel order) {
    final banner = order.lifecycle?.banner?.trim();
    if (banner != null && banner.isNotEmpty) return banner;

    if (order.isCancelled) return AppStrings.orderCancelledCopy.tr;
    if (order.isCompleted) return AppStrings.orderCompletedCopy.tr;

    final isOwner = _controller.isOwner;
    final stageKey = order.currentIndex >= 0 && order.stages.isNotEmpty
        ? order.stages[order.currentIndex].key.toLowerCase()
        : (order.currentStage ?? '').toLowerCase();

    final ready = order.orderStatus == OrderStatusValue.ready ||
        stageKey.contains('ready') ||
        stageKey.contains('pickup');
    if (ready) {
      return isOwner
          ? AppStrings.orderWaitingCustomerCollect.tr
          : AppStrings.orderReadyCollectIt.tr;
    }
    if (order.orderStatus == OrderStatusValue.placed) {
      return isOwner ? null : AppStrings.orderWaitingShopConfirm.tr;
    }
    return null;
  }

  Widget _stepsCard(OrderTrackModel order) =>
      _card(child: OrderStepper(order: order));

  /// S10 — no rider block at all when there is no rider. No empty map, no
  /// "waiting for rider".
  List<Widget> _riderCard(OrderTrackModel order) {
    final rider = order.rider;
    if (rider == null) return const [];
    return [
      const SizedBox(height: OrderSpace.m),
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.orderStepsRiderHeading.tr,
                style: OrderType.label.copyWith(color: AppColors.grayText)),
            const SizedBox(height: OrderSpace.s),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.greyE5,
                  backgroundImage: (rider.photo ?? '').isNotEmpty
                      ? CachedNetworkImageProvider(rider.photo!)
                      : null,
                  child: (rider.photo ?? '').isEmpty
                      ? const Icon(Icons.person,
                          size: 18, color: AppColors.grayText)
                      : null,
                ),
                const SizedBox(width: OrderSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rider.name ?? AppStrings.orderStepsRiderHeading.tr,
                          style: OrderType.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor)),
                      if ((rider.vehicleNumber ?? '').isNotEmpty)
                        Text(rider.vehicleNumber!,
                            style: OrderType.label
                                .copyWith(color: AppColors.grayText)),
                      // The leg's own copy (guide §18.5). `cancelled` and
                      // `rejected` read differently on purpose: "no rider
                      // accepted this order" is not "your order was
                      // cancelled". A leg this build does not know draws
                      // nothing rather than echoing a raw code.
                      if (RiderLegStatus.customerCopy(rider.status) != null)
                        Text(RiderLegStatus.customerCopy(rider.status)!,
                            style: OrderType.label
                                .copyWith(color: AppColors.grayText)),
                    ],
                  ),
                ),
                if ((rider.phone ?? '').isNotEmpty)
                  IconButton(
                    onPressed: () => _dial(rider.phone!),
                    icon: const Icon(Icons.call,
                        size: 20, color: AppColors.primaryColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _itemsCard(OrderTrackModel order) {
    final items = order.items;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.orderStepsItemsHeading.tr,
              style: OrderType.label.copyWith(color: AppColors.grayText)),
          const SizedBox(height: OrderSpace.s),
          if (items.isEmpty)
            Text('—', style: OrderType.body.copyWith(color: AppColors.grayText))
          else
            ...items.map(_itemRow),
          const SizedBox(height: OrderSpace.s),
          const OrderZoneDivider(),
          // Never a total this screen computed — `grandTotal`, as sent.
          OrderMoneyRow(
            label: AppStrings.orderStepsTotal.tr,
            amount: order.grandTotal,
            emphasise: true,
          ),
        ],
      ),
    );
  }

  Widget _itemRow(OrderTrackItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OrderSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _itemThumb(item),
          const SizedBox(width: OrderSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [item.name, item.variantLabel]
                      .where((e) => (e ?? '').isNotEmpty)
                      .join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      OrderType.body.copyWith(color: AppColors.mainTextColor),
                ),
                if (item.sellingPrice != null)
                  Row(
                    children: [
                      if (item.isDiscounted)
                        Padding(
                          padding: const EdgeInsets.only(right: OrderSpace.xs),
                          child: Text(
                            '₹${OrderMoneyRow.money(item.mrp!)}',
                            style: OrderType.label.copyWith(
                              color: AppColors.grayText,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      Text('₹${OrderMoneyRow.money(item.sellingPrice!)}',
                          style: OrderType.label
                              .copyWith(color: AppColors.mainTextColor)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: OrderSpace.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('× ${OrderMoneyRow.money(item.quantity)}',
                  style: OrderType.mono(size: 13)
                      .copyWith(color: AppColors.grayText)),
              if (item.lineTotal != null)
                Text('₹${OrderMoneyRow.money(item.lineTotal!)}',
                    style: OrderType.mono(size: 13, weight: FontWeight.w700)
                        .copyWith(color: AppColors.mainTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  /// C15 — variant image, then product image, then a placeholder **tile**.
  /// Never an empty box.
  Widget _itemThumb(OrderTrackItem item) {
    const size = 40.0;
    final url = item.imageUrl ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(OrderRadius.inner),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? Container(
                color: AppColors.greyE5,
                child: const Icon(Icons.shopping_basket_outlined,
                    size: 18, color: AppColors.grayText),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.greyE5),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.greyE5,
                  child: const Icon(Icons.shopping_basket_outlined,
                      size: 18, color: AppColors.grayText),
                ),
              ),
      ),
    );
  }

  /// §6.4. **P3 — an absent `payment` key hides the whole row.**
  List<Widget> _paymentCard(OrderTrackModel order) {
    final side = _controller.isOwner
        ? (order.payment?.owner ?? order.payment?.customer)
        : order.payment?.customer;
    if (side == null) return const [];

    final rows = <Widget>[];

    // P1 — not applicable: print the server's note verbatim and offer no pay
    // button. This is every grocery self-pickup order.
    final note = (side.note ?? '').trim();
    if (note.isNotEmpty) {
      rows.add(Text(note,
          style: OrderType.body.copyWith(color: AppColors.mainTextColor)));
    }

    // P2 — applicable: the amount, and the action comes from the control bar,
    // never from a button invented here.
    if (side.applicable && side.amount != null) {
      rows.add(OrderMoneyRow(label: 'Amount due', amount: side.amount));
    }

    // P4 / P5 / P6 — the payment state, in the shop's words about the shop's
    // money. Never "we will refund you".
    String? stateCopy;
    OrderTone stateTone = OrderTone.neutral;
    if (side.isSubmitted) {
      stateCopy = AppStrings.orderPaymentSubmittedWaiting.tr;
    } else if (side.isRejected) {
      stateCopy = [
        AppStrings.orderPaymentRejected.tr,
        if ((side.rejectionReason ?? '').isNotEmpty) side.rejectionReason!,
      ].join(' — ');
      stateTone = OrderTone.danger;
    } else if (side.isRefundPending) {
      stateCopy = AppStrings.orderRefundPendingFromShop.tr;
      stateTone = OrderTone.warning;
    } else if (side.isRefunded) {
      stateCopy = AppStrings.orderRefundReceivedCopy.tr;
      stateTone = OrderTone.success;
    }
    if (stateCopy != null) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: OrderSpace.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stateTone.icon, size: 15, color: stateTone.color),
            const SizedBox(width: OrderSpace.xs),
            Expanded(
              child: Text(stateCopy,
                  style: OrderType.label.copyWith(color: stateTone.color)),
            ),
          ],
        ),
      ));
    }

    // P7 — `isPaid: false` on a completed self-pickup order is not "Unpaid".
    // The cash was taken at the counter; the flag simply never gets written.
    // So it is never rendered for a self-pickup order, at all.

    if (rows.isEmpty) return const [];

    return [
      const SizedBox(height: OrderSpace.m),
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.orderStepsPaymentHeading.tr,
                style: OrderType.label.copyWith(color: AppColors.grayText)),
            const SizedBox(height: OrderSpace.s),
            ...rows,
          ],
        ),
      ),
    ];
  }

  List<Widget> _partiesCard(OrderTrackModel order) {
    // The viewer is shown the OTHER party, never themselves.
    final isOwner = _controller.isOwner;
    final heading = isOwner
        ? AppStrings.orderStepsCustomerHeading.tr
        : AppStrings.orderStepsShopHeading.tr;
    final name = isOwner ? order.customerName : order.businessName;
    final phone = isOwner ? order.customerPhone : order.businessPhone;
    final address = isOwner ? null : order.businessAddress;

    if ((name ?? '').isEmpty && (phone ?? '').isEmpty) return const [];

    return [
      const SizedBox(height: OrderSpace.m),
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading,
                style: OrderType.label.copyWith(color: AppColors.grayText)),
            const SizedBox(height: OrderSpace.s),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((name ?? '').isNotEmpty)
                        Text(name!,
                            style: OrderType.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainTextColor)),
                      if ((address ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(address!,
                              style: OrderType.label
                                  .copyWith(color: AppColors.grayText)),
                        ),
                    ],
                  ),
                ),
                if ((phone ?? '').isNotEmpty)
                  IconButton(
                    onPressed: () => _dial(phone!),
                    icon: const Icon(Icons.call,
                        size: 20, color: AppColors.primaryColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ── Controls ─────────────────────────────────────────────────────────

  /// B2 — both lists empty means **no button row at all**, not an empty bar
  /// reserving space. B10 — offline disables rather than optimistically
  /// advancing.
  Widget _controlBar() {
    final order = _controller.track.value;
    if (order == null) return const SizedBox.shrink();

    final offline = _controller.isOffline.value;

    // A vertical the lifecycle rollout has reached drives its own buttons
    // through the app's single action renderer — one switch, one source of
    // truth, and a key this build does not know renders nothing (B1). There
    // is no second copy of the accept / reject / handover / refund UI here.
    final Widget? bar =
        OrderVerticalCapabilities.hasLifecycle(widget.args.service) &&
                order.lifecycle != null
            ? _lifecycleBar(order)
            : _legacyBar(offline);
    if (bar == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: AnimatedOpacity(
        duration: OrderMotion.actionShift,
        opacity: offline ? 0.5 : 1,
        child: IgnorePointer(
          // B10 — offline disables the row. It never optimistically advances
          // the order.
          ignoring: offline,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                OrderSpace.l, OrderSpace.m, OrderSpace.l, OrderSpace.m),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.greyE5)),
            ),
            child: bar,
          ),
        ),
      ),
    );
  }

  /// The ported verticals. Null when the server offered nothing — B2: no row
  /// at all, not an empty bar reserving space.
  Widget? _lifecycleBar(OrderTrackModel order) {
    final actions = order.actionsFor(isOwner: _controller.isOwner);
    if (actions.isEmpty) return null;
    return OrderActionBar(
      actions: actions,
      ctx: OrderCardContext(
        orderId: widget.args.orderId,
        service: widget.args.service,
        isOwner: _controller.isOwner,
        otherUserId: _controller.isOwner ? order.customerId : order.businessId,
        otherUserName:
            _controller.isOwner ? order.customerName : order.businessName,
        otherUserPhone:
            _controller.isOwner ? order.customerPhone : order.businessPhone,
        shopName: order.businessName,
        shopAddress: order.businessAddress,
        orderTotal: order.grandTotal,
        businessId: order.businessId,
        // Re-read rather than advance locally (B11).
        onChanged: (_) => _controller.silentRefresh(),
      ),
    );
  }

  /// The legacy verticals — grocery today. Two controls, both verified to
  /// exist, and nothing else is offered at all (§7).
  Widget? _legacyBar(bool offline) {
    final controls = _controller.availableControls
        .where(_isRenderable)
        .toList(growable: false);
    if (controls.isEmpty) return null;
    return Row(
      children: [
        for (final key in controls) ...[
          Expanded(child: _controlButton(key, disabled: offline)),
          if (key != controls.last) const SizedBox(width: OrderSpace.m),
        ],
      ],
    );
  }

  /// B1 — an action key this build does not know renders **nothing**. Never a
  /// button labelled `MARK_REFUND_SENT`.
  bool _isRenderable(String key) =>
      key == OrderAction.markReady || key == kOrderActionMarkCollected;

  Widget _controlButton(String key, {required bool disabled}) {
    final busy = _controller.isBusy(key);
    final label = key == OrderAction.markReady
        ? AppStrings.orderMarkReady.tr
        : AppStrings.orderMarkCollected.tr;

    return ElevatedButton(
      // B9 — a tapped button is dead until its response lands.
      onPressed: (busy || disabled) ? null : () => _onControl(key),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        disabledBackgroundColor: AppColors.greyE5,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OrderRadius.inner)),
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.white),
            )
          : Text(label,
              style: OrderType.body.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.white)),
    );
  }

  Future<void> _onControl(String key) async {
    if (key == kOrderActionMarkCollected) {
      // §7 — closing the order is behind a confirm. It cannot be undone from
      // the app.
      final confirmed = await _confirmCollected();
      if (confirmed != true) return;
    }

    final outcome = key == OrderAction.markReady
        ? await _controller.markReady()
        : await _controller.markCollected();

    if (!mounted) return;
    // B4 — a stale 409 is normal. Silence, and the refreshed card explains
    // itself.
    if (outcome.silent || outcome.copy == null) return;
    commonSnackBar(message: outcome.copy!.tr);
  }

  Future<bool?> _confirmCollected() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OrderRadius.card)),
        title: Text(AppStrings.orderMarkCollectedTitle.tr,
            style: OrderType.title.copyWith(color: AppColors.mainTextColor)),
        content: Text(AppStrings.orderMarkCollectedBody.tr,
            style: OrderType.body.copyWith(color: AppColors.grayText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel.tr,
                style: OrderType.body.copyWith(color: AppColors.grayText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.orderMarkCollected.tr,
                style: OrderType.body.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

/// What the screen popped with, so a caller that keeps a local order list can
/// drop an order the server no longer has (S14).
enum OrderStepsResult { gone }
