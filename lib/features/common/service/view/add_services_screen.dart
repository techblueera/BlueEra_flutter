import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/service/controller/add_service_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/add_more_details_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/local_assets.dart';

class AddServicesScreenNew extends StatefulWidget {
  const AddServicesScreenNew({Key? key}) : super(key: key);

  @override
  State<AddServicesScreenNew> createState() => _AddServicesScreenState();
}

class _AddServicesScreenState extends State<AddServicesScreenNew> {
  late AddServiceController addServiceController;
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    addServiceController = getOrPut(() => AddServiceController());
    addServiceController.consumePendingEdit();
  }

  bool get _isEditMode =>
      (addServiceController.serviceId ?? '').isNotEmpty;

  @override
  void dispose() {
    deleteIfRegistered<AddServiceController>();
    super.dispose();
  }

  static const _accent = LinearGradient(
    colors: [AppColors.blue5CAF, AppColors.primaryColor],
  );

  bool get _isIndividual => accountTypeGlobal == AppConstants.individual;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        title: addServiceController.serviceNameCtrl.text.isEmpty
            ? AppStrings.service
            : addServiceController.serviceNameCtrl.text,
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size12,
            SizeConfig.size12,
            SizeConfig.size12,
            SizeConfig.size16,
          ),
          child: Form(
            key: addServiceController.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: SizeConfig.size12),
                _buildContextCard(),
                SizedBox(height: SizeConfig.size12),

                // ── Service details ──────────────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        Icons.image_outlined,
                        AppStrings.uploadImages,
                        trailing: _pill("Min 2 / Max 5"),
                      ),
                      SizedBox(height: SizeConfig.size12),
                      _buildImageStrip(context),
                      SizedBox(height: SizeConfig.size20),

                      _sectionHeader(
                          Icons.design_services_outlined,
                          AppStrings.serviceName),
                      SizedBox(height: SizeConfig.size10),
                      CommonTextField(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          title: '',
                          hintText: AppStrings.hintServiceName,
                          textEditController:
                              addServiceController.serviceNameCtrl,
                          validator: addServiceController.validateServiceName,
                          maxLength: 100,
                          isValidate: true,
                          isCounterVisible: true),
                      SizedBox(height: SizeConfig.size20),

                      _sectionHeader(
                          Icons.checklist_rounded, AppStrings.facilities),
                      SizedBox(height: SizeConfig.size10),
                      _buildFacilityInput(),
                      const SizedBox(height: 12),
                      Obx(() => Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: addServiceController.facilities
                                .map((facility) => _facilityChip(facility))
                                .toList(),
                          )),
                      SizedBox(height: SizeConfig.size20),

                      _sectionHeader(
                          Icons.notes_outlined, AppStrings.serviceDescription),
                      SizedBox(height: SizeConfig.size10),
                      CommonTextField(
                          title: '',
                          hintText: AppStrings.hintServiceDescription,
                          textEditController:
                              addServiceController.descriptionCtrl,
                          maxLine: 4,
                          validator:
                              addServiceController.validateServiceDescription,
                          maxLength: 600,
                          isCounterVisible: true),
                      SizedBox(height: SizeConfig.size20),

                      _sectionHeader(
                          Icons.schedule_outlined, AppStrings.timing),
                      SizedBox(height: SizeConfig.size12),
                      _timingSection(),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size12),

                // ── Pricing ──────────────────────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                          Icons.sell_outlined, AppStrings.price),
                      SizedBox(height: SizeConfig.size12),
                      _priceSection(),
                      SizedBox(height: SizeConfig.size20),
                      _sectionHeader(Icons.local_offer_outlined,
                          AppStrings.discount,
                          optional: true),
                      _discountSection(),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size12),

                // ── Booking & extra details ──────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.event_available_outlined,
                          AppStrings.minimumBookingAmount,
                          optional: true),
                      SizedBox(height: SizeConfig.size10),
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        title: '',
                        hintText: AppStrings.egRs300,
                        textEditController: addServiceController.minBookingCtrl,
                        keyBoardType: TextInputType.number,
                        regularExpression: RegularExpressionUtils.digitsPattern,
                        isValidate: false,
                      ),
                      SizedBox(height: SizeConfig.size20),
                      _buildDetailsSection(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO — gradient banner.
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14, vertical: SizeConfig.size12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _accent,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -22,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Icon(
                    _isEditMode
                        ? Icons.edit_note_rounded
                        : Icons.design_services_outlined,
                    color: Colors.white,
                    size: 19),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      _isEditMode
                          ? 'Update your service'
                          : 'Finish setting up your service',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      'Add photos, pricing and timings to go live',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CONTEXT CARD — profile bits we reuse; warn only if missing.
  // ─────────────────────────────────────────────────────────────
  Widget _buildContextCard() {
    const amber = Color(0xFFB45309);
    final title = _isIndividual
        ? AppStrings.yourProfessionDesignation
        : AppStrings.yourCategorySubcategory;
    final showWarning = _isIndividual
        ? (userProfessionGlobal.trim().isEmpty ||
            userDesignationGlobal.trim().isEmpty)
        : (businessCategoryGlobal.trim().isEmpty ||
            businessSubCategoryGlobal.trim().isEmpty);

    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6DDB0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 17, color: amber),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C4A06),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (_isIndividual) ...[
            _kvRow(AppStrings.profession, userProfessionGlobal),
            _kvRow(AppStrings.workType, userDesignationGlobal),
          ] else ...[
            _kvRow(AppStrings.category.tr, businessCategoryGlobal),
            _kvRow(AppStrings.subCategory, businessSubCategoryGlobal),
          ],
          if (showWarning) ...[
            SizedBox(height: SizeConfig.size6),
            Container(height: 1, color: const Color(0xFFF1DFC0)),
            SizedBox(height: SizeConfig.size8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: AppColors.red00),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: CustomText(
                    _isIndividual
                        ? AppStrings.kindlyAddServicesProfession
                        : AppStrings.kindlyAddServicesCategory,
                    color: AppColors.red00,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9A7B45),
            ),
          ),
          Expanded(
            child: CustomText(
              value.trim().isEmpty ? '—' : value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B4A14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Reusable bits.
  // ─────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12001120),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title,
      {bool optional = false, Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: CustomText(
            title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ),
        if (optional) ...[
          SizedBox(width: SizeConfig.size8),
          _pill('Optional'),
        ],
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.greyE5.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        text,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  // ─── Image strip — rounded square slots, tap to add, badge to remove ───
  Widget _buildImageStrip(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
        itemBuilder: (context, imgIdx) {
          return GestureDetector(
            key: ValueKey('img_$imgIdx'),
            onTap: () {
              final total = addServiceController.existingPhotoUrls.length +
                  addServiceController.imageLocalPaths.length;
              if (total >= 5) {
                commonSnackBar(message: AppStrings.limitReachedImages.tr);
              } else {
                addServiceController.pickImages(context);
              }
            },
            child: Obx(() {
              final urls = addServiceController.existingPhotoUrls;
              final locals = addServiceController.imageLocalPaths;
              final isRemote = imgIdx < urls.length;
              final localIdx = imgIdx - urls.length;
              final hasLocal = !isRemote && localIdx < locals.length;
              final hasImage = isRemote || hasLocal;
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: hasImage
                      ? AppColors.whiteFE
                      : AppColors.primaryColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasImage
                        ? AppColors.greyE5
                        : AppColors.primaryColor.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isRemote)
                      Image.network(
                        urls[imgIdx],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.grey9B),
                        ),
                      )
                    else if (hasLocal)
                      Image.file(File(locals[localIdx]), fit: BoxFit.cover)
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 22,
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.7)),
                            const SizedBox(height: 4),
                            CustomText(
                              imgIdx == 0 ? 'Add' : '',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    if (hasImage)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            if (isRemote) {
                              urls.removeAt(imgIdx);
                            } else {
                              addServiceController.removeImageAt(localIdx);
                            }
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildFacilityInput() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteFE,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        children: [
          Image.asset("assets/icons/tag_icon.png"),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: TextField(
              controller: addServiceController.facilitiesCtrl,
              onChanged: (_) => addServiceController.update(["addIcon"]),
              decoration: InputDecoration(
                hintText: AppStrings.facility.tr,
                hintStyle: TextStyle(color: AppColors.grey9B, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          GetBuilder<AddServiceController>(
            id: "addIcon",
            builder: (_) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: addServiceController.facilitiesCtrl.text.isNotEmpty
                    ? InkWell(
                        key: const ValueKey("add"),
                        onTap: () {
                          addServiceController.addFacility();
                          addServiceController.update(["addIcon"]);
                          unFocus();
                        },
                        child: LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                      )
                    : const SizedBox.shrink(key: ValueKey("empty")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _facilityChip(String facility) {
    return Chip(
      label: Text(facility),
      backgroundColor: AppColors.lightBlue,
      labelStyle:
          TextStyle(fontSize: SizeConfig.size14, color: Colors.black87),
      deleteIcon:
          const Icon(Icons.close, size: 20, color: AppColors.mainTextColor),
      shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8.0)),
      onDeleted: () => addServiceController.removeFacility(facility),
      labelPadding: const EdgeInsets.only(left: 12),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => addServiceController.detailsList.isNotEmpty
            ? Column(
                children: List.generate(
                  addServiceController.detailsList.length,
                  (index) {
                    final item = addServiceController.detailsList[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0) ...[
                            _sectionHeader(
                                Icons.list_alt_outlined, AppStrings.details),
                            SizedBox(height: SizeConfig.size12),
                          ],
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      boxShadow: [AppShadows.textFieldShadow],
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: AppColors.greyE5)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              item.title,
                                              fontSize: SizeConfig.large,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mainTextColor,
                                            ),
                                            const SizedBox(height: 4),
                                            CustomText(
                                              item.details,
                                              fontSize: SizeConfig.medium,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  AppColors.secondaryTextColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                  right: 6,
                                  top: -15,
                                  child: InkWell(
                                    onTap: () => addServiceController
                                        .removeDetail(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: AppColors.white,
                                          boxShadow: [
                                            AppShadows.textFieldShadow
                                          ],
                                          border:
                                              Border.all(color: AppColors.greyE5),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 18),
                                    ),
                                  ))
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : const SizedBox.shrink()),
        InkWell(
          onTap: () => showAddMoreDetailsDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14, vertical: SizeConfig.size12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primaryColor),
                  child: const Center(
                      child: Icon(CupertinoIcons.add,
                          color: Colors.white, size: 20)),
                ),
                SizedBox(width: SizeConfig.size12),
                CustomText(
                  AppStrings.addMoreDetails,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STICKY BOTTOM BAR — gradient Post / Update CTA.
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.greyE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size12),
          child: GestureDetector(
            onTap: () {
              if (_isEditMode) {
                addServiceController.updateServiceApi();
              } else {
                addServiceController.createServiceApi();
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: _accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        _isEditMode
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 19),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      _isEditMode
                          ? AppStrings.update
                          : AppStrings.postService,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText('Working hours',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor),
            Obx(() => RadioGroup<bool>(
                  groupValue: addServiceController.isSpecial.value,
                  onChanged: (val) =>
                      addServiceController.isSpecial.value = val ?? false,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity:
                              const VisualDensity(horizontal: -4, vertical: -4),
                          value: false,
                          title: const CustomText(AppStrings.defaultTiming, fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity:
                              const VisualDensity(horizontal: -4, vertical: -4),
                          value: true,
                          title: const CustomText(AppStrings.specialTiming, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ),

        SizedBox(height: SizeConfig.size8),

        // Start and End Time Dropdowns
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildDropdown(
                    hint: AppStrings.startTime,
                    value: addServiceController.startTime.value,
                    items: addServiceController.timeSlots,
                    onChanged: (val) =>
                        addServiceController.startTime.value = val!,
                  )),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Obx(() => _buildDropdown(
                    hint: AppStrings.endTime,
                    value: addServiceController.endTime.value,
                    items: addServiceController.timeSlots,
                    onChanged: (val) =>
                        addServiceController.endTime.value = val!,
                  )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: value.isEmpty ? null : value,
          hint: Text(hint,
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          style: TextStyle(color: Colors.black87, fontSize: 14),
          items: items.map((String t) {
            return DropdownMenuItem<String>(
              value: t,
              child: Text(t),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _priceSection() {
    return Obx(() => Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText('Price type',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor),
              RadioGroup<bool>(
                groupValue: addServiceController.isRange.value,
                onChanged: (val) =>
                    addServiceController.isRange.value = val ?? false,
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                        value: false,
                        title: CustomText(
                          AppStrings.fixedPrice,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                        value: true,
                        title: CustomText(AppStrings.rangePrice, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          addServiceController.isRange.isTrue
              ? Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        hintText: "${AppStrings.min} - ₹300",
                        textEditController: addServiceController.minPriceCtrl,
                        keyBoardType: TextInputType.number,
                        validator: (value) => ValidationMethod()
                            .validateMinPrice(
                                value, addServiceController.maxPriceCtrl),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: CommonTextField(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        hintText: "${AppStrings.max.tr} - ₹800",
                        textEditController: addServiceController.maxPriceCtrl,
                        keyBoardType: TextInputType.number,
                        validator: (value) => ValidationMethod()
                            .validateMaxPrice(
                                value, addServiceController.minPriceCtrl),
                      ),
                    ),
                  ],
                )
              : CommonTextField(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  hintText: AppStrings.egRs300,
                  textEditController: addServiceController.priceCtrl,
                  keyBoardType: TextInputType.number,
                  validator: addServiceController.validateAmount,
                ),
          SizedBox(height: SizeConfig.size20),
          CommonTextField(
            title: AppStrings.perUnit,
            // contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            hintText: AppStrings.hintPerUnit,
            textEditController: addServiceController.perUnitCtrl,
            regularExpression: RegularExpressionUtils.alphabetPatternSpace,
            maxLength: 10,
          ),
        ]));
  }

  Widget _discountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SizeConfig.size10,
        ),
        Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                addServiceController.coupons.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: [AppShadows.textFieldShadow],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.greyE5,
                            )),
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: CustomText(
                            AppStrings.discountCoupon,
                            fontFamily: "Arial",
                          ),
                          trailing: const Icon(CupertinoIcons.chevron_forward),
                          onTap: () {
                            showDiscountCouponDialog(context);
                          },
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: List.generate(
                          addServiceController.coupons.length,
                          (index) {
                            final coupon = addServiceController.coupons[index];

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size12,
                                      vertical: SizeConfig.size15),
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      boxShadow: [AppShadows.textFieldShadow],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.greyE5,
                                      )),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              "Discount worth ₹${coupon.totalOff.toStringAsFixed(0)} T&Cs",
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mainTextColor,
                                            ),
                                            SizedBox(height: 6),
                                            CustomText(coupon.description,
                                                fontSize: SizeConfig.small,
                                                color: AppColors
                                                    .secondaryTextColor,
                                                fontWeight: FontWeight.w400),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                DottedBorder(
                                                  borderType: BorderType.RRect,
                                                  radius: Radius.circular(6),
                                                  dashPattern: [6, 3],
                                                  // 6px dash, 3px gap
                                                  color: Colors.green,
                                                  strokeWidth: 1.0,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6),
                                                    child: CustomText(
                                                        coupon.codeName ??
                                                            "N/A",
                                                        fontSize:
                                                            SizeConfig.small,
                                                        color: AppColors
                                                            .mainTextColor,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                CustomText(
                                                    coupon.discountType ==
                                                            DiscountType
                                                                .inPercentage
                                                        ? "${coupon.totalOff}% Off"
                                                        : "₹${coupon.totalOff} Off",
                                                    fontSize: SizeConfig.small,
                                                    color: AppColors.green7F,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),

                                      // Right side - Icon
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.white,
                                            border: Border.all(
                                                color: AppColors.primaryColor,
                                                width: 1.1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                offset: const Offset(0, 1),
                                                blurRadius: 2,
                                                spreadRadius: 0,
                                              )
                                            ]),
                                        child: Icon(
                                          Icons.percent,
                                          color: AppColors.orange27,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    right: 6,
                                    top: -6,
                                    child: InkWell(
                                      onTap: () => addServiceController
                                          .removeCoupon(index),
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: AppColors.white,
                                            boxShadow: [
                                              AppShadows.textFieldShadow
                                            ],
                                            border: Border.all(
                                              color: AppColors.greyE5,
                                            ),
                                            shape: BoxShape.circle),
                                        child: Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                      ),
                                    ))
                              ],
                            );
                          },
                        ),
                      ),
                SizedBox(
                  height: SizeConfig.size8,
                ),
                if (addServiceController.coupons.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDiscountCouponDialog(context);
                        },
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.add,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            const CustomText(
                              "Add More Coupon",
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
              ],
            ))
      ],
    );
  }


  Future<void> showAddMoreDetailsDialog(BuildContext context) async {
    if (addServiceController.detailsList.length == 5) {
      commonSnackBar(message: AppStrings.cantAddMoreThanFive.tr);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          AddMoreDetailsDialog(fromScreen: RouteConstant.addServicesScreen),
    );
  }
}

void showAddMoreDetailsDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                AppStrings.addMoreDetails,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              const SizedBox(height: 20),

              // Title Field
              CommonTextField(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                title: AppStrings.title,
                hintText: AppStrings.egSize,
                textEditController: titleCtrl,
              ),
              const SizedBox(height: 16),

              // Details Field
              CommonTextField(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                title: AppStrings.details,
                hintText: AppStrings.egWirelessEarbudsBox,
                textEditController: detailsCtrl,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.paddingM,
                    ),
                  ),
                  onPressed: () {
                    // handle save
                    Navigator.pop(context);
                  },
                  child: const CustomText(
                    "Save",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showDiscountCouponDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final couponNameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final codeNameCtrl = TextEditingController();
  final totalOffCtrl = TextEditingController();
  String selectedType = "percentage"; // or "rupees"

  // --- VALIDATIONS ---

  String? validateCouponName(String? value) {
    if (value == null || value.isEmpty) return 'Coupon name is required';
    if (value.length < 3) return 'Coupon name must be at least 3 characters';
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'Description is required';
    if (value.length < 10) return 'Description must be at least 10 characters';
    return null;
  }

  String? validateTotalOff(String? value, String type) {
    if (value == null || value.isEmpty) {
      return "Enter a discount value";
    }
    final num? discount = num.tryParse(value);
    if (discount == null) return "Enter a valid number";

    if (type == "rupees") {
      if (discount <= 0) return "Discount must be greater than 0 ₹";
    } else if (type == "percentage") {
      if (discount <= 0 || discount > 100) {
        return "Discount % must be between 1 and 100";
      }
    }
    return null;
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                            "Discount Coupon",
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          IconButton(
                            onPressed: () {
                              Get.back();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.mainTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Coupon Name
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        title: AppStrings.couponName,
                        hintText: AppStrings.egCouponName,
                        textEditController: couponNameCtrl,
                        validator: validateCouponName,
                        maxLength: 30,
                        isCounterVisible: true,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        title: AppStrings.descriptionTerms,
                        hintText:
                            AppStrings.hintDescriptionTerms,
                        textEditController: descriptionCtrl,
                        validator: validateDescription,
                        maxLength: 200,
                        isCounterVisible: true,
                      ),
                      const SizedBox(height: 16),

                      // Code Name
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        title: AppStrings.codeNameOptional,
                        hintText: AppStrings.egCouponName,
                        textEditController: codeNameCtrl,
                        isValidate: false,
                      ),
                      const SizedBox(height: 16),

                      // Total Off with radio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                            AppStrings.totalOff,
                            fontWeight: FontWeight.w500,
                          ),
                          RadioGroup<String>(
                            groupValue: selectedType,
                            onChanged: (val) {
                              setState(() {
                                selectedType = val!;
                              });
                            },
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: "rupees",
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                    ),
                                    const CustomText(
                                      AppStrings.inRupees,
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: "percentage",
                                      visualDensity: const VisualDensity(
                                          horizontal: -4, vertical: -4),
                                    ),
                                    const CustomText(
                                      AppStrings.inPercentage,
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Total Off input
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        hintText:
                            selectedType == "rupees" ? AppStrings.egRs300 : AppStrings.egPer10,
                        textEditController: totalOffCtrl,
                        validator: (value) =>
                            validateTotalOff(value, selectedType),
                        keyBoardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.paddingM,
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final coupon = DiscountCoupon(
                                couponName: couponNameCtrl.text,
                                description: descriptionCtrl.text,
                                codeName: codeNameCtrl.text.isEmpty
                                    ? null
                                    : codeNameCtrl.text,
                                totalOff:
                                    double.tryParse(totalOffCtrl.text) ?? 0,
                                discountType: selectedType == 'rupees'
                                    ? DiscountType.inRupees
                                    : DiscountType.inPercentage,
                              );

                              Get.put(AddServiceController()).addCoupon(coupon);

                              Get.back();
                              Get.snackbar(AppStrings.success, AppStrings.couponSaved.tr);

                            }
                          },
                          child: const CustomText(
                            AppStrings.save,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

enum DiscountType { inRupees, inPercentage }

class DiscountCoupon {
  final String couponName;
  final String description;
  final String? codeName; // optional
  final double totalOff;
  final DiscountType discountType;

  DiscountCoupon({
    required this.couponName,
    required this.description,
    this.codeName,
    required this.totalOff,
    required this.discountType,
  });

  // CopyWith method
  DiscountCoupon copyWith({
    String? couponName,
    String? description,
    String? codeName,
    double? totalOff,
    DiscountType? discountType,
  }) {
    return DiscountCoupon(
      couponName: couponName ?? this.couponName,
      description: description ?? this.description,
      codeName: codeName ?? this.codeName,
      totalOff: totalOff ?? this.totalOff,
      discountType: discountType ?? this.discountType,
    );
  }

  // From JSON
  factory DiscountCoupon.fromJson(Map<String, dynamic> json) {
    return DiscountCoupon(
      couponName: json['name'] ?? '',
      description: json['description'] ?? '',
      codeName: json['codeName'],
      totalOff: (json['totalOff'] ?? 0).toDouble(),
      discountType: json['type'] == 'flat'
          ? DiscountType.inRupees
          : DiscountType.inPercentage,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'name': couponName,
      'description': description,
      'codeName': codeName,
      'totalOff': totalOff,
      'type': discountType == DiscountType.inRupees ? 'flat' : 'percentage',
    };
  }
}
