import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Saves one variant's price to the inventory endpoint. Each caller supplies
/// the concrete service (product-service for admin/manufacturer cards,
/// earn-service for the home-made-product screens) — the sheet stays generic.
typedef PriceUpdateCallback = Future<bool> Function({
  required String inventoryId,
  required num sellingPrice,
  required num mrp,
  required bool varientIsActive,
});

/// Bottom sheet to update sellingPrice + mrp per variant of a product. Each
/// variant has its own Update button — they're saved independently (the API
/// patches one inventory record at a time), so there's no combined save.
class ProductPriceEditSheet {
  static Future<void> show({
    required BuildContext context,
    required GetProductData product,
    required PriceUpdateCallback onUpdate,
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
        onUpdate: onUpdate,
      ),
    );
  }
}

class _PriceEditSheetBody extends StatefulWidget {
  final GetProductData product;
  final PriceUpdateCallback onUpdate;

  const _PriceEditSheetBody({
    required this.product,
    required this.onUpdate,
  });

  @override
  State<_PriceEditSheetBody> createState() => _PriceEditSheetBodyState();
}

class _PriceEditSheetBodyState extends State<_PriceEditSheetBody> {
  late final List<TextEditingController> _priceCtrls;
  late final List<TextEditingController> _mrpCtrls;

  /// Per-variant saving flag so each Update button shows its own spinner.
  late final List<bool> _saving;

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
    _saving = List<bool>.filled(_classification.variants.length, false);
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

  Future<void> _onUpdateVariant(int i) async {
    final v = _classification.variants[i];
    // The update endpoint keys off the inventory record id, not the
    // variant `_id`; fall back to the variant id only if it's missing.
    final inventoryId = v.inventoryId.isNotEmpty ? v.inventoryId : v.id;
    if (inventoryId.isEmpty) {
      commonSnackBar(message: 'This variant can\'t be updated');
      return;
    }
    setState(() => _saving[i] = true);
    final newPrice = num.tryParse(_priceCtrls[i].text.trim()) ?? v.sellingPrice;
    final newMrp = num.tryParse(_mrpCtrls[i].text.trim()) ?? v.mrp;
    final ok = await widget.onUpdate(
      inventoryId: inventoryId,
      sellingPrice: newPrice,
      mrp: newMrp,
      varientIsActive: v.variantIsActive,
    );
    if (!mounted) return;
    setState(() => _saving[i] = false);
    commonSnackBar(message: ok ? 'Updated' : 'Update failed');
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
                          _variantLabel(v, i),
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
                        SizedBox(height: SizeConfig.size10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _updateButton(i),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _updateButton(int i) {
    final saving = _saving[i];
    return GestureDetector(
      onTap: saving ? null : () => _onUpdateVariant(i),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size20,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : CustomText(
                'Update',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
      ),
    );
  }

  /// A meaningful name for a variant card. Prefers the variant's attribute
  /// label (e.g. "Color: Red • Size: M"); when the variant has no attributes
  /// (common single-variant products) it falls back to the product name rather
  /// than a generic "Variant N".
  String _variantLabel(Variant v, int index) {
    final attrLabel = _attributesLabel(v);
    if (attrLabel != null) return attrLabel;
    final productName = widget.product.product.details?.name.trim() ?? '';
    if (productName.isNotEmpty) return productName;
    return 'Variant ${index + 1}';
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
    return parts.isEmpty ? null : parts.join(' • ');
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
