import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/model/order_track_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// The order steps tracker (§6.2 of `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md`).
///
/// ```
/// ✓───────────●───────────○
/// Order      Ready for   Completed
/// placed     pickup
/// 27 Aug     27 Aug        —
/// 12:00 PM   12:01 PM
/// ```
///
/// Every rule this enforces exists because the payload breaks one of them in
/// production:
///
/// * **Labels are server copy** and are rendered verbatim. A stage key this
///   build has never seen still draws, using its label (S2) — that is how a
///   fourth step ships without an app release.
/// * **Array order is layout order.** A later stage marked done before an
///   earlier one is not re-sorted (S4).
/// * **`currentStage` wins** over `orderStatus` for which node is current — a
///   live capture has `placed` next to `ready_for_pickup` and the stage is the
///   one that is right (S5).
/// * A done stage with `at: null` shows the tick and hides the timestamp (S3).
/// * A cancelled order keeps its completed history at full strength and gets a
///   grey terminal node appended (S9).
/// * A timestamp in the future is clock skew, not the future — clamped to
///   "just now" (S12).
class OrderStepper extends StatelessWidget {
  final OrderTrackModel order;

  const OrderStepper({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final stages = order.stages;

    // S1 — no stages at all. The caller renders the status chip on its own;
    // an empty stepper frame would be worse than none.
    if (stages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: OrderSpace.m),
        child: Text(
          AppStrings.orderStepsEmptyStages.tr,
          style: OrderType.label.copyWith(color: AppColors.grayText),
        ),
      );
    }

    final currentIndex = order.currentIndex;
    final lastDone = order.lastDoneIndex;
    final cancelled = order.isCancelled;

    final nodes = <Widget>[];
    for (var i = 0; i < stages.length; i++) {
      final stage = stages[i];

      // A cancelled order stops where it stopped. Steps after the last
      // completed one are neither "current" nor pending — they never happened.
      final isCurrent = !cancelled && i == currentIndex && !stage.done;
      final isAfterCancel = cancelled && i > lastDone;

      nodes.add(_StepRow(
        stage: stage,
        isFirst: i == 0,
        isLast: i == stages.length - 1 && !cancelled,
        done: stage.done,
        current: isCurrent,
        dimmed: isAfterCancel,
        // The connector above this node is solid once the step before it is
        // done — it describes progress that happened, not progress expected.
        incomingSolid: i > 0 && stages[i - 1].done,
      ));
    }

    // S9 — the grey terminal node, appended rather than replacing anything.
    if (cancelled) {
      nodes.add(_StepRow(
        stage: OrderStage(
          key: 'cancelled',
          label: order.orderStatus == 'expired'
              ? AppStrings.orderStatusExpired.tr
              : AppStrings.orderStatusCancelled.tr,
          done: true,
          at: order.cancelledAt,
          note: order.cancellationReason,
        ),
        isFirst: false,
        isLast: true,
        done: true,
        current: false,
        dimmed: false,
        terminal: true,
        incomingSolid: false,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes,
    );
  }
}

class _StepRow extends StatelessWidget {
  final OrderStage stage;
  final bool isFirst;
  final bool isLast;
  final bool done;
  final bool current;
  final bool dimmed;
  final bool terminal;
  final bool incomingSolid;

  const _StepRow({
    required this.stage,
    required this.isFirst,
    required this.isLast,
    required this.done,
    required this.current,
    required this.dimmed,
    required this.incomingSolid,
    this.terminal = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = terminal
        ? OrderTone.muted
        : done
            ? OrderTone.success
            : current
                ? OrderTone.accent
                : OrderTone.muted;

    final labelColor = dimmed
        ? AppColors.grayText
        : (done || current)
            ? AppColors.mainTextColor
            : AppColors.grayText;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Connector in.
                SizedBox(
                  height: 6,
                  child: isFirst
                      ? const SizedBox.shrink()
                      : _Connector(solid: incomingSolid),
                ),
                _Node(tone: tone, done: done, current: current),
                // Connector out — fills whatever height the label block takes.
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : _Connector(solid: done),
                ),
              ],
            ),
          ),
          const SizedBox(width: OrderSpace.s),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: OrderSpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Server copy, verbatim. Never "Ready for pickup" hard-coded
                    // over whatever the server actually called this step.
                    stage.label,
                    style: OrderType.body.copyWith(
                      fontWeight:
                          current || done ? FontWeight.w700 : FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  // S3 — a done stage with no timestamp shows the tick and
                  // nothing else. A hollow future step shows an em dash.
                  if (stage.at != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        formatStageTime(stage.at!),
                        style: OrderType.label.copyWith(
                          color: AppColors.grayText,
                          fontFeatures: OrderType.tabular,
                        ),
                      ),
                    )
                  else if (!done)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('—',
                          style: OrderType.label
                              .copyWith(color: AppColors.grayText)),
                    ),
                  if ((stage.note ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        stage.note!,
                        style:
                            OrderType.label.copyWith(color: AppColors.grayText),
                      ),
                    ),
                  // S7 — one sub-row per shop, each with its own status.
                  if (stage.businesses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: OrderSpace.s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: stage.businesses
                            .map((b) => _BusinessSubRow(business: b))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `27 Aug, 12:01 PM`, and **"just now"** for anything the device thinks is
  /// in the future — a wrong clock must not print tomorrow's date (S12).
  static String formatStageTime(DateTime at) {
    final now = DateTime.now();
    if (at.isAfter(now.add(const Duration(minutes: 1)))) return 'Just now';
    return DateFormat('d MMM, h:mm a').format(at);
  }
}

class _Node extends StatelessWidget {
  final OrderTone tone;
  final bool done;
  final bool current;

  const _Node({required this.tone, required this.done, required this.current});

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: tone.color, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 13, color: Colors.white),
      );
    }
    if (current) {
      // The one pulsing thing on the screen: where the order is standing.
      return Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tone.color.withValues(alpha: 0.16),
        ),
        child: OrderStatusDot(tone: tone, pulse: true, size: 10),
      );
    }
    // Future — hollow.
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.greyE5, width: 2),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool solid;
  const _Connector({required this.solid});

  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        color: solid
            ? OrderTone.success.color.withValues(alpha: 0.45)
            : AppColors.greyE5,
      );
}

/// One shop inside a multi-shop stage (S7). Its `status` is server text; it is
/// shown, not switched on.
class _BusinessSubRow extends StatelessWidget {
  final OrderStageBusiness business;
  const _BusinessSubRow({required this.business});

  @override
  Widget build(BuildContext context) {
    final ready = business.isReady;
    return Padding(
      padding: const EdgeInsets.only(bottom: OrderSpace.xs),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: ready ? OrderTone.success.color : AppColors.grayText,
          ),
          const SizedBox(width: OrderSpace.xs),
          Expanded(
            child: Text(
              business.name ?? business.businessId ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OrderType.label.copyWith(color: AppColors.mainTextColor),
            ),
          ),
          if ((business.status ?? '').isNotEmpty)
            Text(
              OrderStage.humaniseStageKey(business.status!),
              style: OrderType.label.copyWith(
                color: ready ? OrderTone.success.color : AppColors.grayText,
              ),
            ),
        ],
      ),
    );
  }
}
