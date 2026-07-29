import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_profile_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_certificate_model.dart';
import 'package:BlueEra/features/me/doctor/view/certificate/doctor_certificates_screen.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_certificate_card.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_chip_input_field.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_cover_photo_card.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_gallery_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/testimonial_listing_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overview tab — the public-facing summary of the doctor's listing.
///
/// Section order follows the design: joined/identity card, cover photo,
/// expertise, certificates, gallery, testimonials, contact + map, then the
/// share banner and QR card that every "me" profile ends with.
///
/// Sections load independently: expertise and certificates come from the
/// doctor profile (hospital-service) while photos, contact and rating come
/// from the business profile (user-service), so one failing does not blank the
/// other.
class DoctorOverviewTab extends StatelessWidget {
  final DoctorProfileController controller;

  const DoctorOverviewTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10),

        // ── Joined date + name + rating (business identity) ──
        Padding(
          padding: EdgeInsets.only(left: SizeConfig.size16),
          child: BusinessJoinedProfileCard(
            businessController: businessController,
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        // ── Cover Photo (+ Edit) ──
        Padding(
          padding: _hPad,
          child: const DoctorCoverPhotoCard(),
        ),
        SizedBox(height: SizeConfig.size12),

        // ── Expertise ──
        Padding(
          padding: _hPad,
          // The observable must be READ INSIDE this builder — reading it in
          // the child's build() instead leaves Obx with nothing to subscribe
          // to and throws "improper use of a GetX".
          child: Obx(
            () => _ExpertiseSection(
              controller: controller,
              expertise: controller.profile.value?.expertise ?? const [],
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        // ── Certificate & Awards ──
        Padding(
          padding: _hPad,
          child: Obx(
            () => _CertificatesSection(
              certificates: controller.certificates,
              onViewAll: () => Get.to(() => const DoctorCertificatesScreen()),
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        // ── Gallery (Business.live_photos) ──
        Padding(
          padding: _hPad,
          child: const DoctorGallerySection(),
        ),
        SizedBox(height: SizeConfig.size12),

        // ── Testimonials ──
        Padding(
          padding: _hPad,
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CustomText(
                    AppStrings.testimonials.tr,
                    fontWeight: FontWeight.w700,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size10),
                TestimonialListingWidget(
                  showBorder: false,
                  callApi: true,
                  userId: userId,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        // ── Contact Us + map ──
        Padding(
          padding: _hPad,
          child: Obx(() {
            final details =
                businessController.businessProfileDetails.value?.data;
            return BusinessContactMapCard(businessProfileDetails: details);
          }),
        ),
        SizedBox(height: SizeConfig.size12),

        Padding(
          padding: _hPad,
          child: Obx(
            () => WebsiteOverviewCard(
              websiteUrl:
                  businessController.businessProfileDetails.value?.data?.websiteUrl,
              onSave: (url) => businessController
                  .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        Padding(padding: _hPad, child: const ProfileShareBanner()),
        SizedBox(height: SizeConfig.size12),

        Obx(() {
          final details =
              businessController.businessProfileDetails.value?.data;
          if (details == null) return const SizedBox.shrink();
          return Padding(
            padding: _hPad,
            child: BusinessQrCodeWidget(data: details),
          );
        }),

        SizedBox(height: kBottomNavigationBarHeight + 10),
      ],
    );
  }

  EdgeInsets get _hPad => EdgeInsets.symmetric(horizontal: SizeConfig.size12);
}

/// Expertise bullets with the pencil affordance from the design. Editing
/// writes back through a partial `PUT /doctors/me` touching only `expertise`.
class _ExpertiseSection extends StatelessWidget {
  /// Resolved by the caller's [Obx] — see the note there. The controller is
  /// still passed in, but only for the save callback, which is not a read.
  final List<String> expertise;
  final DoctorProfileController controller;

  const _ExpertiseSection({
    required this.controller,
    required this.expertise,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.doctorExpertise.tr,
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                ),
              ),
              InkWell(
                onTap: () => _openEditor(context, expertise),
                child: Icon(
                  expertise.isEmpty ? Icons.add : Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          if (expertise.isEmpty)
            InkWell(
              onTap: () => _openEditor(context, expertise),
              child: CustomText(
                AppStrings.doctorAddExpertise.tr,
                fontSize: SizeConfig.small,
                color: AppColors.grey83,
              ),
            )
          else
            ...expertise.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child: CustomText(
                        item,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    List<String> current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ExpertiseEditSheet(
        initial: current,
        controller: controller,
      ),
    );
  }
}

class _ExpertiseEditSheet extends StatefulWidget {
  final List<String> initial;
  final DoctorProfileController controller;

  const _ExpertiseEditSheet({required this.initial, required this.controller});

  @override
  State<_ExpertiseEditSheet> createState() => _ExpertiseEditSheetState();
}

class _ExpertiseEditSheetState extends State<_ExpertiseEditSheet> {
  late List<String> _values = [...widget.initial];
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.controller.saveExpertise(_values);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.whiteE5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size16),
              DoctorChipInputField(
                title: AppStrings.doctorExpertise.tr,
                hintText: AppStrings.doctorExpertiseHint.tr,
                values: _values,
                onChanged: (next) => setState(() => _values = next),
              ),
              SizedBox(height: SizeConfig.size20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.4),
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : CustomText(
                        AppStrings.save.tr,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Certificates carousel + "View All".
class _CertificatesSection extends StatelessWidget {
  final List<DoctorCertificate> certificates;
  final VoidCallback onViewAll;

  const _CertificatesSection({
    required this.certificates,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.doctorCertificateAwards.tr,
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: CustomText(
                  AppStrings.viewAll.tr,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.small,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          if (certificates.isEmpty)
            _EmptyRow(
              icon: Icons.workspace_premium_outlined,
              label: AppStrings.doctorAddCertificate.tr,
              onTap: onViewAll,
            )
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: certificates.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
                itemBuilder: (_, i) => DoctorCertificateCard(
                  certificate: certificates[i],
                  width: 160,
                  onTap: onViewAll,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EmptyRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: AppColors.primaryColor),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              label,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared card chrome for every Overview section.
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
