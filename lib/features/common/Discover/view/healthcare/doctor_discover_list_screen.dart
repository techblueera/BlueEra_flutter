import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/doctor_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/doctor_discover_summary.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/doctor_public_profile_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/doctor_discover_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standalone "Clinic Doctors" screen — used when the flow enters directly
/// from the Discover healthcare grid, so it brings its own app bar.
///
/// Inside the Healthcare listing (which already has the sticky category
/// header) use [DoctorDiscoverListView] instead, the same way the Lab
/// category renders its own body under the shared header.
class DoctorDiscoverListScreen extends StatelessWidget {
  /// `DOCTORS` (default) or `CLINICS` — both are valid and behave identically.
  final String category;
  final String? title;

  const DoctorDiscoverListScreen({
    super.key,
    this.category = 'DOCTORS',
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar:
          CommonBackAppBar(title: title ?? AppStrings.doctorDiscoverTitle.tr),
      body: DoctorDiscoverListView(category: category),
    );
  }
}

/// The doctor list itself, with no chrome of its own so it can sit under the
/// Healthcare screen's sticky category header.
///
/// This is the screen that replaces `HospitalListScreen(serviceType: 'DOCTORS')`
/// for the Clinic Doctors category. A standalone doctor has no hospital
/// record, no departments and no OPD rows, and routing it through the hospital
/// adapter discarded every doctor field the backend sends (guide §26).
class DoctorDiscoverListView extends StatefulWidget {
  final String category;

  const DoctorDiscoverListView({super.key, this.category = 'DOCTORS'});

  @override
  State<DoctorDiscoverListView> createState() => _DoctorDiscoverListViewState();
}

class _DoctorDiscoverListViewState extends State<DoctorDiscoverListView> {
  late final DoctorDiscoverController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tagged per category so a DOCTORS list and a CLINICS list never share
    // reactive state.
    controller = getOrPut(() => DoctorDiscoverController(),
        tag: 'doctor_discover_${widget.category}');
    controller.fetchDoctorsIfNeeded(category: widget.category);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      controller.loadMore(category: widget.category);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Both ids travel to the profile: `businessId` for enquiry / booking /
  /// ratings, `ownerUserId` for the doctor's professional profile and chat.
  /// Losing either one costs an extra round-trip later (guide §14).
  void _openProfile(DoctorDiscoverSummary doctor) {
    Get.to(() => DoctorPublicProfileScreen(
          businessId: doctor.businessId,
          ownerUserId: doctor.ownerUserId,
          summary: doctor,
        ));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: AppColors.skyE7,
      child: Obx(() {
        if (controller.isLoading.value && controller.doctors.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (controller.error.value.isNotEmpty && controller.doctors.isEmpty) {
          return _centeredMessage(
            AppStrings.failedToLoadData.tr,
            color: AppColors.red,
          );
        }
        if (controller.doctors.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () => controller.fetchDoctors(category: widget.category),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: SizeConfig.size100),
                _centeredMessage(AppStrings.doctorDiscoverEmpty.tr,
                    color: AppColors.grey9B),
              ],
            ),
          );
        }
        // Read in the Obx body, not inside `itemBuilder` — the builder runs
        // lazily, outside the reactive scope, so a read in there would never
        // subscribe and the footer spinner would never update.
        final isLoadingMore = controller.isLoadingMore.value;
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () => controller.fetchDoctors(category: widget.category),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size12,
              horizontal: SizeConfig.size12,
            ),
            itemCount: controller.doctors.length + 1,
            itemBuilder: (context, index) {
              if (index == controller.doctors.length) {
                return isLoadingMore
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.size12),
                        child: const Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(height: SizeConfig.size20);
              }
              final doctor = controller.doctors[index];
              return DoctorDiscoverCard(
                doctor: doctor,
                // Drives the card's alternating tint — the list index is the
                // position on screen, since the trailing loader is the only
                // other row and it comes after every card.
                index: index,
                onTap: () => _openProfile(doctor),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _centeredMessage(String message, {required Color color}) => Center(
        child: CustomText(
          message,
          fontSize: SizeConfig.medium,
          color: color,
        ),
      );
}
