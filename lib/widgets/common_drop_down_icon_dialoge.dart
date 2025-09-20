import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonDropdownIconDialog<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedValue;
  final String hintText;
  final String title;
  final String Function(T) displayValue;
  final String Function(T) displayValueSubTitle;
  final String Function(T) displayValueImagePath;
  final ValueChanged<T?> onChanged;
  final String? errorText;

  const CommonDropdownIconDialog({
    Key? key,
    required this.items,
    required this.selectedValue,
    required this.hintText,
    required this.title,
    required this.displayValue,
    required this.onChanged,
    this.errorText,
    required this.displayValueSubTitle,
    required this.displayValueImagePath,
  }) : super(key: key);

  @override
  State<CommonDropdownIconDialog<T>> createState() =>
      _CommonDropdownIconDialogState<T>();
}

class _CommonDropdownIconDialogState<T>
    extends State<CommonDropdownIconDialog<T>> {
  Future<void> _showDropdownDialog() async {
    final selected = await showDialog<T>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size10,vertical: SizeConfig.size25),
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
                CustomText(
                  widget.title,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.size16,
                ),
                SizedBox(height: SizeConfig.size12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return InkWell(
                        onTap: (){
                          Navigator.of(context).pop(item);

                        },
                        child: Padding(
                          padding:  EdgeInsets.symmetric(vertical: SizeConfig.size10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              LocalAssets(
                                imagePath: widget.displayValueImagePath(item),
                                width: SizeConfig.size30,
                                height: SizeConfig.size30,
                              ),
                              SizedBox(
                                width: SizeConfig.size10,
                              ),
                              Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      widget.displayValue(item),
                                      fontWeight: FontWeight.w600,
                                      // fontSize: SizeConfig.small,
                                      color: AppColors.mainTextColor,
                                    ),
                                    CustomText(
                                      widget.displayValueSubTitle(item),
                                      fontSize: SizeConfig.small,
                                      color: AppColors.mainTextColor,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                      return ListTile(
                        leading: LocalAssets(
                            imagePath: widget.displayValueImagePath(item)),
                        title: CustomText(
                          widget.displayValue(item),
                          fontWeight: FontWeight.w600,
                          // fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                        ),
                        subtitle: CustomText(
                          widget.displayValueSubTitle(item),
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                        ),
                        onTap: () {
                          Navigator.of(context).pop(item);
                        },
                      );
                    },
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
                        ),
                ),
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
