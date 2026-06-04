import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/color_selection_tile.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class AddVariantDialog extends StatefulWidget {
  final ProductController controller;

  const AddVariantDialog({super.key, required this.controller});

  @override
  State<AddVariantDialog> createState() => _AddVariantDialogState();
}

class _AddVariantDialogState extends State<AddVariantDialog> {
  final titleController = TextEditingController();
  final detailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Local temp list for color selection
  final RxList<SelectedColor> localSelectedColors = <SelectedColor>[].obs;

  bool get isColor => titleController.text.toLowerCase() == 'color';

  // Newly added attribute values (key/value only).
  final RxList<String> newValues = <String>[].obs;

  @override
  void initState() {
    super.initState();
    // If already editing color, copy current selections
    if (isColor) {
      localSelectedColors.addAll(widget.controller.selectedColors);
    }
    detailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    titleController.dispose();
    detailController.dispose();
    super.dispose();
  }

  void _addValue() {
    final value = detailController.text.trim();
    if (value.isEmpty) return;
    if (newValues.any((v) => v.toLowerCase() == value.toLowerCase())) return;

    newValues.add(value);
    detailController.clear();
    setState(() {});
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Variant Name Field
                    CommonTextField(
                      title: AppStrings.variantName,
                      hintText: AppStrings.variantNameHint,
                      textEditController: titleController,
                      isValidate: true,
                      onChange: (_) => setState(() {}),
                    ),
                    SizedBox(height: SizeConfig.size20),

                    // Details Section (color picker or free values)
                    isColor ? _buildColorSection() : _buildValueSection(),

                    SizedBox(height: SizeConfig.size20 + 2),

                    _buildSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 10, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.greyE5, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_motion_outlined,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: CustomText(
              AppStrings.addVariant,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(30),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.secondaryTextColor,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Color section ─────────────────────────────────────────────────────────
  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColorSelectionTile(
          controller: widget.controller,
          onSelectedColor: (color, colorName) {
            SelectedColor selectedColor = SelectedColor(color, colorName);
            if (!localSelectedColors.contains(selectedColor)) {
              localSelectedColors.add(selectedColor);
            }
            return SelectedColor(color, colorName);
          },
        ),
        const SizedBox(height: 12),
        Obx(
          () => localSelectedColors.isEmpty
              ? const SizedBox.shrink()
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(localSelectedColors.length, (i) {
                    final selected = localSelectedColors[i];
                    return _accentPill(
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: selected.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.12),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      label: selected.name,
                      onDelete: () => localSelectedColors.remove(selected),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  // ── Free-value section (key + values only) ──────────────────────────────────
  Widget _buildValueSection() {
    final active = detailController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Value input with inline add
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [AppShadows.textFieldShadow],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primaryColor : AppColors.greyE5,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Image.asset("assets/icons/tag_icon.png"),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: TextField(
                  controller: detailController,
                  onSubmitted: (_) => _addValue(),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: AppStrings.enterValue.tr,
                    hintStyle: TextStyle(color: AppColors.grey9B, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: active
                    ? InkWell(
                        key: const ValueKey("add_icon"),
                        onTap: _addValue,
                        child: const Icon(Icons.add_circle_rounded,
                            color: AppColors.primaryColor, size: 28),
                      )
                    : const SizedBox.shrink(key: ValueKey("empty")),
              ),
            ],
          ),
        ),
        // Chips
        Obx(
          () => newValues.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: newValues
                        .map((v) => _accentPill(
                              label: v,
                              onDelete: () => newValues.remove(v),
                            ))
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  // Accent pill used for both selected colors and newly added values.
  Widget _accentPill({
    Widget? leading,
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 8),
          ],
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(Icons.close_rounded,
                size: 16, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(
      () => CustomBtn(
        title: widget.controller.isAddUpdateProductVariantLoading.value
            ? null
            : AppStrings.addVariant,
        isLoading: widget.controller.isAddUpdateProductVariantLoading.value,
        onTap: () async {
          if (!formKey.currentState!.validate()) return;

          final title = titleController.text.trim();

          if (isColor) {
            // ── Color branch (unchanged) ───────────────────────────────────
            if (widget.controller.dynamicAttributes.containsKey(title)) {
              Get.snackbar(
                AppStrings.error.tr,
                AppStrings.attributeExists.tr,
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.redAccent,
                colorText: Colors.white,
              );
              return;
            }
            if (localSelectedColors.isEmpty) {
              Get.snackbar(
                AppStrings.error.tr,
                AppStrings.pickAtLeastOneColor.tr,
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.redAccent,
                colorText: Colors.white,
              );
              return;
            }

            final List<SelectedColor> mergedColors = [
              ...widget.controller.selectedColors.toList(),
              ...localSelectedColors.where(
                (c) => !widget.controller.selectedColors.contains(c),
              ),
            ];

            final success =
                await widget.controller.addUpdateProductVariantApi(
              allColors: mergedColors,
              allDynamicAttributes: widget.controller.dynamicAttributes.map(
                (key, value) => MapEntry(key, value.toList()),
              ),
            );

            if (success) {
              widget.controller.selectedColors.assignAll(mergedColors);
              for (var color in mergedColors) {
                widget.controller.selectVariantValue('color', color);
              }
              widget.controller.selectedColors.refresh();
              Get.back();
            }
          } else {
            // ── Value branch: send just the key/values to the API ───────────
            if (newValues.isEmpty) {
              Get.snackbar(
                AppStrings.error.tr,
                AppStrings.enterValue.tr,
                snackPosition: SnackPosition.TOP,
              );
              return;
            }

            final success = await widget.controller.addAttributeVariantsApi(
              attributeKey: title,
              values: newValues.toList(),
            );

            if (success) Get.back();
          }
        },
        bgColor: AppColors.primaryColor,
        textColor: AppColors.white,
        height: 45,
      ),
    );
  }
}
