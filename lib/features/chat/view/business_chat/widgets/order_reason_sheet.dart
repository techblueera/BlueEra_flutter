import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_card_ui.dart';
import 'package:flutter/material.dart';

/// What the user picked in [showOrderReasonSheet].
class OrderReasonChoice {
  final String reasonCode;
  final String? comment;

  const OrderReasonChoice({required this.reasonCode, this.comment});
}

/// **The board's confirmation sheet** — `Cancel this order?` and
/// `Reject Payment Screenshot?` are the same object with different words.
///
/// The shape is deliberate and is the board's, not ours:
///
/// ```
///        ◉ (red, ringed)
///     Cancel this order?
///  Your order is currently being prepared by the shop.
///  Cancellation may not be available once preparation…
///  ┌────────────────────────────────┐
///  │ Order #0D1247   🛍 Self Pickup │  ← what you are about to end
///  │ ▣▣▣              Total ₹600    │
///  │ ⓘ No payment has been collected│
///  └────────────────────────────────┘
///  ┌────────────────────────────────┐
///  │ Why are you cancelling?        │  ← reasons, two to a row
///  └────────────────────────────────┘
///  [ Keep Order ]   [ ✕ Cancel Order ]
/// ```
///
/// The order preview between the question and the answer is the point of the
/// design: the destructive button is two taps from a chat list, and the only
/// thing standing between a mis-tap and a cancelled order is seeing *which*
/// order it is.
///
/// **The list comes from `/actions` → `cancellationReasons[]`, already scoped
/// to the caller's role.** It is never hard-coded: a customer must not be able
/// to pick `ITEM_UNAVAILABLE`, and the server would refuse it with
/// `INVALID_REASON` anyway (guide §9).
///
/// When [reasons] is empty the sheet degrades to a free-text-only form and
/// submits [fallbackReasonCode] — better than blocking the user because the
/// list hadn't loaded, and the server still validates.
Future<OrderReasonChoice?> showOrderReasonSheet(
  BuildContext context, {
  required String title,
  required List<OrderCancellationReason> reasons,
  String confirmLabel = 'Confirm',
  String fallbackReasonCode = 'OTHER',
  String commentHint = 'Add a note (optional)',
  bool destructive = true,

  /// The line under the title — what state the order is in right now.
  String? subtitle,

  /// The grey caveat under that.
  String? caption,

  /// `Keep Order` on both of the board's sheets.
  String keepLabel = 'Keep Order',

  /// The board's question above the radio grid.
  String? reasonPrompt,

  /// The order (or the screenshot) this is about, drawn between the question
  /// and the answers.
  Widget? preview,
}) {
  return showModalBottomSheet<OrderReasonChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OrderReasonSheet(
      title: title,
      reasons: reasons,
      confirmLabel: confirmLabel,
      fallbackReasonCode: fallbackReasonCode,
      commentHint: commentHint,
      destructive: destructive,
      subtitle: subtitle,
      caption: caption,
      keepLabel: keepLabel,
      reasonPrompt: reasonPrompt,
      preview: preview,
    ),
  );
}

class _OrderReasonSheet extends StatefulWidget {
  final String title;
  final List<OrderCancellationReason> reasons;
  final String confirmLabel;
  final String fallbackReasonCode;
  final String commentHint;
  final bool destructive;
  final String? subtitle;
  final String? caption;
  final String keepLabel;
  final String? reasonPrompt;
  final Widget? preview;

  const _OrderReasonSheet({
    required this.title,
    required this.reasons,
    required this.confirmLabel,
    required this.fallbackReasonCode,
    required this.commentHint,
    required this.destructive,
    required this.keepLabel,
    this.subtitle,
    this.caption,
    this.reasonPrompt,
    this.preview,
  });

  @override
  State<_OrderReasonSheet> createState() => _OrderReasonSheetState();
}

class _OrderReasonSheetState extends State<_OrderReasonSheet> {
  String? _selected;
  final TextEditingController _comment = TextEditingController();
  String? _error;

