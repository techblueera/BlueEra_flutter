import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/booking_controller.dart';
import 'package:BlueEra/widgets/visiting_hour_selector.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/apiService/api_keys.dart';

class BusinessHoursSheetContent extends StatefulWidget {
  final BusinessProfileDetails? details;
  final ViewBusinessDetailsController controller;

  const BusinessHoursSheetContent({
    required this.details,
    required this.controller,
  });

  @override
  State<BusinessHoursSheetContent> createState() =>
      _BusinessHoursSheetContentState();
}

class _BusinessHoursSheetContentState
    extends State<BusinessHoursSheetContent> {
  bool _isLoading = true;
  final _bookingCtrl = getOrPut(() => BookingController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAndLoad());
  }

  Future<void> _syncAndLoad() async {
    if (!mounted) return;
    _bookingCtrl.syncScheduleToController(widget.details?.availability?.schedule);
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    deleteIfRegistered<VisitingHoursSelectorController>();
    deleteIfRegistered<BookingController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          // Compact while loading, wrap-to-content when ready
          constraints: _isLoading
              ? BoxConstraints.tightFor(
            height: MediaQuery.of(context).size.height * 0.4,
          )
              : BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size16,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoading ? _buildLoader() : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return SizedBox.expand(
      key: const ValueKey('loader'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryColor),
          const SizedBox(height: 16),
          CustomText(
            AppStrings.loadingBusinessHours.tr,
            fontSize: 14,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      key: const ValueKey('content'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Expanded so a longer translation wraps or ellipsizes instead
              // of colliding with the close button.
              Expanded(
                child: CustomText(
                  AppStrings.updateBusinessHours.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const CloseButton(),
            ],
          ),
          const SizedBox(height: 16),
          VisitingHoursSelector(),
          const SizedBox(height: 16),
          CustomBtn(
            radius: 10,
            bgColor: AppColors.primaryColor,
            title: AppStrings.save.tr,
            onTap: () async {
              // Use BookingController's payload builder
              final visitingHoursData = _bookingCtrl.payloadForVisitingHours();
              final params = <String, dynamic>{
                ApiKeys.businessId: businessId,
                if (visitingHoursData.isNotEmpty)
                  ApiKeys.schedule: visitingHoursData,
              };
              await widget.controller.updateBusinessProfileDetails(params);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}