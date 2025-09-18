import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<List<Map<String, dynamic>>?> showCategoryBottomSheet(BuildContext context) async {
  final controller = Get.put(ManualListingScreenController());
  controller.reset();

  final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) {
      return Obx(() {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                     CustomText(
                        "Category",
                        color: AppColors.mainTextColor,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppConstants.OpenSans,
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              CommonHorizontalDivider(
                color: AppColors.whiteE5,
              ),

              // --- Breadcrumb ---
              if (controller.breadcrumb.isNotEmpty)
                Container(
                  width: SizeConfig.screenWidth,
                  padding: EdgeInsets.all(SizeConfig.size12),
                  margin: EdgeInsets.all(SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: AppColors.white, 
                    boxShadow: [AppShadows.textFieldShadow],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.greyE5,
                      width: 1.5
                    )
                  ),
                  child: Wrap(
                    children: List.generate(
                      controller.breadcrumb.length,
                          (i) {
                        final item = controller.breadcrumb[i];
                        final isLast = i == controller.breadcrumb.length - 1;

                        return InkWell(
                          onTap: () => controller.goToBreadcrumb(i),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText(
                                item['name'],
                                color: isLast ? AppColors.mainTextColor : AppColors.primaryColor,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppConstants.OpenSans,
                              ),
                              if (!isLast)
                                const Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              Expanded(
                child: controller.loading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                  itemCount: controller.categories.length,
                  separatorBuilder: (_, __) =>
                  CommonHorizontalDivider(
                      color: AppColors.whiteE5,
                  ),
                  itemBuilder: (_, index) {
                    final cat = controller.categories[index];
                    return ListTile(
                      title: CustomText(
                          cat.name??'',
                          color: AppColors.mainTextColor,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppConstants.OpenSans,

                      ),
                      trailing: (cat.root??false) ? PositiveCustomBtn(
                        onTap: () {
                          controller.breadcrumb.add({'id': cat.sId??'', 'name': cat.name});
                          Navigator.pop(context, controller.breadcrumb);
                        },
                        title: 'Select',
                        width: SizeConfig.size60,
                        height: SizeConfig.size30,
                        bgColor: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderColor: AppColors.primaryColor,
                        textColor: AppColors.primaryColor,
                        radius: 10.0,
                      )
                          : const Icon(Icons.arrow_forward_ios,
                           size: 14),
                      onTap: () => controller.selectCategory(cat),
                    );
                  },
                ),
              ),

              // --- Back Button ---
              if (controller.breadcrumb.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size12,
                      right: SizeConfig.size12,
                      top: SizeConfig.size12,
                      bottom: SizeConfig.size30,
                  ),
                  child: PositiveCustomBtn(
                    onTap: () {
                      final lastIndex = controller.breadcrumb.length - 2;
                      if (lastIndex >= 0) {
                        controller.goToBreadcrumb(lastIndex);
                      } else {
                        controller.reset();
                      }
                    },
                    title: 'Back',
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    radius: 10.0,
                  ),
                ),

            ],
          ),
        );
      });
    },
  );

  return result;
}
