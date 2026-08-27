import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The §6.1 status chip. **One chip, eight states, shared by the chat card and
/// the steps screen** so the two can never describe the same order
/// differently.
///
/// | `orderStatus` | Chip | Colour |
/// |---|---|---|
/// | `placed` | Placed | amber |
/// | `accepted` | Accepted | blue |
/// | `in-progress` | In progress / Ready for pickup | blue |
/// | `ready` | Ready for pickup | green |
/// | `dispatched` | On the way | blue |
/// | `completed` | Completed | green |
/// | `cancelled` | Cancelled | grey |
/// | `expired` | Expired | grey |
///
/// Grocery only ever emits `placed`, `in-progress` and `completed` (plus
/// `cancelled` via a direct write) — all eight are handled anyway, because the
/// enum is shared across every vertical.
class OrderStatusChip extends StatelessWidget {
  final String? orderStatus;

  /// `is_cancelled` from a legacy chat card. **It wins** over [orderStatus]:
  /// a cancelled card routinely arrives with `order_status: null` (C10).
  final bool isCancelled;

  /// The stage the order is standing on, when the caller knows it. Only used
  /// to disambiguate `in-progress`, which means "being packed" in one vertical
  /// and "packed, waiting on the counter" in another.
  final String? stageKey;

  final bool compact;

  const OrderStatusChip({
    super.key,
    this.orderStatus,
    this.isCancelled = false,
    this.stageKey,
    this.compact = false,
  });

  /// Null when there is nothing to say — no status, not cancelled. A chip that
  /// says "—" is noise.
  static String? labelFor(String? orderStatus,
      {bool isCancelled = false, String? stageKey}) {
    if (isCancelled) return AppStrings.orderStatusCancelled.tr;
    switch (orderStatus) {
      case OrderStatusValue.placed:
        return AppStrings.orderStatusPlaced.tr;
      case OrderStatusValue.accepted:
        return AppStrings.orderStatusAccepted.tr;
      case OrderStatusValue.inProgress:
        final key = (stageKey ?? '').toLowerCase();
        return (key.contains('ready') || key.contains('pickup'))
            ? AppStrings.orderStatusReadyForPickup.tr
            : AppStrings.orderStatusInProgress.tr;
      case OrderStatusValue.ready:
        return AppStrings.orderStatusReadyForPickup.tr;
      case OrderStatusValue.dispatched:
        return AppStrings.orderStatusOnTheWay.tr;
      case OrderStatusValue.completed:
        return AppStrings.orderStatusCompleted.tr;
      case OrderStatusValue.cancelled:
        return AppStrings.orderStatusCancelled.tr;
      case OrderStatusValue.expired:
        return AppStrings.orderStatusExpired.tr;
      default:
        return null;
    }
  }

  static OrderTone toneFor(String? orderStatus, {bool isCancelled = false}) {
    if (isCancelled) return OrderTone.muted;
    switch (orderStatus) {
      case OrderStatusValue.placed:
        return OrderTone.warning;
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
      case OrderStatusValue.dispatched:
        return OrderTone.accent;
      case OrderStatusValue.ready:
      case OrderStatusValue.completed:
        return OrderTone.success;
      case OrderStatusValue.cancelled:
      case OrderStatusValue.expired:
        return OrderTone.muted;
      default:
        return OrderTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        labelFor(orderStatus, isCancelled: isCancelled, stageKey: stageKey);
    if (label == null) return const SizedBox.shrink();

    final tone = toneFor(orderStatus, isCancelled: isCancelled);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? OrderSpace.s : OrderSpace.m,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(OrderRadius.pill),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colour never carries the meaning on its own — the dot is paired
          // with the word, always.
          OrderStatusDot(tone: tone, size: compact ? 6 : 8),
          SizedBox(width: compact ? OrderSpace.xs : OrderSpace.s),
          Text(
            label,
            style: OrderType.label.copyWith(
              color: tone.color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
