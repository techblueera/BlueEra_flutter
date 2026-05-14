import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/health_camp_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/health_camp_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_form_screen.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_soft_card_color.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HealthCampDetailScreen extends StatefulWidget {
  final bool isOwnProfile;
  final String? labId;

  const HealthCampDetailScreen({
    super.key,
    this.isOwnProfile = true,
    this.labId,
  });

  @override
  State<HealthCampDetailScreen> createState() => _HealthCampDetailScreenState();
}

class _HealthCampDetailScreenState extends State<HealthCampDetailScreen> {
  HealthCampController? controller;
  bool _isDescExpanded = false;

  // For another lab's camp (read-only mode).
  HealthCamp? _otherCamp;
  bool _isOtherLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOwnProfile) {
      if (!Get.isRegistered<HealthCampController>()) {
        controller = Get.put(HealthCampController(), permanent: true);
      } else {
        controller = Get.find<HealthCampController>();
      }
      controller!.fetchCampFullDetails();
    } else {
      _fetchOtherUserCamp();
    }
  }

  Future<void> _fetchOtherUserCamp() async {
    setState(() => _isOtherLoading = true);
    try {
      final res = await HealthCampRepo().getHealthCampsByLab(widget.labId!);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        if (data.isNotEmpty && mounted) {
          setState(() => _otherCamp = HealthCamp.fromJson(data.last));
        }
      }
    } catch (e) {
      debugPrint("Error fetching other user camp: $e");
    } finally {
      if (mounted) setState(() => _isOtherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isOwnProfile
        ? _buildOwnProfileScreen()
        : _buildOtherProfileScreen();
  }

  // ---------- Other lab (read-only) ----------------------------------------

  Widget _buildOtherProfileScreen() {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.healthCamp.tr),
      body: _isOtherLoading
          ? const Center(child: CircularProgressIndicator())
          : _otherCamp == null
              ? Center(
                  child: CustomText(
                    AppStrings.noHealthCampsFound.tr,
                    color: AppColors.greyA5,
                  ),
                )
              : _buildCampBody(_otherCamp!),
    );
  }

  // ---------- Own lab (editable) -------------------------------------------

  Widget _buildOwnProfileScreen() {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.healthCamp.tr,
        buildCustomActionWidget: () => Obx(() {
          final camp = controller!.campDetail.value;
          if (camp == null) return const SizedBox.shrink();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22),
                onPressed: () async {
                  await Get.to(() => HealthCampFormScreen(existing: camp));
                  controller!.fetchCampFullDetails();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 22, color: AppColors.red),
                onPressed: () => _showDeleteConfirmation(camp),
              ),
            ],
          );
        }),
      ),
      body: Obx(() {
        if (controller!.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final camp = controller!.campDetail.value;
        if (camp == null) return _buildEmptyOwnState();
        return _buildCampBody(camp);
      }),
    );
  }

  Widget _buildEmptyOwnState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            AppStrings.noHealthCampsFound.tr,
            color: AppColors.greyA5,
          ),
          SizedBox(height: SizeConfig.size16),
          GestureDetector(
            onTap: () async {
              await Get.to(() => const HealthCampFormScreen());
              controller!.fetchCampFullDetails();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size12,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomText(
                AppStrings.createHealthCamp.tr,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampBody(HealthCamp camp) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCampHeader(camp),
          SizedBox(height: SizeConfig.size12),
          if (camp.testDiscounts != null && camp.testDiscounts!.isNotEmpty)
            _buildTestCategoryGroup(camp.title ?? "", camp.testDiscounts!),
        ],
      ),
    );
  }

  // ---------- Sections ------------------------------------------------------

  Widget _buildCampHeader(HealthCamp camp) {
    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (camp.images != null && camp.images!.isNotEmpty)
            _buildImageGallery(camp.images!),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            camp.title ?? "",
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: SizeConfig.size8),
          if (camp.description != null && camp.description!.isNotEmpty) ...[
            CustomText(
              camp.description!,
              fontSize: 13,
              color: AppColors.secondaryTextColor,
              maxLines: _isDescExpanded ? null : 3,
            ),
            if (camp.description!.length > 120)
              GestureDetector(
                onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                child: Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size4),
                  child: CustomText(
                    _isDescExpanded
                        ? AppStrings.readLess.tr
                        : AppStrings.readMore.tr,
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: SizeConfig.size8),
          ],
          if (camp.location?.name != null && camp.location!.name!.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size4),
                Expanded(
                  child: CustomText(
                    camp.location!.name!,
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          SizedBox(height: SizeConfig.size12),
          _buildDateTimeSection(camp),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: images[index],
              width: 240,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 240,
                height: 180,
                color: AppColors.greyE5,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 240,
                height: 180,
                color: AppColors.greyE5,
                child: const Icon(Icons.broken_image_outlined,
                    size: 40, color: AppColors.greyA5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeSection(HealthCamp camp) {
    // The HealthCamp model currently exposes only `startTime`, so both boxes
    // surface that value; swap to `camp.endTime` once the model gains it.
    final time = camp.startTime ?? '';
    return Row(
      children: [
        Expanded(
          child: _buildDateTimeBox(
            label: AppStrings.labStartDate.tr,
            date: _formatDate(camp.startDate),
            time: time,
          ),
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: _buildDateTimeBox(
            label: AppStrings.labEndDate.tr,
            date: _formatDate(camp.endDate),
            time: time,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeBox({
    required String label,
    required String date,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              Flexible(
                child: CustomText(
                  date,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CustomText(" • ", fontSize: 14, color: Colors.grey),
              CustomText(
                time,
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestCategoryGroup(String title, List<TestDiscount> discounts) {
    if (discounts.isEmpty) return const SizedBox.shrink();

    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: SizeConfig.size16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: discounts.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size16),
            itemBuilder: (_, index) {
              final item = discounts[index];
              return Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade600, size: 24),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CustomText(
                      item.test?.testName ?? "N/A",
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showTestDetailsDialog(context, item),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.visibility_outlined,
                          color: Colors.blue.shade600, size: 20),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTestDetailsDialog(BuildContext context, TestDiscount discount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomText(
                discount.test?.testName ?? AppStrings.labTestDetails.tr,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: _buildTestCard(discount),
      ),
    );
  }

  Widget _buildTestCard(TestDiscount discount) {
    final test = discount.test;
    if (test == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: LabSoftCardColor.forKey(test.testName),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            test.testName ?? "",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (test.description != null && test.description!.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size4),
            CustomText(
              test.description!,
              fontSize: 11,
              color: Colors.grey.shade600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.grey.shade300, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pill(
                "${AppStrings.labReportsWithinPrefix.tr} ${test.estimatedReportHours ?? 24} ${AppStrings.labHrsSuffix.tr}",
                Colors.white,
              ),
              if (test.customerPrice != null)
                _pill(
                  "${AppStrings.labInrSpace.tr}${test.customerPrice}",
                  Colors.white,
                  isBold: true,
                ),
            ],
          ),
          if ((discount.discountValue ?? 0) > 0) ...[
            SizedBox(height: SizeConfig.size8),
            _pill(
              "${discount.discountValue}% ${discount.discountType ?? 'percentage'} off",
              AppColors.primaryColor.withValues(alpha: 0.1),
              textColor: AppColors.primaryColor,
              isBold: true,
            ),
          ],
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.grey),
              const SizedBox(width: 8),
              CustomText(
                "${test.specimen ?? 'Blood'} sample collection",
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bgColor,
      {bool isBold = false, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomText(
        text,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
        fontSize: 11,
        color: textColor,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _showDeleteConfirmation(HealthCamp camp) {
    showCommonDialog(
      context: context,
      text: AppStrings.confirmDeleteCamp.tr,
      confirmCallback: () async {
        Get.back();
        await controller?.deleteCamp(camp.id ?? "");
        controller?.fetchCampFullDetails();
      },
      cancelCallback: () => Get.back(),
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
    );
  }
}
