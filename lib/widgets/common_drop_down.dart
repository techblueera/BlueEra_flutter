import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CommonDropdown<T> extends FormField<T> {
  CommonDropdown({
    Key? key,
    required List<T> items,
    required T? selectedValue,
    required String hintText,
    required void Function(T?) onChanged,
    required String Function(T) displayValue,
    String? Function(T?)? validator,
    bool isExpanded = true,
  }) : super(
    key: key,
    initialValue: selectedValue,
    validator: validator,
    builder: (FormFieldState<T> state) {
      return _CommonDropdownInternal<T>(
        items: items,
        selectedValue: selectedValue,
        hintText: hintText,
        onChanged: (val) {
          state.didChange(val);
          onChanged(val);
        },
        displayValue: displayValue,
        errorText: state.errorText,
      );
    },
  );
}

class _CommonDropdownInternal<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedValue;
  final String hintText;
  final void Function(T?) onChanged;
  final String Function(T) displayValue;
  final String? errorText;

  const _CommonDropdownInternal({
    required this.items,
    required this.selectedValue,
    required this.hintText,
    required this.onChanged,
    required this.displayValue,
    this.errorText,
  });

  @override
  State<_CommonDropdownInternal<T>> createState() => _CustomDropdownOverlayInternalState<T>();
}

class _CustomDropdownOverlayInternalState<T> extends State<_CommonDropdownInternal<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _key = GlobalKey();

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlay() {
    RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = SizeConfig.screenHeight;

    // Calculate max available height below the dropdown
    final maxHeight = screenHeight - offset.dy - size.height - 40;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Close dropdown when tapping outside
            GestureDetector(
              onTap: _toggleDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
                width: SizeConfig.screenWidth,
                height: SizeConfig.screenHeight,
              ),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 4,
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 4,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: AppColors.white,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxHeight, // ✅ limit dropdown to visible screen space
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < widget.items.length; i++) ...[
                                InkWell(
                                  onTap: () {
                                    widget.onChanged(widget.items[i]);
                                    _toggleDropdown();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size10,
                                      vertical: SizeConfig.size10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.items[i] == widget.selectedValue
                                          ? AppColors.primaryColor
                                          : AppColors.white,
                                      borderRadius: i == 0
                                          ? BorderRadius.vertical(top: Radius.circular(10))
                                          : i == widget.items.length - 1
                                          ? BorderRadius.vertical(bottom: Radius.circular(10))
                                          : BorderRadius.zero,
                                    ),
                                    child: CustomText(
                                      widget.displayValue(widget.items[i]),
                                      color: widget.items[i] == widget.selectedValue
                                          ? AppColors.white
                                          : AppColors.black28,
                                      fontWeight: FontWeight.w400,
                                      fontSize: SizeConfig.size15,
                                    ),
                                  ),
                                ),
                                if (i != widget.items.length - 1)
                                  CommonHorizontalDivider(color: AppColors.grey99, height: 0.2),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: _toggleDropdown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.white,
                border: Border.all(
                  color: Theme.of(context).inputDecorationTheme.enabledBorder?.borderSide.color ?? AppColors.greyE5,
                ),
                  boxShadow: [AppShadows.textFieldShadow]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: widget.selectedValue != null ?
                    CustomText(
                      widget.displayValue(widget.selectedValue!),
                      fontSize: SizeConfig.large,
                      color: AppColors.black,
                      fontWeight: FontWeight.w400
                    ) :  CustomText(
                    widget.hintText,
                    fontSize: Theme.of(context).inputDecorationTheme.hintStyle?.fontSize ?? SizeConfig.large,
                    color: Theme.of(context).inputDecorationTheme.hintStyle?.color ?? AppColors.grey9A,
                    fontWeight: Theme.of(context).inputDecorationTheme.hintStyle?.fontWeight ?? FontWeight.w400,
                   ),
                  ),
                  Icon(Icons.keyboard_arrow_down_outlined, color: AppColors.grey9A),
                ],
              ),
            ),
            if (widget.errorText != null)
              Padding(
                padding: EdgeInsets.only(left: 12, top: 6),
                child: CustomText(
                  widget.errorText!,
                  color: AppColors.red,
                  fontSize: SizeConfig.small,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
