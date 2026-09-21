import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// **The order-card design kit — the BlueEra 2026 board, in widgets.**
///
/// Every order surface in the three boards (`Customer Order Self / Cash / UPI`,
/// `Business Side Order Self / Cash / UPI`, `Order By Rider`) is assembled from
/// the same eight pieces: a header, a meta row, a tinted info block, a code
/// panel, an order-summary block, a payment strip, a button pair and a
/// completion panel. They are built once here so the customer card, the owner
/// card and the rider card cannot drift apart.
///
/// The tokens in `order_design_tokens.dart` stay the semantic layer — *what a
/// colour means*. This file is the **visual** layer: the exact fills, radii and
/// type sizes the board draws. Nothing here decides anything; it only renders.
class OrderUi {
  OrderUi._();

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color card = Colors.white;
  static const Color cardBorder = Color(0xFFEDEFF2);

  /// The neutral block that holds instructions, codes and summaries.
  static const Color block = Color(0xFFF5F6F8);
  static const Color blockBorder = Color(0xFFE7E9EE);

  // ── Ink ────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF0F1621);
  static const Color inkSoft = Color(0xFF55606E);
  static const Color inkFaint = Color(0xFF8A94A6);

  // ── Semantic pairs (fill / ink / border) ───────────────────────────────
  static const Color amber = Color(0xFFA9611B);
  static const Color amberFill = Color(0xFFFDEDD9);
  static const Color amberSoftFill = Color(0xFFFEF7EC);
  static const Color amberBorder = Color(0xFFF0D9B4);

  static const Color green = Color(0xFF2E7D32);
  static const Color greenFill = Color(0xFFE4F6E8);
  static const Color greenSoftFill = Color(0xFFF2FAF3);
  static const Color greenBorder = Color(0xFFCFE9D4);

  static const Color danger = Color(0xFFD0453B);
  static const Color dangerFill = Color(0xFFFCE5E4);
  static const Color dangerSoftFill = Color(0xFFFEF4F3);
  static const Color dangerBorder = Color(0xFFF3CFCB);

  static const Color blue = AppColors.primaryColor;
  static const Color blueFill = Color(0xFFEAF2FF);
  static const Color blueSoftFill = Color(0xFFF3F8FF);
  static const Color blueBorder = Color(0xFFD6E5FF);

  // ── Geometry ───────────────────────────────────────────────────────────
  static const double cardRadius = 16;
  static const double blockRadius = 12;
  static const double buttonRadius = 10;
  static const double buttonHeight = 46;

  static const EdgeInsets cardPad = EdgeInsets.fromLTRB(14, 14, 14, 14);
  static const EdgeInsets blockPad = EdgeInsets.all(14);

  // ── Type ───────────────────────────────────────────────────────────────
  static const TextStyle orderNo =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink);
  static const TextStyle blockTitle =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink, height: 1.25);
  static const TextStyle blockBody = TextStyle(
      fontSize: 12.5, fontWeight: FontWeight.w400, color: inkSoft, height: 1.35);
  static const TextStyle meta =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink);
  static const TextStyle faint =
      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: inkFaint);
  static const TextStyle amountBig =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink);
  static const TextStyle link =
      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: blue);
}

/// One line of the order, as the board's `Your Items` / `Order summary` rows
/// draw it: thumbnail, name, variant, selling price and struck-through MRP.
///
/// The verticals each have their own item model (`SelfPickupItem`,
/// `ProductOrderItem`, …); this is the flat shape the card renders, so the
/// design does not have to know which vertical it is on.
class OrderCardItem {
  final String name;

  /// `1kg`, `500ml`, `Large` — the board's second line.
  final String? variant;
  final String? imageUrl;
  final num? price;
  final num? mrp;
  final int? quantity;

  const OrderCardItem({
    required this.name,
    this.variant,
    this.imageUrl,
    this.price,
    this.mrp,
    this.quantity,
  });

  bool get hasDiscount => mrp != null && price != null && mrp! > price!;
}

