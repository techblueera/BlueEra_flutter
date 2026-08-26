import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Zone ③ — the only part of an order card allowed to animate** (guide §4).
///
/// The rider search used to be a dead spinner while the server was doing
/// something worth watching: three rounds, an expanding radius, a real count of
/// partners rung. Every value rendered here is already on the wire — this
/// widget invents nothing (guide §7.3).
///
/// Two honesty rules it holds to:
///
///  1. **No invented denominator.** "17 partners called" is a complete, true
///     sentence; "17 of 23" is not derivable and a fake total is worse than no
///     total, because the customer counts down against it.
///  2. **`ridersNotified: 0` is a normal answer.** That round reads *"none
///     nearby"* and the headline reads *"Widening the search…"*. Silence reads
///     as a hang; an honest "looking further" reads as work.
class OrderBroadcastSearchSection extends StatefulWidget {
  final String orderId;

  /// Shown when the race ends with nobody. **Not a cancellation** — the goods
  /// are packed and can still be collected (guide §7.6).
  final VoidCallback? onCollectMyself;
  final VoidCallback? onTryAgain;

  const OrderBroadcastSearchSection({
    super.key,
    required this.orderId,
    this.onCollectMyself,
    this.onTryAgain,
  });

  @override
  State<OrderBroadcastSearchSection> createState() =>
      _OrderBroadcastSearchSectionState();
}