  /// The free-text field is folded away until it is needed — the board does
  /// not draw one, and a reason that requires a note opens it on selection.
  bool _noteOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.reasons.length == 1) _selected = widget.reasons.first.code;
    // No list at all means free text is the whole form.
    if (widget.reasons.isEmpty) _noteOpen = true;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  OrderCancellationReason? get _selectedReason {
    for (final r in widget.reasons) {
      if (r.code == _selected) return r;
    }
    return null;
  }

  void _submit() {
    final hasList = widget.reasons.isNotEmpty;
    if (hasList && _selected == null) {
      setState(() => _error = 'Pick a reason to continue');
      return;
    }
    final reason = _selectedReason;
    final comment = _comment.text.trim();
    if (reason?.requiresComment == true && comment.isEmpty) {
      setState(() {
        _noteOpen = true;
        _error = 'This reason needs a short note';
      });
      return;
    }
    if (!hasList && comment.isEmpty) {
      setState(() => _error = 'Tell them why, in a few words');
      return;
    }
    Navigator.of(context).pop(OrderReasonChoice(
      reasonCode: _selected ?? widget.fallbackReasonCode,
      comment: comment.isEmpty ? null : comment,
    ));
  }

  Color get _accent => widget.destructive ? OrderUi.danger : OrderUi.blue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _grabberAndClose(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ringedMark(),
                      const SizedBox(height: 14),
                      Text(widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: OrderUi.ink)),
                      if ((widget.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: OrderUi.ink,
                                height: 1.35)),
                      ],
                      if ((widget.caption ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(widget.caption!,
                            textAlign: TextAlign.center,
                            style: OrderUi.blockBody
                                .copyWith(color: OrderUi.inkFaint)),
                      ],
                      if (widget.preview != null) ...[
                        const SizedBox(height: 16),
                        widget.preview!,
                      ],
                      const SizedBox(height: 14),
                      _reasonCard(),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: OrderUi.danger)),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: OrderButtonRow(buttons: [
                  OrderButton(
                    label: widget.keepLabel,
                    style: OrderButtonStyle.secondary,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _confirmButton(),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The board's confirm button is **filled** red — the one place in the order
  /// flow where a destructive action is: the user has already been shown the
  /// order, the reasons and a way out, so there is nothing left to protect
  /// them from except ambiguity.
  Widget _confirmButton() {
    return Material(
      color: _accent,
      borderRadius: BorderRadius.circular(OrderUi.buttonRadius),
      child: InkWell(
        onTap: _submit,
        borderRadius: BorderRadius.circular(OrderUi.buttonRadius),
        child: Container(
          height: OrderUi.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  widget.destructive
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  size: 17,
                  color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(widget.confirmLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabberAndClose() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD8DCE3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Positioned(
          right: 10,
          top: 6,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            customBorder: const CircleBorder(),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: OrderUi.block, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 19, color: OrderUi.ink),
            ),
          ),
        ),
      ],
    );
  }

  /// The concentric ring the board draws over both sheets.
  Widget _ringedMark() {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withValues(alpha: 0.10),
          ),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.18),
            ),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: _accent),
              child: Icon(
                  widget.destructive
                      ? Icons.priority_high_rounded
                      : Icons.question_mark_rounded,
                  size: 24,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  /// `Why are you cancelling? (optional)` and the reasons, two to a row.
  Widget _reasonCard() {
    final anyRequiresComment =
        widget.reasons.any((r) => r.requiresComment);
    final prompt = widget.reasonPrompt ??
        (widget.reasons.isEmpty
            ? 'Tell them what happened'
            : 'Why? ${anyRequiresComment ? '(Required)' : '(optional)'}');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: OrderUi.ink)),
          if (widget.reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Two to a row, as the board draws them — five short reasons in
            // one column would push the buttons off a small screen.
            LayoutBuilder(builder: (context, c) {
              final twoUp = c.maxWidth > 300;
              final w = twoUp ? (c.maxWidth - 10) / 2 : c.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  for (final r in widget.reasons)
                    SizedBox(width: w, child: _reasonTile(r)),
                ],
              );
            }),
          ],
          if (_noteOpen) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 300,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              style: const TextStyle(fontSize: 14, color: OrderUi.ink),
              decoration: InputDecoration(
                hintText: widget.commentHint,
                hintStyle: OrderUi.blockBody,
                counterText: '',
                filled: true,
                fillColor: OrderUi.block,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: OrderUi.blockBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: OrderUi.blockBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accent),
                ),
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _noteOpen = true),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Add a note', style: OrderUi.link),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reasonTile(OrderCancellationReason r) {
    final selected = _selected == r.code;
    return InkWell(
      onTap: () => setState(() {
        _selected = r.code;
        _error = null;
        if (r.requiresComment) _noteOpen = true;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 19,
              height: 19,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? OrderUi.blue : const Color(0xFFC6CCD6),
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: OrderUi.blue),
                    )
                  : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                r.label,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? OrderUi.ink : OrderUi.inkSoft,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The order mini-card the board draws inside the cancel sheet.
///
/// It exists so the destructive question is asked *about something visible*:
/// `Order #0D1247 · 🛍 Self Pickup · 💵 Cash at Shop`, the items, the total,
/// and — the line that settles the only thing a cancelling customer actually
/// worries about — how much money has changed hands.
class OrderCancelPreview extends StatelessWidget {
  final String orderNo;
  final bool isDelivery;
  final bool isCash;
  final List<String> thumbnails;
  final String totalAmount;

  /// `No payment has been collected yet.`
  final String? moneyNote;

  const OrderCancelPreview({
    super.key,
    required this.orderNo,
    required this.isDelivery,
    required this.isCash,
    required this.totalAmount,
    this.thumbnails = const [],
    this.moneyNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('Order #$orderNo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: OrderUi.ink)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: OrderMetaRow(
                      isDelivery: isDelivery, isCash: isCash),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: OrderUi.blockBorder)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: OrderThumbStrip(urls: thumbnails)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Amount', style: OrderUi.faint),
                    const SizedBox(height: 2),
                    Text(totalAmount, style: OrderUi.amountBig),
                  ],
                ),
              ],
            ),
          ),
          if ((moneyNote ?? '').isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(
                color: OrderUi.block,
                border: Border(top: BorderSide(color: OrderUi.blockBorder)),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(OrderUi.blockRadius)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 15, color: OrderUi.inkFaint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(moneyNote!, style: OrderUi.blockBody),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
