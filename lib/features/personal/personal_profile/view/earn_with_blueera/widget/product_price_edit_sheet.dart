import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Bottom sheet to update sellingPrice + mrp on each variant of a product.
class ProductPriceEditSheet {
  static Future<void> show({
    required BuildContext context,
    required GetProductData product,
    required EarnServiceController controller,
  }) async {
    final classification = product.product.sellerClassification;
    if (classification == null || classification.variants.isEmpty) {
      commonSnackBar(message: 'No variants to edit');
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (_) => _PriceEditSheetBody(
        product: product,
        controller: controller,
      ),
    );
  }
}

class _PriceEditSheetBody extends StatefulWidget {
  final GetProductData product;
  final EarnServiceController controller;

  const _PriceEditSheetBody({
    required this.product,
    required this.controller,
  });

  @override
  State<_PriceEditSheetBody> createState() => _PriceEditSheetBodyState();
}

class _PriceEditSheetBodyState extends State<_PriceEditSheetBody> {
  late final List<TextEditingController> _priceCtrls;
  late final List<TextEditingController> _mrpCtrls;

  SellerClassification get _classification =>
      widget.product.product.sellerClassification!;

  @override
  void initState() {
    super.initState();
    _priceCtrls = [
      for (final v in _classification.variants)
        TextEditingController(text: v.sellingPrice.toString()),
    ];
    _mrpCtrls = [
      for (final v in _classification.variants)
        TextEditingController(text: v.mrp.toString()),
    ];
  }

  @override
  void dispose() {
    for (final c in _priceCtrls) {
      c.dispose();
    }
    for (final c in _mrpCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onSave() async {
    bool allOk = true;
    for (var i = 0; i < _classification.variants.length; i++) {
      final v = _classification.variants[i];
      final newPrice =
          num.tryParse(_priceCtrls[i].text.trim()) ?? v.sellingPrice;
      final newMrp = num.tryParse(_mrpCtrls[i].text.trim()) ?? v.mrp;
      final ok = await widget.controller.updateProductVariantPrice(
        inventoryId: _classification.id,
        variantId: v.id,
        sellingPrice: newPrice,
        mrp: newMrp,
        varientIsActive: v.variantIsActive,
      );
      if (!ok) allOk = false;
    }
    if (!mounted) return;
    commonSnackBar(message: allOk ? 'Updated' : 'Some updates failed');
    if (allOk) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final variants = _classification.variants;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  CustomText('Update Price',
                      fontSize: 18, fontWeight: FontWeight.w600),
                  CloseButton(),
                ],
              ),
              CustomText(
                widget.product.product.details?.name ?? '',
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size16),
              ...List.generate(variants.length, (i) {
                final v = variants[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.size12),
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.greyE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          _attributesLabel(v) ?? 'Variant ${i + 1}',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Row(
                          children: [
                            Expanded(
                              child: CommonTextField(
                                textEditController: _priceCtrls[i],
                                title: 'Selling Price',
                                hintText: '0',
                                keyBoardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size10),
                            Expanded(
                              child: CommonTextField(
                                textEditController: _mrpCtrls[i],
                                title: 'MRP',
                                hintText: '0',
                                keyBoardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: SizeConfig.size16),
              CustomBtn(
                radius: 10,
                bgColor: AppColors.primaryColor,
                title: AppStrings.save,
                onTap: _onSave,
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  static String? _attributesLabel(Variant v) {
    if (v.attributes.isEmpty) return null;
    final parts = <String>[];
    v.attributes.forEach((k, value) {
      String text;
      if (value is Map && value['color_name'] != null) {
        text = value['color_name'].toString();
      } else {
        text = value.toString();
      }
      parts.add('${_titleCase(k)}: $text');
    });
    return parts.join(' • ');
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
