import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class CommonDropdownDialog<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedValue;
  final String hintText;
  final String title;
  final String? dialogTitle;
  final String Function(T) displayValue;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final bool? showDownArrow;

  const CommonDropdownDialog({
    Key? key,
    required this.items,
    required this.selectedValue,
    required this.hintText,
    required this.title,
    required this.displayValue,
    required this.onChanged,
    this.errorText,
    this.dialogTitle,
    this.showDownArrow = true,
  }) : super(key: key);

  @override
  State<CommonDropdownDialog<T>> createState() =>
      _CommonDropdownDialogState<T>();
}

class _CommonDropdownDialogState<T> extends State<CommonDropdownDialog<T>> {
  Future<void> _showDropdownDialog() async {
    final selected = await showDialog<T>(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).dialogBackgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.title,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.size16,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size3),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return ListTile(
                        leading: item is CommentTypeModel
                            ? SvgPicture.asset(item.icon, height: 24, width: 24)
                            : null,
                        title: CustomText(
                          widget.displayValue(item).replaceAll('\n', ' '),
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.size15,
                        ),
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                    // itemBuilder: (context, index) {
                    //   final item = widget.items[index];
                    //   return ListTile(
                    //     title: CustomText(
                    //       widget.displayValue(item),
                    //       fontWeight: FontWeight.w400,
                    //       fontSize: SizeConfig.size15,
                    //     ),
                    //     onTap: () {
                    //       Navigator.of(context).pop(item);
                    //     },
                    //   );
                    // },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDropdownDialog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.dialogTitle?.isNotEmpty ?? false)...[
            CustomText(widget.dialogTitle,

              fontSize:SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.paddingL,),
          ],
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15, vertical: SizeConfig.size10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).inputDecorationTheme.fillColor ??
                  Colors.white,
              border: Border.all(
                color: Theme.of(context)
                        .inputDecorationTheme
                        .enabledBorder
                        ?.borderSide
                        .color ??
                    Colors.grey,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 3)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: widget.selectedValue != null
                      ? Row(
                          children: [
                            if (widget.selectedValue is CommentTypeModel)
                              SvgPicture.asset(
                                (widget.selectedValue as CommentTypeModel).icon,
                                height: 22,
                                width: 22,
                              ),
                            if (widget.selectedValue is CommentTypeModel)
                              const SizedBox(width: 8),
                            Flexible(
                              child: CustomText(
                                widget
                                    .displayValue(widget.selectedValue as T)
                                    .replaceAll('\n', ' '),
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.size15,
                              ),
                            ),
                          ],
                        )
                      : CustomText(
                          widget.hintText,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.size15,
                        ), /*widget.selectedValue != null
                      ? CustomText(
                          widget.displayValue(widget.selectedValue as T),
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.size15,
                        )
                      : CustomText(
                          widget.hintText,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.size15,
                        ),*/
                ),
                if (widget.showDownArrow ?? false)
                  const Icon(Icons.keyboard_arrow_down_outlined,
                      color: Colors.grey),
              ],
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: EdgeInsets.only(
                  left: SizeConfig.size12, top: SizeConfig.size6),
              child: CustomText(
                widget.errorText!,
                color: Colors.red,
                fontSize: SizeConfig.small,
              ),
            ),
        ],
      ),
    );
  }
}