/// One `Your Items` row.
class OrderItemRow extends StatelessWidget {
  final OrderCardItem item;
  final bool showDivider;

  const OrderItemRow({super.key, required this.item, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: OrderUi.blockBorder)))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (item.imageUrl ?? '').trim().isEmpty
                ? Container(
                    width: 44,
                    height: 44,
                    color: OrderUi.block,
                    child: const Icon(Icons.image_outlined,
                        size: 18, color: OrderUi.inkFaint),
                  )
                : Image.network(
                    item.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: OrderUi.block,
                      child: const Icon(Icons.image_outlined,
                          size: 18, color: OrderUi.inkFaint),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: OrderUi.ink)),
                if ((item.variant ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.variant!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OrderUi.faint),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.price != null)
                Text('₹${OrderUiFormat.money(item.price!)}',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: OrderUi.ink)),
              if (item.hasDiscount) ...[
                const SizedBox(width: 5),
                Text('₹${OrderUiFormat.money(item.mrp!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: OrderUi.inkFaint,
                      decoration: TextDecoration.lineThrough,
                    )),
              ],
              if ((item.quantity ?? 0) > 1) ...[
                const SizedBox(width: 6),
                Text('×${item.quantity}', style: OrderUi.faint),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Money and clock formatting the board uses, in one place so `₹600` never
/// renders as `₹600.0` on one card and `₹600` on the next.
class OrderUiFormat {
  OrderUiFormat._();

  static String money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  static String rupees(num? v) => v == null ? '—' : '₹${money(v)}';

  /// `9:30 AM`.
  static String clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// `Today, 9:30 AM` / `4th August • 10:00 am`.
  static String dayAndClock(DateTime t) {
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (sameDay) return 'Today, ${clock(t)}';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${t.day} ${months[t.month - 1]}, ${clock(t)}';
  }
}

/// The tinted status pill at the top-right of a card, and inside a payment
/// strip. Board: `Waiting for acceptance`, `Preparing`, `Ready for pickup`,
/// `Order Picked Up`, `Completed`, `Cancelled`, `Payment Pending`,
/// `Payment Verification`, `Payment Valid`, `Not Paid Yet`, `Pending at Shop`,
/// `Payment Completed`.
enum OrderPillTone { amber, green, danger, blue, neutral }

class OrderStatusPill extends StatelessWidget {
  final String label;
  final OrderPillTone tone;
  final IconData? icon;

  /// Slightly smaller variant used inside the order-summary payment strip.
  final bool compact;

  const OrderStatusPill({
    super.key,
    required this.label,
    this.tone = OrderPillTone.amber,
    this.icon,
    this.compact = false,
  });

  Color get _fg {
    switch (tone) {
      case OrderPillTone.amber:
        return OrderUi.amber;
      case OrderPillTone.green:
        return OrderUi.green;
      case OrderPillTone.danger:
        return OrderUi.danger;
      case OrderPillTone.blue:
        return OrderUi.blue;
      case OrderPillTone.neutral:
        return OrderUi.inkSoft;
    }
  }

  Color get _bg {
    switch (tone) {
      case OrderPillTone.amber:
        return OrderUi.amberFill;
      case OrderPillTone.green:
        return OrderUi.greenFill;
      case OrderPillTone.danger:
        return OrderUi.dangerFill;
      case OrderPillTone.blue:
        return OrderUi.blueFill;
      case OrderPillTone.neutral:
        return OrderUi.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 10, vertical: compact ? 5 : 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 14, color: _fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: _fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `Order #0D1247` with either the status pill (customer) or the placed-at
/// timestamp (owner) on the right — exactly the two header variants the boards
/// draw.
class OrderCardHeader extends StatelessWidget {
  final String orderNo;

  /// Customer cards carry the pill here.
  final Widget? trailing;

  /// Owner cards carry `Today, 9:30 AM` here instead.
  final String? trailingText;

  /// `Today, 9:30 AM` under the order number (customer, early states).
  final String? subtitle;

  /// `🛍 Self Pickup · 💵 Cash at Shop` under the order number.
  final Widget? meta;

  const OrderCardHeader({
    super.key,
    required this.orderNo,
    this.trailing,
    this.trailingText,
    this.subtitle,
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(orderNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OrderUi.orderNo),
            ),
            const SizedBox(width: 8),
            if (trailing != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 168),
                child: trailing,
              )
            else if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(trailingText!, style: OrderUi.faint),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: OrderUi.faint),
        ],
        if (meta != null) ...[
          const SizedBox(height: 6),
          meta!,
        ],
      ],
    );
  }
}

