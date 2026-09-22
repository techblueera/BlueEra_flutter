import 'package:flutter/material.dart';

/// Drop-in replacement for [PopupMenuButton] that measures its anchor ONCE.
///
/// `PopupMenuButton` passes `positionBuilder` to the menu route, and Flutter
/// calls that closure on *every layout of the menu*, re-running
/// `button.localToGlobal()` against the anchor each time
/// (popup_menu.dart:1705 → :1636). The closure guards `mounted`,
/// `button.attached` and `overlay.attached` — but never "has this been laid
/// out". So any frame in which the anchor's page is laid out lazily or not at
/// all, while the anchor is still mounted and attached, throws
///
///   Bad state: RenderBox was not laid out: RenderFractionalTranslation
///
/// from `RenderBox.size` inside `applyPaintTransform`, with the
/// `FractionalTranslation` being the page's slide transition.
///
/// [AnchoredMenuDismissObserver] closes menus when navigation happens, which
/// covers the known trigger. This closes the hole itself: the same route
/// accepts a STATIC `position` instead of a builder (popup_menu.dart:1050,
/// `positionBuilder?.call(...) ?? position!`), and [showMenu] takes exactly
/// that. Measuring once, in the tap handler — a moment when the anchor is
/// necessarily laid out, because the user just hit it — means there is no
/// later re-measure to go wrong.
///
/// The trade-off is that the menu does not follow its anchor if the anchor
/// moves while the menu is open. Nothing here anchors to something that moves
/// under an open menu, and a menu that stays put beats one that crashes.
class AppPopupMenuButton<T> extends StatefulWidget {
  const AppPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.onCanceled,
    this.initialValue,
    this.icon,
    this.child,
    this.offset = Offset.zero,
    this.shape,
    this.color,
    this.padding = const EdgeInsets.all(8.0),
    this.menuPadding,
    this.tooltip,
    this.enabled = true,
    this.constraints,
    this.elevation,
    this.splashRadius,
    this.iconSize,
    this.position = PopupMenuPosition.over,
  }) : assert(child == null || icon == null,
            'Pass either child or icon, not both.');

  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final void Function(T)? onSelected;
  final VoidCallback? onCanceled;
  final T? initialValue;
  final Widget? icon;
  final Widget? child;
  final Offset offset;
  final ShapeBorder? shape;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? menuPadding;
  final String? tooltip;
  final bool enabled;
  final BoxConstraints? constraints;
  final double? elevation;
  final double? splashRadius;
  final double? iconSize;
  final PopupMenuPosition position;

  @override
  State<AppPopupMenuButton<T>> createState() => _AppPopupMenuButtonState<T>();
}

class _AppPopupMenuButtonState<T> extends State<AppPopupMenuButton<T>> {
  Future<void> _show() async {
    final RenderObject? buttonObject = context.findRenderObject();
    final RenderObject? overlayObject =
        Navigator.of(context).overlay?.context.findRenderObject();
    if (buttonObject is! RenderBox || overlayObject is! RenderBox) return;

    // The guard the framework's position builder is missing. At tap time these
    // all hold; checking anyway costs nothing and makes the method total.
    if (!buttonObject.attached ||
        !overlayObject.attached ||
        !buttonObject.hasSize ||
        !overlayObject.hasSize) {
      return;
    }

    Offset offset = widget.offset;
    if (widget.position == PopupMenuPosition.under) {
      offset = Offset(0.0, buttonObject.size.height) + offset;
      if (widget.child == null) {
        // Matches PopupMenuButton: drop the icon button's own padding.
        offset -= Offset(0.0, widget.padding.vertical / 2);
      }
    }

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonObject.localToGlobal(offset, ancestor: overlayObject),
        buttonObject.localToGlobal(
          buttonObject.size.bottomRight(Offset.zero) + offset,
          ancestor: overlayObject,
        ),
      ),
      Offset.zero & overlayObject.size,
    );

    final List<PopupMenuEntry<T>> items = widget.itemBuilder(context);
    if (items.isEmpty) return;

    final T? selected = await showMenu<T>(
      context: context,
      position: position,
      items: items,
      shape: widget.shape,
      color: widget.color,
      constraints: widget.constraints,
      initialValue: widget.initialValue,
      menuPadding: widget.menuPadding,
      elevation: widget.elevation,
      popUpAnimationStyle: null,
    );

    if (!mounted) return;
    if (selected == null) {
      widget.onCanceled?.call();
    } else {
      widget.onSelected?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mirrors PopupMenuButton.build: a child gets an InkWell, otherwise an
    // IconButton carrying the default "more" icon.
    if (widget.child != null) {
      return Tooltip(
        message: widget.tooltip ?? '',
        child: InkWell(
          onTap: widget.enabled ? _show : null,
          radius: widget.splashRadius,
          child: widget.child,
        ),
      );
    }
    return IconButton(
      icon: widget.icon ?? Icon(Icons.adaptive.more),
      padding: widget.padding,
      splashRadius: widget.splashRadius,
      iconSize: widget.iconSize,
      tooltip: widget.tooltip,
      onPressed: widget.enabled ? _show : null,
    );
  }
}
