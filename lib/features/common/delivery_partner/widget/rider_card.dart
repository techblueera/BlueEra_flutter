import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/model/GetBlueeraPiolotModel.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/custom_btn.dart';

// ─── Status enum ───
enum AssociationStatus {
  pending,
  accepted,
  rejected,
  expired,
  dissociated,
  none; // null = no association

  static AssociationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return AssociationStatus.pending;
      case 'accepted':
        return AssociationStatus.accepted;
      case 'rejected':
        return AssociationStatus.rejected;
      case 'expired':
        return AssociationStatus.expired;
      case 'dissociated':
        return AssociationStatus.dissociated;
      default:
        return AssociationStatus.none;
    }
  }
}

class RiderCard extends StatelessWidget {
  final Riders rider;

  const RiderCard({
    super.key,
    required this.rider,
  });

  AssociationStatus get _status =>
      AssociationStatus.fromString(rider.associationStatus);

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
                            text:
                                "${rider.riderData?.ratings?.average ?? '0.0'}",
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
                          rider.riderData?.address?.streetAddress ??
                              "Address not available"),
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
          border: Border.all(color: bgColor, width: 0.5)),
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
      border: Border.all(color: AppColors.greyE5),
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
            if (rider.userId == null) return;
            Get.to(() => NewVisitProfileScreen(
                  authorId: rider.userId ?? '',
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
              const Icon(Icons.arrow_forward_ios,
                  size: 10, color: AppColors.primaryColor),
            ],
          ),
        ),

        _buildStatusButton(context),
      ],
    );
  }

  Widget _buildStatusButton(BuildContext context) {
    switch (_status) {
      // ✅ No association — show Request button
      case AssociationStatus.none:
        return CustomBtn(
          height: 30,
          width: 110,
          onTap: () {
            // send request
          },
          title: "Request To Link",
          bgColor: AppColors.primaryColor,
          radius: 6.0,
        );

      // ⏳ Pending — show waiting state
      case AssociationStatus.pending:
        return _buildStatusChip(
          label: 'Pending',
          icon: Icons.hourglass_top_rounded,
          bgColor: const Color(0xFFFFF8E1),
          textColor: const Color(0xFFE65100),
          iconColor: const Color(0xFFE65100),
          onTap: null, // non-tappable
        );

      // ✅ Accepted — show linked state
      case AssociationStatus.accepted:
        return _buildStatusChip(
          label: 'Linked',
          icon: Icons.check_circle_outline_rounded,
          bgColor: const Color(0xFFE8F5E9),
          textColor: AppColors.greenShade,
          iconColor: AppColors.greenShade,
          onTap: null,
        );

      // ❌ Rejected — allow re-request
      case AssociationStatus.rejected:
        return CustomBtn(
          height: 30,
          width: 110,
          onTap: () {
            // re-send request
          },
          title: "Re-Request",
          bgColor: AppColors.redB4,
          radius: 6.0,
        );

      // 🔁 Expired — allow re-request
      case AssociationStatus.expired:
        return CustomBtn(
          height: 30,
          width: 110,
          onTap: () {
            // re-send request
          },
          title: "Re-Request",
          bgColor: const Color(0xFF9E9E9E),
          radius: 6.0,
        );

      // 🔗 Dissociated — allow re-link
      case AssociationStatus.dissociated:
        return CustomBtn(
          height: 30,
          width: 110,
          onTap: () {
            // re-link
          },
          title: "Re-Link",
          bgColor: AppColors.primaryColor,
          radius: 6.0,
        );
    }
  }

  // ✅ non-tappable status chip
  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            CustomText(
              label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}