/// `🛍 Self Pickup   💳 Cash at Shop` — the immutable identity of the order,
/// drawn on every card from `accepted` onwards.
class OrderMetaRow extends StatelessWidget {
  final bool isDelivery;
  final bool isCash;

  /// The owner's rider cards say `Order By Rider` where the customer's say
  /// `Self Pickup`; pass an override rather than inventing a second widget.
  final String? deliveryLabelOverride;

  const OrderMetaRow({
    super.key,
    required this.isDelivery,
    required this.isCash,
    this.deliveryLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(isDelivery ? Icons.delivery_dining_outlined : Icons.shopping_bag_outlined,
            size: 15, color: OrderUi.ink),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            deliveryLabelOverride ??
                (isDelivery ? 'Order By Rider' : 'Self Pickup'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OrderUi.meta,
          ),
        ),
        const SizedBox(width: 14),
        const Icon(Icons.payments_outlined, size: 15, color: OrderUi.ink),
        const SizedBox(width: 5),
        Flexible(
          child: Text(isCash ? 'Cash at Shop' : 'UPI Payment',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: OrderUi.meta),
        ),
      ],
    );
  }
}

/// The tinted panel that carries one piece of news: the ETA, the arrival
/// instructions, a payment stage, the rider, the cancellation.
///
/// It is one widget because the board draws one shape — circular icon, title,
/// body, optional trailing, optional children — in five colourways.
enum OrderBlockTone { neutral, blue, amber, green, danger }

class OrderInfoBlock extends StatelessWidget {
  final OrderBlockTone tone;
  final IconData? icon;

  /// Replaces the circular icon entirely (used for a thumbnail or a QR).
  final Widget? leading;
  final String? title;
  final String? body;

  /// Small text above the title — the board's `Estimated ready time`.
  final String? overline;
  final Widget? trailing;
  final List<Widget> children;

  /// Draw the 1px border. The board borders the amber, green and danger
  /// panels and leaves the neutral one flat.
  final bool bordered;
  final EdgeInsets? padding;
  final CrossAxisAlignment crossAxisAlignment;