class _OrderBroadcastSearchSectionState
    extends State<OrderBroadcastSearchSection> {
  final OrderClock _clock = OrderClock.instance;

  @override
  void initState() {
    super.initState();
    _clock.addListener(_tick);
  }

  @override
  void dispose() {
    _clock.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  OrderBroadcastController get _c => OrderBroadcastController.instance;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dispatching = _c.dispatching.contains(widget.orderId);
      final search = _c.searches[widget.orderId];

      if (search == null) {
        if (dispatching) return _shell(child: _dispatchingBody());
        // Dispatch could not even be attempted — say so plainly rather than
        // spinning forever.
        if (_c.undispatchable.contains(widget.orderId)) {
          return _shell(child: _noPartnerBody(couldNotStart: true));
        }
        return const SizedBox.shrink();
      }

      if (search.assigned) {
        // The rider cards take over from here (guide §7.5); this zone
        // collapses rather than competing with them.
        return const SizedBox.shrink();
      }

      if (search.exhausted) {
        return _shell(child: _noPartnerBody());
      }

      return _shell(child: _searchingBody(search));
    });
  }

  Widget _shell({required Widget child}) {
    return AnimatedSize(
      duration: OrderMotion.zoneExpand,
      curve: OrderMotion.curve,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
            OrderSpace.m, OrderSpace.s, OrderSpace.m, 0),
        padding: const EdgeInsets.all(OrderSpace.m),
        decoration: BoxDecoration(
          color: OrderTone.neutral.surface,
          borderRadius: BorderRadius.circular(OrderRadius.inner),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: child,
      ),
    );
  }

  // ── Dispatching ──────────────────────────────────────────────────────

  Widget _dispatchingBody() {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: OrderSpace.s),
        Expanded(
          child: Text(
            'Sending this to nearby delivery partners…',
            style: OrderType.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
        ),
      ],
    );
  }

  // ── Searching ────────────────────────────────────────────────────────

  Widget _searchingBody(BroadcastSearch s) {
    final called = s.calledTotal;
    final nobodyYet = called == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const OrderStatusDot(tone: OrderTone.accent, pulse: true),
            const SizedBox(width: OrderSpace.s),
            Expanded(
              child: Text(
                // Zero partners so far is a real state, and saying so is what
                // stops the block reading as a hang.
                nobodyYet
                    ? 'Widening the search…'
                    : 'Finding a delivery partner',
                style: OrderType.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: OrderSpace.m),

        // The radar — one ring, eased to each new radius. Not a strobe.
        Center(child: _Radar(radiusKm: s.radiusKm)),
        const SizedBox(height: OrderSpace.s),
        Center(
          child: Text(
            s.radiusKm > 0 ? 'within ${_km(s.radiusKm)} km' : 'starting…',
            style: OrderType.label.copyWith(
              color: AppColors.grayText,
              fontFeatures: OrderType.tabular,
            ),
          ),
        ),
        const SizedBox(height: OrderSpace.m),

        // Determinate: we know exactly how long this takes.
        ClipRRect(
          borderRadius: BorderRadius.circular(OrderRadius.pill),
          child: LinearProgressIndicator(
            value: s.progress,
            minHeight: 6,
            backgroundColor: AppColors.greyE5,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryColor),
          ),
        ),
        const SizedBox(height: OrderSpace.s),
        Row(
          children: [
            Text(
              // "round", not "wave" — this is customer-facing.
              'round ${math.max(s.currentRound, 1)} of ${s.totalRounds}',
              style: OrderType.label.copyWith(color: AppColors.grayText),
            ),
            const Spacer(),
            Text(
              OrderCountdownFormat.remaining(s.remaining),
              style: OrderType.label.copyWith(
                color: AppColors.grayText,
                fontFeatures: OrderType.tabular,
              ),
            ),
          ],
        ),

        if (called > 0) ...[
          const SizedBox(height: OrderSpace.m),
          Row(
            children: [
              _AvatarStack(count: called),
              const SizedBox(width: OrderSpace.s),
              Expanded(
                child: Text(
                  // Cumulative. No "of N" — that number does not exist.
                  '$called partner${called == 1 ? '' : 's'} called',
                  style: OrderType.label.copyWith(
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (s.rounds.isNotEmpty) ...[
          const SizedBox(height: OrderSpace.m),
          ..._timeline(s),
        ],

        const SizedBox(height: OrderSpace.m),
        Row(
          children: [
            if (s.fare != null || (s.etaLabel ?? '').isNotEmpty)
              Expanded(
                child: Text(
                  [
                    if (s.fare != null) '₹${OrderMoneyRow.money(s.fare!)}',
                    if ((s.etaLabel ?? '').isNotEmpty) s.etaLabel!,
                  ].join(' · '),
                  style: OrderType.label.copyWith(
                    color: AppColors.grayText,
                    fontFeatures: OrderType.tabular,
                  ),
                ),
              )
            else
              const Spacer(),
            TextButton(
              onPressed: () => _c.cancelSearch(widget.orderId),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: OrderSpace.s),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Cancel search',
                style: OrderType.label.copyWith(
                  color: AppColors.grayText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// One row per round, appended as each event lands. ✓ done · ◐ current ·
  /// ○ up next — three rows appearing one at a time say more than any
  /// percentage, and every character of it is server truth.
  List<Widget> _timeline(BroadcastSearch s) {
    final rows = <Widget>[];
    for (var i = 1; i <= s.totalRounds; i++) {
      final done = s.rounds.where((r) => r.index == i).toList();
      final row = done.isEmpty ? null : done.first;
      final isCurrent = i == s.currentRound;
      final isFuture = row == null && i > s.currentRound;

      final IconData icon;
      final Color color;
      if (row != null && !isCurrent) {
        icon = Icons.check_circle;
        color = OrderTone.success.color;
      } else if (isCurrent) {
        icon = Icons.adjust;
        color = AppColors.primaryColor;
      } else {
        icon = Icons.circle_outlined;
        color = AppColors.grayText;
      }

      final String text;
      if (row == null) {
        text = 'round $i — up next';
      } else if (row.foundNobody) {
        // Never "0 partners called".
        text = 'round $i · ${_km(row.radiusKm)} km — none nearby';
      } else {
        text = 'round $i · ${_km(row.radiusKm)} km — '
            '${row.notified} ${isCurrent ? 'more ' : ''}called';
      }

      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: OrderSpace.xs),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: OrderSpace.s),
            Expanded(
              child: Text(
                text,
                style: OrderType.label.copyWith(
                  color:
                      isFuture ? AppColors.grayText : AppColors.mainTextColor,
                  fontFeatures: OrderType.tabular,
                ),
              ),
            ),
          ],
        ),
      ));
    }
    return rows;
  }

  // ── No partner found (guide §7.6) ────────────────────────────────────

  /// **This is not a cancellation and must not look like one.** The goods
  /// exist, the shop is holding them, and the order is deliberately still
  /// alive on the server.
  Widget _noPartnerBody({bool couldNotStart = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const OrderStatusDot(tone: OrderTone.warning),
            const SizedBox(width: OrderSpace.s),
            Expanded(
              child: Text(
                couldNotStart
                    ? "We couldn't start the delivery search"
                    : 'No delivery partner found',
                style: OrderType.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: OrderSpace.xs),
        Text(
          'Your order is packed and waiting at the shop. '
          'You can collect it, or try again.',
          style: OrderType.label.copyWith(color: AppColors.grayText),
        ),
        const SizedBox(height: OrderSpace.m),
        Wrap(
          spacing: OrderSpace.s,
          runSpacing: OrderSpace.s,
          children: [
            if (widget.onTryAgain != null)
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: widget.onTryAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: OrderSpace.l),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(OrderRadius.inner)),
                  ),
                  child: Text('Try again',
                      style: OrderType.label.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            if (widget.onCollectMyself != null)
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: widget.onCollectMyself,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryColor),
                    padding:
                        const EdgeInsets.symmetric(horizontal: OrderSpace.m),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(OrderRadius.inner)),
                  ),
                  child: Text('Collect it myself',
                      style: OrderType.label.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _km(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// One ring, eased to each new radius. Two pulses per round — a constant
/// strobe is noise, not progress.
class _Radar extends StatefulWidget {
  final double radiusKm;
  const _Radar({required this.radiusKm});

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3 km → 6 km → 10 km maps onto the visible ring.
    final t = (widget.radiusKm.clamp(0, 10)) / 10.0;
    final size = 44.0 + 40.0 * t;

    return SizedBox(
      height: 96,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - _pulse.value) * 0.5,
                  child: Container(
                    width: size * (0.7 + _pulse.value * 0.6),
                    height: size * (0.7 + _pulse.value * 0.6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: OrderMotion.radar,
                  curve: OrderMotion.curve,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.35)),
                  ),
                ),
                const Icon(Icons.storefront,
                    size: 18, color: AppColors.primaryColor),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Five faceless silhouettes plus `+N`. This is progress, not a roster — the
/// server never tells us who was rung, and pretending otherwise would be a
/// fabrication.
class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    final shown = math.min(count, 5);
    return SizedBox(
      height: 24,
      width: 24.0 + (shown - 1) * 14.0 + (count > shown ? 26 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.greyE5,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.person,
                    size: 13, color: AppColors.grayText),
              ),
            ),
          if (count > shown)
            Positioned(
              left: shown * 14.0,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greyE5,
                  borderRadius: BorderRadius.circular(OrderRadius.pill),
                ),
                child: Text('+${count - shown}',
                    style: OrderType.label.copyWith(
                      fontSize: 10,
                      color: AppColors.grayText,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}
