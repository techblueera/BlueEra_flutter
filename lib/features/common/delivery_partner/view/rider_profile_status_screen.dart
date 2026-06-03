import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:BlueEra/features/common/delivery_partner/view/aadhar_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/common_rider_bottom_sheet.dart';
import 'package:BlueEra/features/common/delivery_partner/view/driving_licence_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/pan_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rc_book_card_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_images_riding_widget.dart';
import 'package:BlueEra/features/common/delivery_partner/view/vehicle_information_widget.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Rider/Delivery KYC status surface — always embedded inside a
/// bottom-nav tab body now (Riders & Cab/Transport partner tabs).
/// No more Scaffold/AppBar shell or `screeName` flag — those existed
/// only for the legacy standalone-page path.
class RiderProfileStatusScreen extends StatefulWidget {
  RiderProfileStatusScreen({super.key});

  @override
  State<RiderProfileStatusScreen> createState() =>
      _RiderProfileStatusScreenState();
}

class _RiderProfileStatusScreenState extends State<RiderProfileStatusScreen> {
  final controller = getOrPut(() => DeliveryPartnerController());

  @override
  void initState() {
    controller.ridersOnboardingStatusRepoApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RiderFormWidget(
      deliveryPartnerController: controller,
    );
  }
}

class RiderFormWidget extends StatefulWidget {
  RiderFormWidget({
    super.key,
    required this.deliveryPartnerController,
  });

  final DeliveryPartnerController deliveryPartnerController;

  @override
  State<RiderFormWidget> createState() => _RiderFormWidgetState();
}