  const OrderInfoBlock({
    super.key,
    this.tone = OrderBlockTone.neutral,
    this.icon,
    this.leading,
    this.title,
    this.body,
    this.overline,
    this.trailing,
    this.children = const [],
    this.bordered = false,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  Color get fill {
    switch (tone) {
      case OrderBlockTone.neutral:
        return OrderUi.block;
      case OrderBlockTone.blue:
        return OrderUi.blueSoftFill;
      case OrderBlockTone.amber:
        return OrderUi.amberSoftFill;
      case OrderBlockTone.green:
        return OrderUi.greenSoftFill;
      case OrderBlockTone.danger:
        return OrderUi.dangerSoftFill;
    }
  }

  Color get accent {
    switch (tone) {
      case OrderBlockTone.neutral:
        return OrderUi.inkSoft;
      case OrderBlockTone.blue:
        return OrderUi.blue;
      case OrderBlockTone.amber:
        return OrderUi.amber;
      case OrderBlockTone.green:
        return OrderUi.green;
      case OrderBlockTone.danger:
        return OrderUi.danger;
    }
  }

  Color get borderColor {
    switch (tone) {
      case OrderBlockTone.neutral:
        return OrderUi.blockBorder;
      case OrderBlockTone.blue:
        return OrderUi.blueBorder;
      case OrderBlockTone.amber:
        return OrderUi.amberBorder;
      case OrderBlockTone.green:
        return OrderUi.greenBorder;
      case OrderBlockTone.danger:
        return OrderUi.dangerBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final head = <Widget>[];
    if (leading != null) {
      head.add(leading!);
      head.add(const SizedBox(width: 12));
    } else if (icon != null) {
      head.add(OrderGlyph(icon: icon!, color: accent));
      head.add(const SizedBox(width: 12));
    }

    final text = <Widget>[
      if (overline != null)
        Text(overline!,
            style: OrderUi.blockBody.copyWith(fontSize: 12, color: OrderUi.inkFaint)),
      if (title != null)
        Text(title!,
            style: OrderUi.blockTitle.copyWith(
                color: tone == OrderBlockTone.neutral ? OrderUi.ink : accent)),
      if (body != null) ...[
        if (title != null) const SizedBox(height: 3),
        Text(body!, style: OrderUi.blockBody),
      ],
    ];

    if (text.isNotEmpty) {
      head.add(Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: text),
      ));
    }
    if (trailing != null) {
      head.add(const SizedBox(width: 10));
      head.add(trailing!);
    }

    return Container(
      width: double.infinity,
      padding: padding ?? OrderUi.blockPad,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: bordered ? Border.all(color: borderColor) : null,
      ),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (head.isNotEmpty)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: head),
          if (children.isNotEmpty) ...[
            if (head.isNotEmpty) const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }
}

/// The soft circular icon badge the board puts at the left of every panel.
class OrderGlyph extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const OrderGlyph(
      {super.key, required this.icon, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.48, color: color),
    );
  }
}

/// The inline hint strip inside a panel — the board's bordered one-liners
/// (`After receiving the cash, then tap 'Payment Collected'`, `Only share this
/// code with the shop…`, `Verify the payment screenshot before…`).
class OrderHintStrip extends StatelessWidget {
  final String text;
  final OrderBlockTone tone;
  final IconData icon;
  final bool bordered;

  const OrderHintStrip({
    super.key,
    required this.text,
    this.tone = OrderBlockTone.blue,
    this.icon = Icons.error_outline,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final block = OrderInfoBlock(tone: tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone == OrderBlockTone.blue ? OrderUi.blueFill : block.fill,
        borderRadius: BorderRadius.circular(10),
        border: bordered ? Border.all(color: block.borderColor) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: block.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: OrderUi.blockBody.copyWith(color: block.accent, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four big digit boxes. `code` shows the digits (customer, `Show Code`);
/// `masked` draws `✳ ✳ ✳ ✳` for the resting owner panel.
class OrderCodeBoxes extends StatelessWidget {
  final String? code;
  final bool masked;
  final double size;

  const OrderCodeBoxes(
      {super.key, this.code, this.masked = false, this.size = 58});

  @override
  Widget build(BuildContext context) {
    final digits = (code ?? '').replaceAll(RegExp(r'\D'), '');
    final slots = math.max(4, digits.length);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(slots, (i) {
        final ch = masked
            ? '✳'
            : (i < digits.length ? digits[i] : '–');
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(horizontal: size * 0.06),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: OrderUi.blockBorder),
          ),
          child: Text(
            ch,
            style: TextStyle(
              fontSize: masked ? size * 0.38 : size * 0.52,
              fontWeight: FontWeight.w700,
              color: masked ? OrderUi.inkSoft : OrderUi.ink,
            ),
          ),
        );
      }),
    );
  }
}

/// The owner's `Verify Pickup Code` entry — four boxes and one button.
///
/// It keeps its own text state so a keystroke does not rebuild the whole chat
/// list, and hands the finished code up on submit.
class OrderCodeInput extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool busy;
  final ValueChanged<String> onSubmit;

  const OrderCodeInput({
    super.key,
    required this.onSubmit,
    this.title = 'Verify Pickup Code',
    this.subtitle = 'Enter the code provided by the customer to verify the pickup.',
    this.buttonLabel = 'Verify &  Continue',
    this.busy = false,
  });

  @override
  State<OrderCodeInput> createState() => _OrderCodeInputState();
}

