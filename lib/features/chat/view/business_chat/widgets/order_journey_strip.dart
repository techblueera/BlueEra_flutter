import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/model/order_journey.dart';
import 'package:flutter/material.dart';

/// The horizontal step tracker on an order card — the strip directly under the
/// order number on every screen of the three order PDFs.
///
/// ```
///  ✓───────✓───────◉───────○───────○───────○
/// Order   Shop  Preparing Ready  Picked  Completed
/// Placed Accepted order  for pickup up
/// ```
///
/// ## Rules it keeps
///
/// * **It scrolls, and it auto-scrolls to the live node.** A UPI delivery
///   order has nine steps; the PDF itself shows them clipped at the right edge
///   mid-flow ("Con…", "Wai…"). Nine nodes cannot be squeezed into a phone
///   width without becoming unreadable, so they keep their size and the strip
///   brings the node that matters into view instead.
/// * **Colour is never the only signal.** Done is a tick, current is a filled
///   ring, pending is hollow, cancelled is a cross — legible in a shop
///   doorway at noon, and to a colour-blind shopkeeper.
/// * **The connector describes the past, not the plan.** A line is green only
///   when the step behind it is genuinely done, which is what makes a
///   cancelled order's tail read as "never happened" rather than "not yet".
/// * **Nothing animates.** This strip sits inside a chat list that is already
///   moving; a pulsing node in a scrolling list reads as a rendering fault.
///   Movement on the card belongs to the one zone that earns it (the rider
///   search radar).
class OrderJourneyStrip extends StatefulWidget {
  final OrderJourney journey;

  /// Used to re-run the auto-scroll when the live node moves.
  final String? semanticsKey;

  const OrderJourneyStrip({
    super.key,
    required this.journey,
    this.semanticsKey,
  });

  @override
  State<OrderJourneyStrip> createState() => _OrderJourneyStripState();
}

class _OrderJourneyStripState extends State<OrderJourneyStrip> {
  final ScrollController _scroll = ScrollController();

  /// Width of one node column. Wide enough for two lines of a label like
  /// "Waiting for shop acceptance" at 11pt without truncating the words the
  /// customer needs ("Waiting", "acceptance").
  static const double _nodeWidth = 86;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealLiveNode());
  }

  @override
  void didUpdateWidget(OrderJourneyStrip old) {
    super.didUpdateWidget(old);
    final movedTo = _liveIndex(widget.journey);
    if (movedTo != _liveIndex(old.journey)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealLiveNode());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The node the person should be looking at: whatever is live, else the last
  /// thing that happened. A completed order therefore opens showing its end,
  /// and a fresh one opens at the start — both without a tap.
  int _liveIndex(OrderJourney journey) {
    final steps = journey.steps;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].isCurrent || steps[i].isCancelled) return i;
    }
    var lastDone = 0;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].isDone) lastDone = i;
    }
    return lastDone;
  }

  void _revealLiveNode() {
    if (!mounted || !_scroll.hasClients) return;
    final index = _liveIndex(widget.journey);
    final viewport = _scroll.position.viewportDimension;
    // Centre it, then clamp — a target near either end must not leave the
    // strip scrolled into empty space.
    final target = (index * _nodeWidth) - (viewport / 2) + (_nodeWidth / 2);
    final clamped = target.clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    if ((clamped - _scroll.offset).abs() < 1) return;
    _scroll.animateTo(
      clamped,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.journey.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

    return Semantics(
      // One spoken sentence instead of eleven labels read as a list.
      label: _spokenSummary(steps),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 74,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: steps.length,
            itemBuilder: (_, i) => _node(
              step: steps[i],
              isFirst: i == 0,
              isLast: i == steps.length - 1,
              // The line coming into this node is solid only if the step
              // before it actually completed.
              incomingDone: i > 0 && steps[i - 1].isDone,
              outgoingDone: steps[i].isDone &&
                  i + 1 < steps.length &&
                  (steps[i + 1].isDone || steps[i + 1].isCurrent),
            ),
          ),
        ),
      ),
    );
  }

  String _spokenSummary(List<OrderJourneyStep> steps) {
    final live = widget.journey.currentStep;
    final cancelled =
        steps.where((s) => s.isCancelled).map((s) => s.label).join();
    if (cancelled.isNotEmpty) return cancelled;
    if (live != null) return live.label;
    var last = steps.first.label;
    for (final s in steps) {
      if (s.isDone) last = s.label;
    }
    return last;
  }

  Widget _node({
    required OrderJourneyStep step,
    required bool isFirst,
    required bool isLast,
    required bool incomingDone,
    required bool outgoingDone,
  }) {
    final tone = _toneFor(step.state);
    const dot = 20.0;

    return SizedBox(
      width: _nodeWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: dot + 4,
            child: Row(
              children: [
                Expanded(
                  child: isFirst
                      ? const SizedBox.shrink()
                      : _connector(done: incomingDone),
                ),
                _dot(step: step, tone: tone, size: dot),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : _connector(done: outgoingDone),
                ),
              ],
            ),
          ),
          const SizedBox(height: OrderSpace.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              step.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                // The live step and everything achieved are emphasised; what
                // has not happened yet recedes.
                fontWeight: step.state == OrderJourneyStepState.pending
                    ? FontWeight.w400
                    : FontWeight.w700,
                color: step.state == OrderJourneyStepState.pending
                    ? AppColors.grayText
                    : tone.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector({required bool done}) => Container(
        height: 2,
        color: done ? OrderTone.success.color : AppColors.greyE5,
      );

  Widget _dot({
    required OrderJourneyStep step,
    required OrderTone tone,
    required double size,
  }) {
    switch (step.state) {
      case OrderJourneyStepState.done:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: tone.color, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 13, color: Colors.white),
        );

      case OrderJourneyStepState.current:
        // Ring, not a filled dot: the step is open, not finished. The inner
        // disc is what makes it read as "here" at a glance.
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: tone.color, width: 2),
          ),
          child: Center(
            child: Container(
              width: size / 2.5,
              height: size / 2.5,
              decoration:
                  BoxDecoration(color: tone.color, shape: BoxShape.circle),
            ),
          ),
        );

      case OrderJourneyStepState.cancelled:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: tone.color, width: 2),
          ),
          child: Icon(Icons.close, size: 12, color: tone.color),
        );

      case OrderJourneyStepState.pending:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.greyE5, width: 2),
          ),
        );
    }
  }

  OrderTone _toneFor(OrderJourneyStepState state) {
    switch (state) {
      case OrderJourneyStepState.done:
        return OrderTone.success;
      case OrderJourneyStepState.current:
        return OrderTone.warning;
      case OrderJourneyStepState.cancelled:
        return OrderTone.danger;
      case OrderJourneyStepState.pending:
        return OrderTone.muted;
    }
  }
}
