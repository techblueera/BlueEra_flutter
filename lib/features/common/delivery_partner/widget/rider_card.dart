import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/model/GetBlueeraPiolotModel.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/custom_btn.dart';

class RiderCard extends StatelessWidget {
  final Riders rider;

  const RiderCard({
    super.key,
    required this.rider,
  });

  @override
  Widget build(BuildContext context) {

    return CustomFormCard(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      child: SizedBox(
        height: SizeConfig.size180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Rider Image ---
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                rider.user?.profileImage ?? '',
                height: SizeConfig.size180,
                width: SizeConfig.size140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: SizeConfig.size180,
                  width: SizeConfig.size140,
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // --- 2. Rider Details Column ---
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      CustomText(
                        rider.user?.name ?? 'Unknown Rider',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      const SizedBox(height: 8),

                      // Badge Row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildBadge(
                            icon: Icons.star,
                            text: "${rider.riderData?.ratings?.average ?? '0.0'}",
                            bgColor: const Color(0xFFFDF6E3),
                            iconColor: AppColors.rating,
                            textColor: AppColors.blue2D,
                          ),
                          _buildBadge(
                            icon: Icons.location_on_outlined,
                            text: rider.distance ?? "0.0 km",
                            bgColor: const Color(0xFFE7F5EE),
                            iconColor: AppColors.greenShade,
                            textColor: AppColors.greenShade,
                          ),
                          _buildBadge(
                            icon: Icons.storefront_outlined,
                            text: "12 stores",
                            bgColor: const Color(0xFFEFF4FF),
                            iconColor: const Color(0xFF2C47A8),
                            textColor: const Color(0xFF2C47A8),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      DashedBorderContainer(
                        borderColor: AppColors.greyE5,
                        strokeWidth: 1,
                        dashLength: 2,
                        child: SizedBox(
                          height: 1,
                          width: double.maxFinite,
                        ),
                      ),


                      const SizedBox(height: 10),

                      // Address Gray Box
                      _buildAddressBox(
                          rider.riderData?.address?.streetAddress ?? "Address not available"
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // --- 3. Footer Actions ---
                  _buildFooter(context),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Private UI Helpers ---

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor,
          width: 0.5
        )
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          CustomText(
            text,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBox(String address) {
    return CustomFormCard(
      padding: const EdgeInsets.all(8.0),
      color: const Color(0xFFFAFBFC),
      border: Border.all(
        color: AppColors.greyE5
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.location_outline,
            imgColor: AppColors.secondaryTextColor,
            height: 20,
            width: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              address,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // View Profile Link
        InkWell(
          onTap: () {
            if(rider.userId==null) return;
            Get.to(() => NewVisitProfileScreen(
              authorId: rider.userId??'',
              screenFromName: RouteConstant.nearByRidersScreen,
            ));
          },
          child: Row(
            children: [
              CustomText(
                "View Full Profile",
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primaryColor),
            ],
          ),
        ),

        // Action Button
        CustomBtn(
          height: 30,
          width: 100,
          onTap: () {
            // Chat
          },
          title: "Request To Link",
          bgColor: AppColors.primaryColor,
          radius: 6.0,
        ),
      ],
    );
  }
}