class _OrderCodeInputState extends State<OrderCodeInput> {
  static const int _len = 4;
  late final List<TextEditingController> _c =
      List.generate(_len, (_) => TextEditingController());
  late final List<FocusNode> _f = List.generate(_len, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    for (final f in _f) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _c.map((e) => e.text).join();

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < _len - 1) {
      _f[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _f[i - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ready = _code.length == _len && !widget.busy;
    return OrderInfoBlock(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.title,
            textAlign: TextAlign.center,
            style: OrderUi.blockTitle.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        Text(widget.subtitle,
            textAlign: TextAlign.center, style: OrderUi.blockBody),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_len, (i) {
            return Container(
              width: 54,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _f[i].hasFocus ? OrderUi.blue : OrderUi.blockBorder,
                ),
              ),
              child: TextField(
                controller: _c[i],
                focusNode: _f[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                onChanged: (v) => _onChanged(i, v),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: OrderUi.ink),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText: '✳',
                  hintStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: OrderUi.inkFaint),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        OrderButton(
          label: widget.buttonLabel,
          trailingIcon: Icons.arrow_forward,
          busy: widget.busy,
          onTap: ready ? () => widget.onSubmit(_code) : null,
        ),
      ],
    );
  }
}

/// The board's button. One shape, four emphases.
enum OrderButtonStyle { primary, secondary, danger, success }

class OrderButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final OrderButtonStyle style;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool busy;
  final double height;

  const OrderButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = OrderButtonStyle.primary,
    this.icon,
    this.trailingIcon,
    this.busy = false,
    this.height = OrderUi.buttonHeight,
  });

  Color get _bg {
    switch (style) {
      case OrderButtonStyle.primary:
        return OrderUi.blue;
      case OrderButtonStyle.success:
        return OrderUi.green;
      case OrderButtonStyle.danger:
        return OrderUi.dangerFill;
      case OrderButtonStyle.secondary:
        return const Color(0xFFF7F8FA);
    }
  }

  Color get _fg {
    switch (style) {
      case OrderButtonStyle.primary:
      case OrderButtonStyle.success:
        return Colors.white;
      case OrderButtonStyle.danger:
        return OrderUi.danger;
      case OrderButtonStyle.secondary:
        return OrderUi.inkSoft;
    }
  }

  Color? get _border {
    switch (style) {
      case OrderButtonStyle.secondary:
        return OrderUi.blockBorder;
      case OrderButtonStyle.danger:
        return null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || busy;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: _bg,
        borderRadius: BorderRadius.circular(OrderUi.buttonRadius),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(OrderUi.buttonRadius),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OrderUi.buttonRadius),
              border: _border == null ? null : Border.all(color: _border!),
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _fg),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 17, color: _fg),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: _fg),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(trailingIcon, size: 17, color: _fg),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The board never stacks buttons: it draws one full-width, or two side by
/// side with the primary on the right.
class OrderButtonRow extends StatelessWidget {
  final List<Widget> buttons;
  const OrderButtonRow({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    if (buttons.length == 1) return buttons.first;
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

/// **Order summary** — the block that closes almost every card.
///
/// Two variants, both from the board:
/// * *compact* — a strip of item thumbnails on the left, `Total Amount` on the
///   right, and a payment strip underneath.
/// * *expanded* (`placed`, before anyone has acted) — full item rows, then
///   `Total Amount` / `Pickup Method` / `Payment Method`.
class OrderSummaryBlock extends StatelessWidget {
  /// Thumbnail urls, in order. At most three are drawn — the board shows three.
  final List<String> thumbnails;
  final String totalLabel;
  final String totalAmount;
  final VoidCallback? onViewDetails;

  /// The `Cash at Shop / Not Paid Yet` strip drawn inside the block.
  final Widget? paymentStrip;

  /// Drawn instead of the thumbnail strip when the card is in its opening
  /// state: the full item list plus the method rows.
  final List<Widget>? expandedRows;

  /// The board titles this `Order summary` and, in the opening state, gives it
  /// a receipt icon.
  final bool showReceiptIcon;

  const OrderSummaryBlock({
    super.key,
    this.thumbnails = const [],
    this.totalLabel = 'Total Amount',
    required this.totalAmount,
    this.onViewDetails,
    this.paymentStrip,
    this.expandedRows,
    this.showReceiptIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = expandedRows != null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: expanded ? OrderUi.block : Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                if (showReceiptIcon) ...[
                  const Icon(Icons.receipt_long_outlined,
                      size: 18, color: OrderUi.ink),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text('Order summary',
                      style: OrderUi.blockTitle.copyWith(fontSize: 15)),
                ),
                if (onViewDetails != null)
                  GestureDetector(
                    onTap: onViewDetails,
                    behavior: HitTestBehavior.opaque,
                    child: const Text('View Details', style: OrderUi.link),
                  ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(children: expandedRows!),
            )
          else
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: OrderUi.blockBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: OrderThumbStrip(urls: thumbnails)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(totalLabel, style: OrderUi.faint),
                      const SizedBox(height: 2),
                      Text(totalAmount, style: OrderUi.amountBig),
                    ],
                  ),
                ],
              ),
            ),
          if (paymentStrip != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: paymentStrip,
            ),
        ],
      ),
    );
  }
}

