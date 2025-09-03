import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CustomDropdownForDocumentType extends StatefulWidget {
  final String? title;
  final FontWeight? fontWeight;
  final double? fontSize;
  final List<BusinessDocumentType> items;
  final String hint;
  final Function(String)? onChanged;

  const CustomDropdownForDocumentType({
    super.key,
    this.title,
    this.fontWeight,
    this.fontSize,
    required this.items,
    required this.hint,
    this.onChanged,
  });

  @override
  _CustomDropdownForDocumentTypeState createState() => _CustomDropdownForDocumentTypeState();
}

class _CustomDropdownForDocumentTypeState extends State<CustomDropdownForDocumentType> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String? _selectedItem;
  final TextEditingController _otherController = TextEditingController();
  final ValueNotifier<bool> _showTextField = ValueNotifier<bool>(false);
  ValueNotifier<int> selectedIndex = ValueNotifier<int>(-1);
  bool disableDoneBtn = true;

  @override
  void initState() {
    _otherController.addListener(() {
      print("Current text: ${_otherController.text}");
      disableDoneBtn = _otherController.text.isEmpty;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _otherController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      removeOverlay();
    }
  }


  void removeOverlay(){
    _showTextField.value = false;
    _otherController.clear();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    log("size is--> $size");
    log("offset is--> $offset");
    log("_selectedItem is--> $_selectedItem");

    if(_selectedItem == BusinessDocumentType.otherGovtLicense){
      log("inside this");
      _showTextField.value = true;
    }

    return OverlayEntry(
      builder: (context) {
        final appLocalizations = AppLocalizations.of(context);

        // final viewInsets = WidgetsBinding.instance.window.viewInsets.bottom;
        // double keyboardHeight = viewInsets / WidgetsBinding.instance.window.devicePixelRatio;
        // double adjustedTop = offset.dy;
        // if (keyboardHeight > 0) {
        //   adjustedTop = offset.dy - keyboardHeight / 2;
        // }

        return Stack(
        children: [
          // 👇 Fullscreen transparent detector to catch outside taps
          GestureDetector(
            onTap: () {
              removeOverlay();
            },
            behavior: HitTestBehavior.translucent, // Ensures it detects all taps
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // 👇 dropdown overlay
          Positioned(
            left: offset.dx,
            top: offset.dy,
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height - SizeConfig.size20),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  // height: SizeConfig.size250,
                  decoration: BoxDecoration(
                    color: AppColors.blue35,
                    borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 3.0
                        )
                      ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      ...widget.items.asMap().entries.map((item) {
                        return InkWell(
                          onTap: () {
                            selectedIndex.value = item.key;
                            _selectedItem = item.value.label;
                            if(item.value != BusinessDocumentType.otherGovtLicense) {
                              setState(() {
                                widget.onChanged?.call(item.value.label);
                                _toggleDropdown();
                              });
                              _showTextField.value = false;
                            }else{
                              _showTextField.value = true;
                            }
                          },
                          child: ValueListenableBuilder<int>(
                              valueListenable: selectedIndex,
                              builder: (context, value, child){
                                return  Container(
                                  decoration: BoxDecoration(
                                    color: value == item.key ? AppColors.primaryColor : Colors.transparent,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.value.label,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                          ),
                        );
                      }),

                      ValueListenableBuilder<bool>(
                          valueListenable: _showTextField,
                          builder:  (context, value, child){
                            return value ? Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    appLocalizations?.nameOfTheDocument,
                                    fontSize: SizeConfig.extraSmall,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  SizedBox(height: SizeConfig.size4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                        CommonTextField(
                                          textEditController: _otherController,
                                          // inputLength: AppConstants.inputCharterLimit50,
                                          keyBoardType: TextInputType.text,
                                          // regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                                          hintText: appLocalizations?.pleaseSpecifyIfOther,
                                          isValidate: false,
                                          // onTap: (){
                                          //   Future.delayed(Duration(milliseconds: 300), () {
                                          //     // _rebuildOverlay(); // recreate with updated offset
                                          //   });
                                          // },
                                          // onChange: (value) => ,
                                        ),
                                      ),
                                      SizedBox(width: SizeConfig.size10),
                                      CustomBtn(
                                        height:  SizeConfig.size35,
                                        width: SizeConfig.size50,
                                        title: appLocalizations?.done,
                                        onTap: () {
                                          setState(() {
                                            _selectedItem = _otherController.text;
                                            widget.onChanged?.call(_otherController.text);
                                            _toggleDropdown();
                                          });
                                        },
                                        isValidate: !disableDoneBtn,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ) : SizedBox();
                          }
                      ),
                    ],
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.title == null || (widget.title?.isEmpty ?? false)
            ? const SizedBox.shrink()
            : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              widget.title ?? '',
              fontSize: widget.fontSize ?? SizeConfig.medium,
              fontWeight: widget.fontWeight ?? FontWeight.w600,
            ),
            // if (isOptionalFiled) const OptionalTextWidget(),
          ],
        ),
        widget.title == null || (widget.title?.isEmpty ?? false)
            ? const SizedBox.shrink()
            : SizedBox(height: SizeConfig.paddingXSL),

        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: SizeConfig.size12),
              decoration: BoxDecoration(
                color: AppColors.black28,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedItem ?? widget.hint,
                      style: TextStyle(
                        color: _selectedItem == null ? Colors.grey : Colors.white,
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Icon(
                    _overlayEntry == null
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
