import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
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
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderProfileStatusScreen extends StatefulWidget {
  RiderProfileStatusScreen({
    super.key,
    required this.screeName,
  });

  final String screeName;

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
    return widget.screeName != "from_tab_view"
        ? Scaffold(
            appBar: CommonBackAppBar(
              title: AppStrings.deliveryPartner,
            ),
            body: RiderFormWidget(
              deliveryPartnerController: controller,
            ),
          )
        : Material(
            color: AppColors.appBackgroundColor,
            child: RiderFormWidget(
              deliveryPartnerController: controller,
            ));
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
    return SafeArea(
      child: Obx(() {
        if (widget.deliveryPartnerController.isRiderStatusLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        riderOnboardingStatusData =
            widget.deliveryPartnerController.riderOnboardingStatusData.value ??
                RiderOnboardingStatusData();

        final state = widget.deliveryPartnerController.riderVerificationState;
        final allCompleted = widget.deliveryPartnerController.stepStatus.values
            .every((s) => s == true);

        final completedCount = _getCompletedCount();
        const totalSteps = 6;

        // Show submitted success screen
        if (_isSubmitted.value || (allCompleted && state == RiderVerificationState.pending)) {
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

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rejected banner
                  if (allCompleted && state == RiderVerificationState.rejected)
                    _buildRejectedBanner(),

                  // Progress Header
                  if (!allCompleted) ...[
                    _buildProgressHeader(completedCount, totalSteps),
                    SizedBox(height: SizeConfig.size10),
                  ],

                  // Document Cards
                  ..._buildDocumentCards(context),

                  // Submit Button (when all completed & not yet submitted)
                  if (allCompleted && state != RiderVerificationState.completed) ...[
                    SizedBox(height: SizeConfig.size20),
                    _buildSubmitButton(),
                  ],

                  // Contact Us
                  SizedBox(height: SizeConfig.size20),
                  _buildContactUsCard(),

                  SizedBox(height: SizeConfig.size100),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  int _getCompletedCount() {
    int count = 0;
    if (riderOnboardingStatusData.vehicleInformation ?? false) count++;
    if (riderOnboardingStatusData.aadhar ?? false) count++;
    if (riderOnboardingStatusData.pan ?? false) count++;
    if (riderOnboardingStatusData.dl ?? false) count++;
    if (riderOnboardingStatusData.rc ?? false) count++;
    if (riderOnboardingStatusData.vehicleImages ?? false) count++;
    return count;
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
            'Application Submitted\nSuccessfully!',
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
                    'Your profile is under verification. We will notify you once your profile is verified.',
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
                  'What happens next?',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 14),
                _buildTimelineStep(
                  icon: Icons.fact_check_rounded,
                  title: 'Document Review',
                  subtitle: 'Our team will verify all your uploaded documents',
                  isActive: true,
                ),
                _buildTimelineConnector(),
                _buildTimelineStep(
                  icon: Icons.notifications_active_rounded,
                  title: 'Get Notified',
                  subtitle: 'You\'ll receive a notification once approved',
                  isActive: false,
                ),
                _buildTimelineConnector(),
                _buildTimelineStep(
                  icon: Icons.delivery_dining_rounded,
                  title: 'Start Delivering',
                  subtitle: 'Accept orders and start earning',
                  isActive: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact Us card
          _buildContactUsCard(),

          const SizedBox(height: 20),

          // Go Back button
          CustomBtn(
            onTap: () => Get.back(),
            title: 'Go to Home',
            bgColor: AppColors.primaryColor,
            radius: 12,
          ),

          SizedBox(height: SizeConfig.size60),
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
                        'Profile Verified',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        'You\'re all set to accept deliveries!',
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
                  'No Orders Yet',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CustomText(
                  'New delivery requests will appear here.\nStay online to receive orders nearby.',
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
                  'Tips to Get More Orders',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 14),
                _buildTipRow(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFFE53935),
                  text: 'Stay in high-demand areas for faster pickups',
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFFFFA000),
                  text: 'Peak hours: 11 AM - 2 PM & 6 PM - 10 PM',
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.star_rounded,
                  color: const Color(0xFF4CAF50),
                  text: 'Maintain good ratings to get priority orders',
                ),
                const SizedBox(height: 12),
                _buildTipRow(
                  icon: Icons.wifi_rounded,
                  color: AppColors.primaryColor,
                  text: 'Keep your internet connection stable',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contact Us
          _buildContactUsCard(),

          const SizedBox(height: 16),

          // Go to Home
          CustomBtn(
            onTap: () => Get.back(),
            title: 'Go to Home',
            bgColor: AppColors.primaryColor,
            radius: 12,
          ),

          SizedBox(height: SizeConfig.size60),
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
              'Your verification was rejected. Please review and re-upload the required documents.',
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

  // ─── PROGRESS HEADER ──────────────────────────────────────────────

  Widget _buildProgressHeader(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Complete Your Profile',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              CustomText(
                '$completed / $total',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EAF0),
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          CustomText(
            completed == 0
                ? 'Upload your documents to get started'
                : '$completed of $total steps completed',
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // ─── SUBMIT BUTTON ────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return CustomBtn(
      onTap: () => _showSubmitConfirmationDialog(),
      title: 'Submit for Verification',
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
                'Submit Application?',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              CustomText(
                'Please make sure all your documents are correct. Once submitted, your application will be reviewed by our team.',
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
                      title: 'Cancel',
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
                      title: 'Submit',
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
                'Choose Your Ride Type',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              CustomText(
                'Select how you\'d like to serve on BlueEra',
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
                        title: 'Passenger Rider',
                        subtitle: 'Pick up & drop off passengers',
                      ),
                      const SizedBox(height: 10),
                      _buildRiderTypeOption(
                        selectedType: selectedType,
                        value: 'delivery',
                        icon: Icons.local_shipping_rounded,
                        iconColor: const Color(0xFFFB8C00),
                        title: 'Delivery Rider',
                        subtitle: 'Deliver food, parcels & groceries',
                      ),
                      const SizedBox(height: 10),
                      _buildRiderTypeOption(
                        selectedType: selectedType,
                        value: 'both',
                        icon: Icons.all_inclusive_rounded,
                        iconColor: const Color(0xFF43A047),
                        title: 'Both',
                        subtitle: 'Passenger rides & deliveries',
                      ),
                    ],
                  )),

              const SizedBox(height: 22),

              // Continue button
              Obx(() => CustomBtn(
                    onTap: selectedType.value.isEmpty
                        ? null
                        : () {
                            Get.back();
                            commonSnackBar(
                                message:
                                    'Preference saved! You can change this later.');
                          },
                    title: 'Continue',
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
                    'Need Help?',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    'Contact us for any queries or support',
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
    final selectedCategory = RxString('General');
    final categories = ['General', 'Document Issue', 'Verification Delay', 'Technical Issue', 'Other'];

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
                    'Contact Us',
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
                'Category',
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
                'Describe your query',
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
                  hintText: 'Type your question or concern here...',
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
                      commonSnackBar(message: 'Please describe your query');
                      return;
                    }
                    Get.back();
                    _showQuerySubmittedPopup();
                  },
                  title: 'Submit Query',
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
                'Query Submitted!',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              CustomText(
                'Thank you for reaching out. Our support team will get back to you shortly.',
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
                  title: 'Done',
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
        title: AppStrings.vehicleInformation,
        value: (riderOnboardingStatusData.vehicleNo?.isNotEmpty ?? false)
            ? riderOnboardingStatusData.vehicleNo ?? ""
            : 'E.g. WB5454',
        isCompleted: riderOnboardingStatusData.vehicleInformation ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.vehicleInformation,
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
        title: AppStrings.aadharNumber,
        value: (riderOnboardingStatusData.aadharNo?.isNotEmpty ?? false)
            ? riderOnboardingStatusData.aadharNo ?? ""
            : 'E.g. 5678 1234 6679 9012',
        isCompleted: riderOnboardingStatusData.aadhar ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: "Aadhar Card",
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
        title: AppStrings.panNumber,
        value: (riderOnboardingStatusData.panNo?.isNotEmpty ?? false)
            ? riderOnboardingStatusData.panNo ?? ""
            : 'E.g. ABCDE1234F',
        isCompleted: riderOnboardingStatusData.pan ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: "Pan Card",
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
        title: AppStrings.drivingLicenceNumber,
        value: (riderOnboardingStatusData.dlNo?.isNotEmpty ?? false)
            ? riderOnboardingStatusData.dlNo ?? ""
            : 'E.g. DL0120110012345',
        isCompleted: riderOnboardingStatusData.dl ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: "Driving Licence",
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
        title: AppStrings.rcNumber,
        value: (riderOnboardingStatusData.rcNo?.isNotEmpty ?? false)
            ? riderOnboardingStatusData.rcNo ?? ""
            : 'E.g. WB12 AB 1234',
        isCompleted: riderOnboardingStatusData.rc ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: "RC",
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
        title: AppStrings.vehicleImages,
        value: 'Upload Vehicle image',
        isCompleted: riderOnboardingStatusData.vehicleImages ?? false,
        onTap: () {
          Get.bottomSheet(
            CommonBottomSheet(
              title: AppStrings.vehicleImages,
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
    return GestureDetector(
      onTap: item.isCompleted ? null : item.onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isCompleted
                ? const Color(0xFF4CAF50).withAlpha(60)
                : const Color(0xFFE5E5E5),
          ),
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
                color: item.isCompleted
                    ? const Color(0xFFE8F5E9)
                    : AppColors.primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.isCompleted
                    ? const Color(0xFF4CAF50)
                    : AppColors.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    item.title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    item.value,
                    fontSize: SizeConfig.small,
                    color: item.isCompleted
                        ? AppColors.secondaryTextColor
                        : const Color(0xFFB0B4BF),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.isCompleted)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else
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
}

class _DocumentItem {
  final int stepNumber;
  final IconData icon;
  final String title;
  final String value;
  final bool isCompleted;
  final VoidCallback onTap;

  _DocumentItem({
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.value,
    required this.isCompleted,
    required this.onTap,
  });
}