class _RiderFormWidgetState extends State<RiderFormWidget>
    with SingleTickerProviderStateMixin {
  RiderOnboardingStatusData riderOnboardingStatusData =
      RiderOnboardingStatusData();

  final RxBool _isSubmitted = false.obs;
  bool _hasShownRiderTypePopup = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No SafeArea / Scaffold here — the parent tab body already lives
    // inside the bottom-nav scaffold's SafeArea, and the surrounding
    // Padding above this widget supplies the top breathing room.
    return Obx(() {
      if (widget.deliveryPartnerController.isRiderStatusLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      riderOnboardingStatusData =
          widget.deliveryPartnerController.riderOnboardingStatusData.value ??
              RiderOnboardingStatusData();

      final state = widget.deliveryPartnerController.riderVerificationState;
      final allCompleted = widget.deliveryPartnerController.stepStatus.values
          .every((s) => s == true);

      // Show submitted success screen
      if (_isSubmitted.value ||
          (allCompleted && state == RiderVerificationState.pending)) {
        return _buildSubmittedSuccessView();
      }

      // Show verified screen
      if (allCompleted && state == RiderVerificationState.completed) {
        if (!_hasShownRiderTypePopup) {
          _hasShownRiderTypePopup = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRiderTypeSelectionPopup();
          });
        }
        return _buildVerifiedView();
      }

      return SingleChildScrollView(
        // Left inset is bumped to 24 px so the outside-left status
        // badges (red ?/green ✓) and the cards beside them sit well
        // inside the tab body rather than hugging the screen edge.
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size40,
          SizeConfig.size4,
          SizeConfig.size12,
          SizeConfig.size20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rejected banner
            if (allCompleted && state == RiderVerificationState.rejected)
              _buildRejectedBanner(),

            // "Joined" pill — centered above the document list,
            // matches the new design spec.
            if (!allCompleted) ...[
              _buildJoinedPill(),
              SizedBox(height: SizeConfig.size16),
            ],

            // Document Cards
            ..._buildDocumentCards(context),

            // Submit Button (when all completed & not yet submitted)
            if (allCompleted &&
                state != RiderVerificationState.completed) ...[
              SizedBox(height: SizeConfig.size16),
              _buildSubmitButton(),
            ],

            // Contact Us
            SizedBox(height: SizeConfig.size4),
            _buildContactUsCard(),
          ],
        ),
      );
    });
  }

  // ─── SUBMITTED SUCCESS VIEW ───────────────────────────────────────

  Widget _buildSubmittedSuccessView() {
    if (!_animController.isCompleted) {
      _animController.forward();
    }
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),

          // Animated check icon
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF2E7D32),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withAlpha(60),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 28),
          CustomText(
            AppStrings.applicationSubmittedSuccessfully.tr,
            fontSize: SizeConfig.extraLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFA000).withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: Color(0xFFFFA000), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    AppStrings.profileUnderVerificationMsg.tr,
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // What happens next
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.whatHappensNext.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 14),
                _buildTimelineStep(
                  icon: Icons.fact_check_rounded,
                  title: AppStrings.documentReview.tr,
                  subtitle: AppStrings.documentReviewSubtitle.tr,
                  isActive: true,
                ),
                _buildTimelineConnector(),
                _buildTimelineStep(
                  icon: Icons.notifications_active_rounded,
                  title: AppStrings.getNotified.tr,
                  subtitle: AppStrings.getNotifiedSubtitle.tr,
                  isActive: false,
                ),
                _buildTimelineConnector(),
                _buildTimelineStep(
                  icon: Icons.delivery_dining_rounded,
                  title: AppStrings.startDelivering.tr,
                  subtitle: AppStrings.startDeliveringSubtitle.tr,
                  isActive: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact Us card
          _buildContactUsCard(),

          SizedBox(height: SizeConfig.size20),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryColor.withAlpha(20)
                : const Color(0xFFF1F1F3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? AppColors.primaryColor : const Color(0xFFB0B4BF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                title,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.mainTextColor
                    : AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 2),
              CustomText(
                subtitle,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 17),
      child: Container(
        width: 2,
        height: 20,
        color: const Color(0xFFE5E5E5),
      ),
    );
  }

  // ─── VERIFIED VIEW (No Orders) ─────────────────────────────────────

  Widget _buildVerifiedView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Verified badge card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withAlpha(40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.profileVerified.tr,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        AppStrings.allSetToAcceptDeliveries.tr,
                        fontSize: SizeConfig.small,
                        color: Colors.white.withAlpha(220),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // No orders illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delivery_dining_rounded,
                    color: AppColors.primaryColor.withAlpha(120),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                CustomText(
                  AppStrings.noOrdersYet.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CustomText(
                  AppStrings.noOrdersYetSubtitle.tr,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick tips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.tipsToGetMoreOrders.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 14),
                _buildTipRow(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFFE53935),
                  text: AppStrings.tipStayHighDemand.tr,
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFFFFA000),
                  text: AppStrings.tipPeakHours.tr,
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.star_rounded,
                  color: const Color(0xFF4CAF50),
                  text: AppStrings.tipMaintainRatings.tr,
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.wifi_rounded,
                  color: AppColors.primaryColor,
                  text: AppStrings.tipStableInternet.tr,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contact Us
          _buildContactUsCard(),

          SizedBox(height: SizeConfig.size20),
        ],
      ),
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomText(
            text,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  // ─── REJECTED BANNER ──────────────────────────────────────────────

  Widget _buildRejectedBanner() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: SizeConfig.size15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red00.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              AppStrings.verificationRejectedMsg.tr,
              fontSize: SizeConfig.small,
              color: AppColors.mainTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── "JOINED" PILL ────────────────────────────────────────────────
  // Small white capsule centered above the document list, e.g.
  // "Joined - 1/05/2026". Replaces the earlier progress header so the
  // chrome above the cards is calmer and matches the new spec.
  Widget _buildJoinedPill() {
    final today = DateTime.now();
    final formatted =
        '${today.day}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomText(
          '${AppStrings.joinedLabel.tr} - $formatted',
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w500,
          color: AppColors.mainTextColor,
        ),
      ),
    );
  }

  // ─── SUBMIT BUTTON ────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return CustomBtn(
      onTap: () => _showSubmitConfirmationDialog(),
      title: AppStrings.submitForVerification.tr,
      bgColor: AppColors.primaryColor,
      radius: 12,
      isValidate: true,
    );
  }

  void _showSubmitConfirmationDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: AppColors.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              CustomText(
                AppStrings.submitApplicationQuestion.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              CustomText(
                AppStrings.submitApplicationConfirmMsg.tr,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      onTap: () => Get.back(),
                      title: AppStrings.cancel.tr,
                      bgColor: Colors.white,
                      textColor: AppColors.secondaryTextColor,
                      borderColor: const Color(0xFFE5E5E5),
                      radius: 10,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomBtn(
                      onTap: () {
                        Get.back();
                        _isSubmitted.value = true;
                        _animController.reset();
                      },
                      title: AppStrings.submit.tr,
                      bgColor: AppColors.primaryColor,
                      radius: 10,
                      height: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ─── RIDER TYPE SELECTION POPUP ────────────────────────────────────

  void _showRiderTypeSelectionPopup() {
    final selectedType = RxString('');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: AppColors.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              CustomText(
                AppStrings.chooseYourRideType.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              CustomText(
                AppStrings.selectHowToServe.tr,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 22),

              // Options
              Obx(() => Column(
                    children: [
                      _buildRiderTypeOption(
                        selectedType: selectedType,
                        value: 'passenger',
                        icon: Icons.person_pin_circle_rounded,
                        iconColor: const Color(0xFF1E88E5),
                        title: AppStrings.passengerRider.tr,
                        subtitle: AppStrings.passengerRiderSubtitle.tr,
                      ),
                      const SizedBox(height: 10),
                      _buildRiderTypeOption(
                        selectedType: selectedType,
                        value: 'delivery',
                        icon: Icons.local_shipping_rounded,
                        iconColor: const Color(0xFFFB8C00),
                        title: AppStrings.deliveryRider.tr,
                        subtitle: AppStrings.deliveryRiderSubtitle.tr,
                      ),
                      const SizedBox(height: 10),
                      _buildRiderTypeOption(
                        selectedType: selectedType,
                        value: 'both',
                        icon: Icons.all_inclusive_rounded,
                        iconColor: const Color(0xFF43A047),
                        title: AppStrings.bothRideType.tr,
                        subtitle: AppStrings.bothRiderSubtitle.tr,
                      ),
                    ],
                  )),

              const SizedBox(height: 22),

              // Continue button
              Obx(() => CustomBtn(
                    onTap: selectedType.value.isEmpty
                        ? null
                        : () async {
                            await SharedPreferenceUtils.setSecureValue(
                                'riderTypePreference', selectedType.value);
                            Get.back();
                            commonSnackBar(
                                message: AppStrings.preferenceSaved.tr);
                          },
                    title: AppStrings.continueBtn.tr,
                    bgColor: selectedType.value.isEmpty
                        ? const Color(0xFFB0B4BF)
                        : AppColors.primaryColor,
                    radius: 12,
                  )),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildRiderTypeOption({
    required RxString selectedType,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedType.value == value;

    return GestureDetector(
      onTap: () => selectedType.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withAlpha(8)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : const Color(0xFFE5E5E5),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    subtitle,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : const Color(0xFFD0D0D0),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CONTACT US CARD ──────────────────────────────────────────────

  Widget _buildContactUsCard() {
    return GestureDetector(
      onTap: () => _showEnquiryDialog(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.headset_mic_rounded,
                color: AppColors.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.needHelpQuestion.tr,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    AppStrings.contactUsForQueries.tr,
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showEnquiryDialog() {
    final queryController = TextEditingController();
    final selectedCategory = RxString(AppStrings.categoryGeneral.tr);
    final categories = [
      AppStrings.categoryGeneral.tr,
      AppStrings.categoryDocumentIssue.tr,
      AppStrings.categoryVerificationDelay.tr,
      AppStrings.categoryTechnicalIssue.tr,
      AppStrings.categoryOther.tr,
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    AppStrings.contactUs.tr,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Category selector
              CustomText(
                AppStrings.category.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory.value == cat;
                      return GestureDetector(
                        onTap: () => selectedCategory.value = cat,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : const Color(0xFFE5E5E5),
                            ),
                          ),
                          child: CustomText(
                            cat,
                            fontSize: SizeConfig.small,
                            color: isSelected
                                ? Colors.white
                                : AppColors.secondaryTextColor,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                  )),

              const SizedBox(height: 18),

              // Query input
              CustomText(
                AppStrings.describeYourQuery.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: queryController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: AppStrings.queryHintText.tr,
                  hintStyle: TextStyle(
                    color: const Color(0xFFB0B4BF),
                    fontSize: SizeConfig.small,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFCFCFE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomBtn(
                  onTap: () {
                    if (queryController.text.trim().isEmpty) {
                      commonSnackBar(message: AppStrings.pleaseDescribeQuery.tr);
                      return;
                    }
                    Get.back();
                    _showQuerySubmittedPopup();
                  },
                  title: AppStrings.submitQuery.tr,
                  bgColor: AppColors.primaryColor,
                  radius: 10,
                  height: 46,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuerySubmittedPopup() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              CustomText(
                AppStrings.querySubmitted.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              CustomText(
                AppStrings.querySubmittedMsg.tr,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomBtn(
                  onTap: () => Get.back(),
                  title: AppStrings.done.tr,
                  bgColor: AppColors.primaryColor,
                  radius: 10,
                  height: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DOCUMENT CARDS ───────────────────────────────────────────────

  List<Widget> _buildDocumentCards(BuildContext context) {
    final items = [
      _DocumentItem(
        stepNumber: 1,
        icon: Icons.directions_car_rounded,
        title: AppStrings.addYourVehicleInfo.tr,
        example: AppStrings.egVehicleNo.tr,
        currentValue: riderOnboardingStatusData.vehicleNo ?? '',
        isCompleted: riderOnboardingStatusData.vehicleInformation ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.vehicleInformation.tr,
              height: MediaQuery.of(context).size.height * 0.80,
              child: VehicleInformationWidget(
                screeName: 'from_bottom_view',
              ),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ),
      _DocumentItem(
        stepNumber: 2,
        icon: Icons.badge_rounded,
        title: AppStrings.addYourAadharNumber.tr,
        dialogTitle: AppStrings.aadharCard.tr,
        example: AppStrings.egAadharNo.tr,
        currentValue: riderOnboardingStatusData.aadharNo ?? '',
        isCompleted: riderOnboardingStatusData.aadhar ?? false,
        imageUrl: riderOnboardingStatusData.aadharImage,
        // Aadhar is the one document that stays viewable (View + Edit)
        // once filled even if no image URL is on file — the dialog
        // surfaces the saved number and re-opens this sheet to edit.
        enableDataView: true,
        onTap: () {
          // Pre-fill the saved number so the sheet opens in "edit"
          // mode when reached from the View dialog's Edit action.
          widget.deliveryPartnerController.aadharController.text =
              riderOnboardingStatusData.aadharNo ?? '';
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.aadharCard.tr,
              height: MediaQuery.of(context).size.height * 0.40,
              child: AadharCardWidget(),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ),
      _DocumentItem(
        stepNumber: 3,
        icon: Icons.credit_card_rounded,
        title: AppStrings.addYourPanNumber.tr,
        dialogTitle: AppStrings.panCard.tr,
        example: AppStrings.egPanNo.tr,
        currentValue: riderOnboardingStatusData.panNo ?? '',
        isCompleted: riderOnboardingStatusData.pan ?? false,
        imageUrl: riderOnboardingStatusData.panImage,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.panCard.tr,
              height: MediaQuery.of(context).size.height * 0.40,
              child: PanCardWidget(),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ),
      _DocumentItem(
        stepNumber: 4,
        icon: Icons.card_membership_rounded,
        title: AppStrings.addYourDrivingLicenceNumber.tr,
        dialogTitle: AppStrings.drivingLicence.tr,
        example: AppStrings.egDlNo.tr,
        currentValue: riderOnboardingStatusData.dlNo ?? '',
        isCompleted: riderOnboardingStatusData.dl ?? false,
        imageUrl: riderOnboardingStatusData.dlImage,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.drivingLicence.tr,
              height: MediaQuery.of(context).size.height * 0.40,
              child: DrivingLicenceCardWidget(),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ),
      _DocumentItem(
        stepNumber: 5,
        icon: Icons.description_rounded,
        title: AppStrings.addYourRcNumber.tr,
        dialogTitle: AppStrings.rcBook.tr,
        example: AppStrings.egRcNo.tr,
        currentValue: riderOnboardingStatusData.rcNo ?? '',
        isCompleted: riderOnboardingStatusData.rc ?? false,
        imageUrl: riderOnboardingStatusData.rcImage,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.rc.tr,
              height: MediaQuery.of(context).size.height * 0.40,
              child: RcBookCardWidget(),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ),
      _DocumentItem(
        stepNumber: 6,
        icon: Icons.photo_camera_rounded,
        title: AppStrings.vehicleImages.tr,
        example: AppStrings.uploadVehicleImage.tr,
        currentValue: '',
        isCompleted: riderOnboardingStatusData.vehicleImages ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.vehicleImages.tr,
              height: MediaQuery.of(context).size.height * 0.80,
              child: VehicleImagesRidingWidget(),
            ),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ),
    ];

    return items.map((item) => _buildDocumentCard(item)).toList();
  }

  Widget _buildDocumentCard(_DocumentItem item) {
    final state = widget.deliveryPartnerController.riderVerificationState;
    // The card has three interactive states:
    //   1. Uploaded WITH image  → whole card opens the view dialog,
    //      from which the user can also Replace (which routes back
    //      to the existing upload bottom sheet).
    //   2. Pending (or rejected) → whole card opens the upload sheet.
    //   3. Completed without an image URL → fallback "Done" pill,
    //      not tappable (preserves the original behavior until the
    //      backend returns image URLs).
    final hasUploadedImage = item.isCompleted &&
        (item.imageUrl?.isNotEmpty ?? false);
    // Aadhar (enableDataView) stays viewable once completed even when no
    // image URL is on file — the view dialog surfaces the saved number
    // and an Edit action instead of the plain "Done" pill.
    final isViewable =
        item.isCompleted && (hasUploadedImage || item.enableDataView);
    final allowUpload =
        !item.isCompleted || state == RiderVerificationState.rejected;
    final VoidCallback? onCardTap = isViewable
        ? () => _showDocumentViewDialog(
              context,
              title: item.dialogTitle ?? item.title,
              imageUrl: item.imageUrl,
              dataLabel:
                  item.enableDataView ? AppStrings.aadharNumber.tr : null,
              dataValue: item.enableDataView ? item.currentValue : null,
              onReplace: item.onTap,
              actionLabel:
                  item.enableDataView ? AppStrings.editLabel.tr : null,
              actionIcon: item.enableDataView
                  ? Icons.edit_rounded
                  : Icons.refresh_rounded,
            )
        : (allowUpload ? item.onTap : null);

    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusBadge(item.isCompleted),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onCardTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildIconColumn(
                          item,
                          showThumbnail: hasUploadedImage,
                        ),
                        Expanded(
                          child: _buildContentColumn(
                            item,
                            showViewDocument: isViewable,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LEFT COLUMN — icon/thumbnail (top) + saved value (bottom) ────
  // Pale primary-tint panel inset 10 px inside the white card, with
  // its own rounded corners so it reads as a panel-within-panel.
  // [showThumbnail] swaps the generic Material icon for a clipped
  // thumbnail of the uploaded document (with a tiny green check
  // overlay) — so the panel itself communicates "this document is
  // on file."
  Widget _buildIconColumn(_DocumentItem item, {bool showThumbnail = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: 66,
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            showThumbnail
                ? _buildDocumentThumbnail(item)
                : _buildDocumentIconTile(item.icon),
            // Always-rendered slot — keeps the icon pinned to the top
            // even when the user hasn't entered a value yet.
            CustomText(
              item.currentValue,
              fontSize: SizeConfig.small,
              color: const Color(0xFF8A8F9C),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Generic icon tile shown when the document hasn't been uploaded
  // yet (or there's no image URL on file). Outlined white box with
  // a darkish glyph — the original calm-but-empty cue.
  Widget _buildDocumentIconTile(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF1F2937),
        size: 24,
      ),
    );
  }

  // Thumbnail tile shown in the uploaded state. The image is
  // clipped to a 10-radius square inside a primary-tinted border
  // (so the verified-state cue is unambiguous), with a small green
  // check chip overlapping the bottom-right corner. Falls back to
  // the generic icon tile if the image fails to load.
  Widget _buildDocumentThumbnail(_DocumentItem item) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFF1F4F9),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) =>
                      _buildDocumentIconTile(item.icon),
                ),
              ),
            ),
          ),
          // Tiny green check overlay — confirmation cue.
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withAlpha(60),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RIGHT COLUMN — title, example, divider, centered CTA ─────────
  // Three states for the bottom CTA:
  //   • [showViewDocument] true  → "View Document" with eye icon
  //     (uploaded with image — taps open the view dialog).
  //   • [item.isCompleted] true  → "Done" pill (uploaded but no
  //     image URL on file yet — preserves prior behavior).
  //   • Otherwise                → "+ Add Now" primary CTA.
  Widget _buildContentColumn(
    _DocumentItem item, {
    bool showViewDocument = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            item.title,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          CustomText(
            showViewDocument ? AppStrings.documentReceived.tr : item.example,
            fontSize: SizeConfig.small,
            color: showViewDocument
                ? AppColors.primaryColor
                : const Color(0xFFB0B4BF),
            fontWeight:
                showViewDocument ? FontWeight.w600 : FontWeight.w400,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SizeConfig.size12),
          Container(
            height: 1,
            color: const Color(0xFFEDEFF4),
          ),
          SizedBox(height: SizeConfig.size10),
          Center(
            child: showViewDocument
                ? _buildViewDocumentCta()
                : item.isCompleted
                    ? _buildDoneChip()
                    : _buildAddNowCta(),
          ),
        ],
      ),
    );
  }

  // ─── "View Document" CTA — uploaded-state right-column action ─────
  Widget _buildViewDocumentCta() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.remove_red_eye_outlined,
          color: AppColors.primaryColor,
          size: 16,
        ),
        const SizedBox(width: 6),
        CustomText(
          AppStrings.viewDocument.tr,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ],
    );
  }

  // ─── STATUS BADGE (outside left of each card) ─────────────────────
  Widget _buildStatusBadge(bool isCompleted) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEAEC),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4CAF50).withAlpha(80)
              : const Color(0xFFE57373).withAlpha(110),
          width: 1,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check_rounded : Icons.help_outline_rounded,
        color: isCompleted
            ? const Color(0xFF4CAF50)
            : const Color(0xFFE57373),
        size: 16,
      ),
    );
  }

  // ─── "+ Add Now" CTA (right side, pending state) ──────────────────
  Widget _buildAddNowCta() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add_circle_outline_rounded,
          color: AppColors.primaryColor,
          size: 16,
        ),
        const SizedBox(width: 4),
        CustomText(
          AppStrings.addNowCta.tr,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ],
    );
  }

  // ─── VIEW DOCUMENT DIALOG ─────────────────────────────────────────
  // Polished modal that surfaces the uploaded document at full
  // legibility. Three sections inside a 18-radius rounded sheet
  // with a soft drop shadow:
  //   1. HEADER  — uppercase tracked title on the left, primary-
  //               tinted close button on the right, hairline below.
  //   2. BODY    — InteractiveViewer wrapping a CachedNetworkImage
  //               (BoxFit.contain) so users can pinch to zoom into
  //               the document. Capped at 55 % of the screen height
  //               so the dialog never overflows.
  //   3. ACTIONS — Replace (outlined primary) closes the dialog and
  //               re-opens the upload bottom sheet; Done (filled
  //               primary) just closes.
  void _showDocumentViewDialog(
    BuildContext context, {
    required String title,
    String? imageUrl,
    String? dataLabel,
    String? dataValue,
    required VoidCallback onReplace,
    String? actionLabel,
    IconData actionIcon = Icons.refresh_rounded,
  }) {
    final maxImageHeight = MediaQuery.of(context).size.height * 0.55;
    final hasImage = imageUrl?.isNotEmpty ?? false;
    final hasData = dataValue?.isNotEmpty ?? false;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
              const BoxShadow(
                color: Color(0x14001120),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(title),
                if (hasImage) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxImageHeight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => _buildDialogImageFallback(
                            const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) =>
                              _buildDialogImageFallback(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  size: 44,
                                  color:
                                      AppColors.secondaryTextColor,
                                ),
                                const SizedBox(height: 8),
                                CustomText(
                                  AppStrings.couldNotLoadImage.tr,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.zoom_in_rounded,
                        size: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      CustomText(
                        AppStrings.pinchToZoom.tr,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                ],
                if (hasData) _buildDialogDataRow(dataLabel, dataValue!),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDialogReplaceBtn(
                          onReplace,
                          label: actionLabel,
                          icon: actionIcon,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogDoneBtn(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  Widget _buildDialogHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              title.toUpperCase(),
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              letterSpacing: 0.6,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      AppColors.primaryColor.withValues(alpha: 0.22),
                  width: 0.6,
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Wraps the placeholder/error content inside a soft neutral card so
  // those states match the in-frame aesthetic instead of bleeding a
  // raw spinner across the dialog.
  Widget _buildDialogImageFallback(Widget child) {
    return Container(
      height: 200,
      width: double.infinity,
      color: const Color(0xFFF5F7FA),
      child: Center(child: child),
    );
  }

  Widget _buildDialogReplaceBtn(
    VoidCallback onReplace, {
    String? label,
    IconData icon = Icons.refresh_rounded,
  }) {
    return InkWell(
      onTap: () {
        Get.back();
        onReplace();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 6),
            CustomText(
              label ?? AppStrings.replaceLabel.tr,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Labeled data row shown inside the view dialog for documents that
  // carry a saved text value (currently just the Aadhar number). Sits
  // between the (optional) image and the action buttons.
  Widget _buildDialogDataRow(String? label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null && label.isNotEmpty) ...[
              CustomText(
                label,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 4),
            ],
            CustomText(
              value,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogDoneBtn() {
    return InkWell(
      onTap: () => Get.back(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: CustomText(
            AppStrings.done.tr,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─── "Done" chip (right side, completed state) ────────────────────
  Widget _buildDoneChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            color: Color(0xFF4CAF50),
            size: 14,
          ),
          const SizedBox(width: 4),
          CustomText(
            AppStrings.done.tr,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}

class _DocumentItem {
  final int stepNumber;
  final IconData icon;
  final String title;
  // The "E.g. …" format hint shown under the title in the top row.
  // Always rendered, even when [currentValue] is also present.
  final String example;
  // The user's actual saved value, shown in the bottom-left of the
  // card under the divider. Empty when the document hasn't been
  // filled in yet.
  final String currentValue;
  final bool isCompleted;
  final VoidCallback onTap;
  // URL of the uploaded document image. When present alongside
  // [isCompleted], the card upgrades from the "Done" pill state
  // to a richer "thumbnail + View Document" presentation, and the
  // whole card opens the view dialog instead of the upload sheet.
  // Null/empty for documents that don't have a single-image preview
  // (Vehicle Information, Vehicle Images).
  final String? imageUrl;
  // Clean title shown at the top of the view dialog. Falls back to
  // [title] when null.
  final String? dialogTitle;
  // When true, the card stays viewable (View + Edit) once completed even
  // if no [imageUrl] is on file — the view dialog surfaces the saved
  // [currentValue] and re-opens [onTap] as an edit flow. Currently only
  // the Aadhar card opts in.
  final bool enableDataView;

  _DocumentItem({
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.example,
    required this.currentValue,
    required this.isCompleted,
    required this.onTap,
    this.imageUrl,
    this.dialogTitle,
    this.enableDataView = false,
  });
}
