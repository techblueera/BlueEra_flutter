import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/school_contact_us.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_contact_us_res_model.dart';

/// School "Contact Us" section — visual language matches
/// [BusinessContactMapCard]: outer `CustomFormCard` with title + Update
/// pill, inner white containers with the shared greyE5 border and
/// text-field shadow, and row items that use LocalAssets icons at
/// 20px + `AppColors.secondaryTextColor` with the same 12px spacing and
/// 15pt label style.
///
/// Schools can have multiple branches with departments underneath, so
/// each branch is rendered as its own inner container (mirroring the
/// business card's single inner container) with departments listed as
/// contact rows separated by thin dividers.
class ContactUsSection extends StatelessWidget {
  final List<Contacts> contacts;
  final bool isEdit;

  const ContactUsSection({
    super.key,
    required this.contacts,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + Update pill (mirrors the business card header) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.contactUs.tr,
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w600,
              ),
              if (isEdit) _updatePill(() => Get.to(SchoolContactUs())),
            ],
          ),
          const SizedBox(height: 10),
          if (contacts.isEmpty)
            _emptyState()
          else
            ...contacts.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _branchCard(c),
                )),
        ],
      ),
    );
  }

  Widget _branchCard(Contacts contact) {
    final website = (contact.branch?.website ?? '').trim();
    final departments = contact.departments ?? const <Departments>[];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.greyE5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Branch name (styled like the business name in the reference) ──
          CustomText(
            contact.branch?.name ?? AppStrings.na,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextColor,
          ),
          const Divider(color: AppColors.greyE5, height: 30),

          // ── Website row (only when set) ──
          if (website.isNotEmpty) _websiteItem(website),

          // ── Departments — each rendered as a group of contact rows ──
          for (int i = 0; i < departments.length; i++) ...[
            _contactItem(
              AppIconAssets.principal,
              departments[i].department ?? AppStrings.na,
            ),
            _contactItem(
              AppIconAssets.email,
              departments[i].email ?? AppStrings.na,
            ),
            _contactItem(
              AppIconAssets.phone_outline,
              departments[i].phone ?? AppStrings.na,
            ),
            if (i != departments.length - 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.greyE5,
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Website row uses the material language icon rendered at the same size
  // and colour as the LocalAssets icons so the left rail stays uniform.
  Widget _websiteItem(String website) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.language_outlined,
            size: 20,
            color: AppColors.secondaryTextColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              website,
              fontSize: 15,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: AppColors.secondaryTextColor,
            height: 20,
            width: 20,
            boxFix: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              label,
              fontSize: 15,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Small outlined pill in the top-right — same shape/colour treatment as
  /// the "Update" chip in [BusinessContactMapCard].
  Widget _updatePill(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: CustomText(
          AppStrings.edit.tr,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.greyE5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        children: [
          Icon(
            Icons.contact_phone_outlined,
            size: 40,
            color: AppColors.secondaryTextColor,
          ),
          const SizedBox(height: 8),
          CustomText(
            AppStrings.noDataFound.tr,
            color: AppColors.secondaryTextColor,
          ),
          if (isEdit) ...[
            const SizedBox(height: 12),
            _updatePill(() => Get.to(SchoolContactUs())),
          ],
        ],
      ),
    );
  }
}