/// Up to three 44dp item thumbnails, as the board draws them.
class OrderThumbStrip extends StatelessWidget {
  final List<String> urls;
  final double size;

  const OrderThumbStrip({super.key, required this.urls, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final shown = urls.where((u) => u.trim().isNotEmpty).take(3).toList();
    if (shown.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: OrderUi.block,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2_outlined,
              size: 18, color: OrderUi.inkFaint),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == shown.length - 1 ? 0 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                shown[i],
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: OrderUi.block,
                  child: const Icon(Icons.image_not_supported_outlined,
                      size: 16, color: OrderUi.inkFaint),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The payment line inside the summary block: icon, title, sub-line, status
/// pill. Amber while money is owed, green once it is in.
class OrderPaymentStrip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String statusLabel;
  final OrderPillTone tone;

  /// Amber and green strips are tinted; the resting one sits on white.
  final bool tinted;

  const OrderPaymentStrip({
    super.key,
    required this.icon,
    required this.title,
    required this.statusLabel,
    this.subtitle,
    this.tone = OrderPillTone.amber,
    this.tinted = true,
  });

  Color get _fill {
    if (!tinted) return Colors.white;
    switch (tone) {
      case OrderPillTone.green:
        return OrderUi.greenSoftFill;
      case OrderPillTone.danger:
        return OrderUi.dangerSoftFill;
      case OrderPillTone.blue:
        return OrderUi.blueSoftFill;
      case OrderPillTone.neutral:
        return OrderUi.block;
      case OrderPillTone.amber:
        return OrderUi.amberSoftFill;
    }
  }

  Color get _accent {
    switch (tone) {
      case OrderPillTone.green:
        return OrderUi.green;
      case OrderPillTone.danger:
        return OrderUi.danger;
      case OrderPillTone.blue:
        return OrderUi.blue;
      case OrderPillTone.neutral:
        return OrderUi.inkSoft;
      case OrderPillTone.amber:
        return OrderUi.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fill,
        border: const Border(top: BorderSide(color: OrderUi.blockBorder)),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(OrderUi.blockRadius)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OrderGlyph(icon: icon, color: _accent, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: OrderUi.ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: OrderUi.blockBody.copyWith(fontSize: 11.5)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OrderStatusPill(
            label: statusLabel,
            tone: tone,
            compact: true,
            icon: tone == OrderPillTone.green ? Icons.check_circle_outline : null,
          ),
        ],
      ),
    );
  }
}

/// A key/value row — the board's `Total Amount / Pickup Method / Payment
/// Method` block and the cancellation table.
class OrderKeyValueRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasise;

  const OrderKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: OrderUi.inkSoft),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w400, color: OrderUi.inkSoft)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasise ? 14 : 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? OrderUi.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shop / rider card: avatar, name, address, distance, map thumbnail.
class OrderPartyCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String? address;
  final String? distance;

  /// `Open Now` beside the name on the shop card.
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  const OrderPartyCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.address,
    this.distance,
    this.badge,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(OrderUi.blockRadius),
          border: Border.all(color: OrderUi.blockBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (photoUrl ?? '').trim().isEmpty
                  ? Container(
                      width: 46,
                      height: 46,
                      color: OrderUi.block,
                      child: const Icon(Icons.storefront_outlined,
                          size: 20, color: OrderUi.inkFaint),
                    )
                  : Image.network(
                      photoUrl!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 46,
                        height: 46,
                        color: OrderUi.block,
                        child: const Icon(Icons.storefront_outlined,
                            size: 20, color: OrderUi.inkFaint),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: OrderUi.ink)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: OrderUi.greenFill,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: OrderUi.green)),
                        ),
                      ],
                    ],
                  ),
                  if ((address ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OrderUi.blockBody),
                  ],
                  if ((distance ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: OrderUi.blue),
                        const SizedBox(width: 3),
                        Text(distance!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: OrderUi.blue)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The green tick illustration the board puts on every terminal-success panel
/// (`Order Completed!`, `Payment Verified`).
///
/// Drawn rather than shipped as an asset: it is two circles, a stroke and four
/// speed lines, and a vector scales to any card width without a 3× PNG.
class OrderSuccessMark extends StatelessWidget {
  final double size;
  final Color color;

  const OrderSuccessMark(
      {super.key, this.size = 84, this.color = const Color(0xFF6BBF59)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.6,
      height: size,
      child: CustomPaint(painter: _SuccessMarkPainter(color)),
    );
  }
}

class _SuccessMarkPainter extends CustomPainter {
  final Color color;
  _SuccessMarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final c = Offset(size.width * 0.62, size.height / 2);

    canvas.drawCircle(c, r * 0.92, Paint()..color = color);

    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = r * 0.26
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(c.dx - r * 0.42, c.dy + r * 0.04)
      ..lineTo(c.dx - r * 0.08, c.dy + r * 0.38)
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.42);
    canvas.drawPath(path, stroke);

    // Speed lines to the left — the board's little motion cue.
    final line = Paint()
      ..color = color
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = c.dy - r * 0.34 + i * r * 0.34;
      final w = r * (0.5 - i * 0.08);
      final x = c.dx - r * (1.12 + i * 0.06);
      canvas.drawLine(Offset(x - w, y), Offset(x, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessMarkPainter old) => old.color != color;
}

/// The whole `Order Completed!` / `Payment Verified` panel.
class OrderOutcomePanel extends StatelessWidget {
  final String title;
  final String? body;
  final Color color;
  final bool bordered;

  const OrderOutcomePanel({
    super.key,
    required this.title,
    this.body,
    this.color = OrderUi.green,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, OrderUi.greenSoftFill],
        ),
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(
            color: bordered ? OrderUi.green : OrderUi.blockBorder),
      ),
      child: Column(
        children: [
          const OrderSuccessMark(size: 76),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, color: color)),
          if ((body ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body!,
                textAlign: TextAlign.center,
                style: OrderUi.blockBody.copyWith(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// The green announcement bubble above the card — `Your order has been placed
/// successfully!` / `New Order Received`.
class OrderAnnouncementBar extends StatelessWidget {
  final String title;
  final String subtitle;

  const OrderAnnouncementBar(
      {super.key, required this.title, this.subtitle = 'Just Now'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FBF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OrderUi.greenBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
                color: OrderUi.green, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: OrderUi.ink)),
                Text(subtitle, style: OrderUi.faint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Numbered instruction list — `When you arrive at the shop`.
class OrderStepsList extends StatelessWidget {
  final List<String> steps;
  const OrderStepsList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 18,
                  child: Text('${i + 1}.',
                      style: OrderUi.blockBody.copyWith(color: OrderUi.inkFaint)),
                ),
                Expanded(child: Text(steps[i], style: OrderUi.blockBody)),
              ],
            ),
          ),
      ],
    );
  }
}
