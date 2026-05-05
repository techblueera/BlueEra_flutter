import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/add_self_work_service_screen.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/booking_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/availability_schedule_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/service_selection_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_hour_selector.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class SelfProfessionHomeScreen extends StatefulWidget {
  const SelfProfessionHomeScreen({Key? key}) : super(key: key);

  @override
  State<SelfProfessionHomeScreen> createState() =>
      _SelfProfessionHomeScreenState();
}

class _SelfProfessionHomeScreenState
    extends State<SelfProfessionHomeScreen> {
  final controller = getOrPut(() => SelfWorkServiceController());
  final bookingController = getOrPut(() => BookingController());

  @override
  void initState() {
    controller.fetchSelfProfessionData();
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
    deleteIfRegistered<SelfWorkServiceController>();
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold / SingleChildScrollView here — this screen is
    // embedded inside the parent self-employee dashboard's
    // CustomScrollView, so its sections need to flow into the
    // parent scroll. Wrapping its own scrollable would (a) bound
    // the inner content to a fixed height and (b) prevent the
    // parent's sticky-tab overlay from engaging on scroll.
    return Obx(() {
      // 1. Loading State
      if (this.controller.isProfessionDataLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor)),
        );
      }

      // 2. Empty / Not-yet-created State — show an empty profile
      final service = this.controller.professionData.value;
      if (service.sId == null || service.sId!.isEmpty) {
        return _buildEmptyProfile(service.category ?? OTHER);
      }

      // 3. Success State — editorial spec-sheet layout. Each section
        //    is a numbered card with an inline "Edit" affordance and a
        //    primary-colored vertical accent bar that ties the rhythm
        //    together with the rest of the v2 dashboard. List items
        //    render as compact chips instead of bullet rows so dense
        //    profiles read at a glance.
        this.controller.serviceId = service.sId;

        // Compute experience once so the heading and tile share state.
        int years = 0;
        int months = 0;
        bool hasExperience = false;
        final startDate = service.experienceStartDate;
        if (startDate != null && startDate.isNotEmpty) {
          final expData = calculateExperience(startDate);
          years = expData['years'] ?? 0;
          months = expData['months'] ?? 0;
          hasExperience = true;
        }

        // Build the section list dynamically so optional groups don't
        // leave numbering gaps. Each entry pairs an upper-cased label
        // with its body builder; we map them into numbered cards below.
        final sections = <_Section>[
          _Section(
            title: 'Work Photos',
            actionLabel: 'Add',
            actionIcon: Icons.add_a_photo_outlined,
            // Cap the gallery at 4 photos — once the user hits the
            // limit the section header's "Add" pill no longer fires.
            onEdit: (service.photos?.length ?? 0) >= _galleryMax
                ? null
                : () => _pickAndUploadGalleryPhoto(this.controller),
            tight: true,
            body: _galleryGrid(service.photos ?? []),
          ),
          _Section(
            title: AppStrings.price.tr,
            onEdit: () {
              final details =
                  bookingController.availabilityDetails.value?.feeDetails;
              updateBookingPrice(
                controller: bookingController,
                minFee: details?.minFee?.toString() ?? '0',
                maxFee: details?.maxFee?.toString() ?? '0',
                feeType: details?.feeType ?? '',
              );
            },
            body: Obx(() {
              final details =
                  bookingController.availabilityDetails.value?.feeDetails;
              return _priceHero(
                min: details?.minFee?.toString() ?? '0',
                max: details?.maxFee?.toString() ?? '0',
                feeType: details?.feeType ?? '',
              );
            }),
          ),
          _Section(
            title: 'Service Type',
            onEdit: () => updateServiceType(
              controller: this.controller,
              serviceType: service.serviceType ?? [],
              designation: service.category ?? ELECTRICIAN,
            ),
            body: _chipList(
              service.serviceType ?? const [],
              emptyMessage: 'Pick the services you offer.',
            ),
          ),
          _Section(
            title: 'Service Description',
            onEdit: () => updateServiceDescription(
              controller: this.controller,
              desc: service.description ?? AppStrings.na,
              designation: service.category ?? ELECTRICIAN,
              experienceStartingDate: service.experienceStartDate,
            ),
            body: _descriptionBody(service.description ?? ''),
          ),
          _Section(
            title: 'Visiting Hours',
            onEdit: () => updateVisitingHours(
              controller: bookingController,
              availabilityData: bookingController.availabilityDetails.value,
            ),
            body: bookingController.availabilityDetails.value != null
                ? AvailabilityScheduleCard(
                    schedule: bookingController
                            .availabilityDetails.value?.schedule ??
                        const [],
                  )
                : _placeholderHint('Add weekly visiting hours so customers'
                    ' know when to book.'),
          ),
          _Section(
            title: 'Work Experience',
            onEdit: () => updateWorkExperience(
              controller: this.controller,
              years: years,
              months: months,
            ),
            body: _experienceCard(
              years: years,
              months: months,
              hasExperience: hasExperience,
            ),
          ),
          // Always render the optional list sections so the user can
          // tap "Edit" on each empty card and fill them in one by
          // one. _chipList shows a friendly placeholder hint until
          // the section has data.
          _Section(
            title: 'Services Offered',
            onEdit: () => updateServiceSelectionData(
              controller: this.controller,
              key: SelfWorkServiceController.keyServicesOffered,
              designation: service.category,
              preSelectedOptions: service.serviceOffered ?? const [],
            ),
            body: _chipList(
              service.serviceOffered ?? const [],
              emptyMessage: 'Pick the services you offer to customers.',
            ),
          ),
          _Section(
            title: 'Expertise',
            onEdit: () => updateServiceSelectionData(
              controller: this.controller,
              key: SelfWorkServiceController.keyExpertise,
              designation: service.category,
              preSelectedOptions: service.expertise ?? const [],
            ),
            body: _chipList(
              service.expertise ?? const [],
              emptyMessage: 'Add the skills you specialise in.',
            ),
          ),
          _Section(
            title: 'Types of Installations',
            onEdit: () => updateServiceSelectionData(
              controller: this.controller,
              key: SelfWorkServiceController.keyTypeOfWork,
              designation: service.category,
              preSelectedOptions: service.typesOfWork ?? const [],
            ),
            body: _chipList(
              service.typesOfWork ?? const [],
              emptyMessage:
                  'List the kinds of installations you handle.',
            ),
          ),
          _Section(
            title: 'Work Categories',
            onEdit: () => updateServiceSelectionData(
              controller: this.controller,
              key: SelfWorkServiceController.keyWorkCategories,
              designation: service.category,
              preSelectedOptions: service.workCategories ?? const [],
            ),
            body: _chipList(
              service.workCategories ?? const [],
              emptyMessage: 'Pick categories that match your work.',
            ),
          ),
          _Section(
            title: 'Why Choose Me',
            onEdit: () => updateServiceSelectionData(
              controller: this.controller,
              key: SelfWorkServiceController.keyWhyChooseMe,
              designation: service.category,
              preSelectedOptions: service.whyChooseMe ?? const [],
            ),
            body: _chipList(
              service.whyChooseMe ?? const [],
              emptyMessage:
                  'Tell customers what makes you the right choice.',
            ),
          ),
        ];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < sections.length; i++) ...[
                _sectionCard(
                  index: i + 1,
                  title: sections[i].title,
                  child: sections[i].body,
                  onEdit: sections[i].onEdit,
                  actionLabel: sections[i].actionLabel,
                  actionIcon: sections[i].actionIcon,
                  tight: sections[i].tight,
                ),
                SizedBox(height: SizeConfig.size12),
              ],
            ],
          ),
        );
    });
  }

  // ─────────────────────────────────────────────
  // SECTION SHELL — numbered card with a primary-colored vertical
  // accent bar on the left edge, a tracked-uppercase title, and an
  // inline "Edit" pill on the right (or a custom action label/icon).
  // ─────────────────────────────────────────────
  Widget _sectionCard({
    required int index,
    required String title,
    required Widget child,
    VoidCallback? onEdit,
    String? actionLabel,
    IconData? actionIcon,
    bool tight = false,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left-edge accent bar — Positioned.fill stretches to the
          // card's intrinsic height without needing IntrinsicHeight,
          // which fails when the section body contains unbounded
          // children like Wrap or the schedule card.
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14 + 3,
              SizeConfig.size14,
              SizeConfig.size12,
              SizeConfig.size14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _indexBadge(index),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppConstants.OpenSans,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    if (onEdit != null)
                      _editChip(
                        onEdit,
                        label: actionLabel ?? 'Edit',
                        icon: actionIcon ?? Icons.edit_outlined,
                      ),
                  ],
                ),
                if (!tight) SizedBox(height: SizeConfig.size12),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indexBadge(int index) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.20),
          width: 0.6,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        index.toString().padLeft(2, '0'),
        style: TextStyle(
          fontFamily: AppConstants.OpenSans,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _editChip(
    VoidCallback onTap, {
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              label,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PRICE HERO — full-width frosted lavender card with a circular
  // rupee badge on the left and the live fee range hero-typed on
  // the right. The fee-type label sits as a small caption under
  // the range so the whole card reads in one glance.
  // ─────────────────────────────────────────────
  Widget _priceHero({
    required String min,
    required String max,
    required String feeType,
  }) {
    final isEmpty = (min == '0' && max == '0');
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size14,
        vertical: SizeConfig.size12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.08),
            AppColors.primaryColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              '₹',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEmpty ? '— —' : '₹$min  •  ₹$max',
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    CustomText(
                      isEmpty ? 'Min  •  Max' : 'Min  •  Max',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    if (feeType.isNotEmpty) ...[
                      SizedBox(width: SizeConfig.size8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomText(
                          feeType,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CHIP LIST — pill-shaped tags for compact list display. Replaces
  // the old bullet rows so dense profiles (10+ services, expertise
  // entries) read in a single glance instead of a long ladder.
  // ─────────────────────────────────────────────
  Widget _chipList(List<String> items, {String? emptyMessage}) {
    if (items.isEmpty) {
      return _placeholderHint(emptyMessage ?? AppStrings.na);
    }
    return Wrap(
      spacing: SizeConfig.size6,
      runSpacing: SizeConfig.size6,
      children: items
          .map(
            (item) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size10,
                vertical: SizeConfig.size5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE6E8EE),
                  width: 0.6,
                ),
              ),
              child: CustomText(
                item,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ),
          )
          .toList(),
    );
  }

  // Editorial pull-quote treatment for the description — a soft
  // background tint with a primary-colored left rule echoes the
  // section accent bar and lets long text breathe.
  Widget _descriptionBody(String desc) {
    if (desc.isEmpty || desc == AppStrings.na) {
      return _placeholderHint(
          'Add a service description so customers know your story.');
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppColors.primaryColor, width: 2.5),
        ),
      ),
      child: CustomText(
        desc,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w400,
        color: AppColors.mainTextColor,
        maxLines: 999,
      ),
    );
  }

  // Twin stat tiles — large numerals + small caption — for years
  // and months. Empty state nudges the user to add their experience.
  Widget _experienceCard({
    required int years,
    required int months,
    required bool hasExperience,
  }) {
    if (!hasExperience) {
      return _placeholderHint(
          'Add your experience so customers can gauge your expertise.');
    }
    return Row(
      children: [
        Expanded(child: _experienceTile(years.toString(), 'Years')),
        SizedBox(width: SizeConfig.size10),
        Expanded(child: _experienceTile(months.toString(), 'Months')),
      ],
    );
  }

  Widget _experienceTile(String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size12,
        horizontal: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // Soft, inviting empty-state pill shown when a section has no data
  // yet. Uses the section's accent rhythm without competing with it.
  Widget _placeholderHint(String message) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(width: SizeConfig.size6),
          Expanded(
            child: CustomText(
              message,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GALLERY — staggered masonry of work photos with a single
  // trailing "+ add" tile. Cycling pseudo-random aspect ratios
  // give the grid a portfolio feel without requiring real image
  // dimensions. When the gallery is empty the entire body collapses
  // to a single full-width prompt so the section never reads as a
  // pile of empty placeholders.
  // ─────────────────────────────────────────────
  Widget _galleryGrid(List<String> apiPhotos) {
    return GetBuilder<SelfWorkServiceController>(
      id: 'professionPhotos',
      builder: (controller) {
        final photos = controller.professionData.value.photos ?? apiPhotos;
        if (photos.isEmpty) {
          return _addGalleryTile(controller, isHero: true);
        }
        // Once the gallery is full (4 photos) we drop the trailing
        // "+ add" tile so the grid doesn't dangle a dead affordance.
        final atCapacity = photos.length >= _galleryMax;
        final tileCount = atCapacity ? photos.length : photos.length + 1;
        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: SizeConfig.size8,
          crossAxisSpacing: SizeConfig.size8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tileCount,
          itemBuilder: (context, index) {
            if (index < photos.length) {
              return _photoTile(controller, photos, index);
            }
            return _addGalleryTile(controller);
          },
        );
      },
    );
  }

  /// Maximum number of photos a self-employed user can showcase in
  /// their work-photo gallery.
  static const int _galleryMax = 4;

  // Cycles through a small set of natural-feeling aspect ratios so
  // adjacent tiles read with masonry-style variety even though we
  // don't know the real image dimensions.
  static const _galleryAspectCycle = <double>[1.0, 1.35, 0.85, 1.15];

  Widget _photoTile(
    SelfWorkServiceController controller,
    List<String> photos,
    int index,
  ) {
    final imagePath = photos[index];
    final ratio = _galleryAspectCycle[index % _galleryAspectCycle.length];
    return GestureDetector(
      onTap: () => navigatePushTo(
        context,
        ImageViewScreen(
          subTitle: '',
          appBarTitle: AppStrings.imageViewer,
          imageUrls: photos,
          initialIndex: index,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.greyE5, width: 1),
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [AppShadows.textFieldShadow],
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () async {
                await controller.deleteProfessionImage(
                    controller.professionData.value.sId ?? '', imagePath);
                controller.professionData.value.photos?.removeAt(index);
                controller.update(['professionPhotos']);
              },
              child: CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.blackMite,
                child: Icon(Icons.close, size: 14, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Trailing "+ add" tile. In hero mode (used when the gallery is
  // empty) it spans full width and shows a longer prompt; otherwise
  // it's a compact masonry tile that matches a typical photo cell.
  Widget _addGalleryTile(SelfWorkServiceController controller,
      {bool isHero = false}) {
    return GestureDetector(
      onTap: () => _pickAndUploadGalleryPhoto(controller),
      child: AspectRatio(
        aspectRatio: isHero ? 16 / 9 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: isHero ? 32 : 22,
                  color: AppColors.primaryColor.withValues(alpha: 0.75),
                ),
                if (isHero) ...[
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    'Add your first work photo',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    'Showcase your craft to attract more bookings.',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the picture-picker dialog and persists the selected photo
  /// to the gallery. Triggered from the section's "Add" pill and from
  /// the trailing add tile. Aborts if the user is already at the
  /// gallery cap so the "+ add" tile can't sneak past the limit.
  Future<void> _pickAndUploadGalleryPhoto(
      SelfWorkServiceController controller) async {
    final current = controller.professionData.value.photos?.length ?? 0;
    if (current >= _galleryMax) {
      commonSnackBar(
          message: 'You can showcase up to $_galleryMax work photos.');
      return;
    }
    final imgStr = await SelectProfilePictureDialog.showLogoDialog(
      context,
      AppStrings.gallery,
      cropAspectRatio: CropAspectRatio(width: 3, height: 4),
    );
    if (imgStr == null) return;
    await controller.saveGalleryImages(
      controller.professionData.value.sId ?? '',
      imgStr,
    );
    controller.update(['professionPhotos']);
  }

  // void _navigateToSelection({
  //   required String key,
  //   required List<String> preSelectedOptions,
  //   String? designation,
  // }
  //     ) {
  //   selfWorkServiceController.selectedCategoryMap[key]?.assignAll(preSelectedOptions);
  //   final List<String> _preSelectedOptions = selfWorkServiceController.selectedCategoryMap[key] ?? [];
  //   final _displayTitle = selfWorkServiceController.categoryTitleMap[key] ?? key;
  //
  //   Get.to(() => ServiceSelectionScreen(
  //     controller: selfWorkServiceController,
  //     designation: designation ?? ELECTRICIAN,
  //     selectedCategoryKey: key,
  //     pageTitle: _displayTitle,
  //     preSelectedOptions: _preSelectedOptions,
  //   ));
  // }

  // Empty-state CTA shown to existing users who registered before
  // the SELF_EMPLOYED auto-create branch existed. Tapping the button
  // posts a minimal earn-service row (only the four core fields), and
  // the Service tab swaps to its section cards so the user can fill
  // in the rest one by one.

  Widget _buildEmptyProfile(String designation) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.handyman_rounded,
                size: 26,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            Text(
              'Create your earn-service profile',
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size6),
            Text(
              'Set it up in one tap. You can add price, hours, '
              'expertise and more from the Service tab afterwards.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size16),
            Obx(() {
              final loading = controller.isCreateServiceLoading.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          controller.designation = designation;
                          await controller.createMinimalEarnService(
                            serviceSubType: 'selfWork',
                            designationOverride: designation,
                          );
                        },
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_rounded,
                          size: 18, color: Colors.white),
                  label: Text(
                    loading ? 'Creating…' : 'Create Earn Service',
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.size12,
                      horizontal: SizeConfig.size16,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              );
            }),
            SizedBox(height: SizeConfig.size8),
            TextButton(
              onPressed: () {
                Get.to(() => AddSelfServiceScreen(
                      designation: designation,
                      serviceSubType: 'selfWork',
                    ));
              },
              child: Text(
                'Use the full setup form instead',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Helper Widgets ---
  Widget _buildDragHandle() => Center(
        child: Container(
          width: 50,
          height: 5,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _buildHeader(String header) => Row(
        children: [
          Expanded(
            child: CustomText(
              header,
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      );

  void _showCommonUpdateSheet({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: SizeConfig.size40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              _buildHeader(title),

              // Dynamic Content
              content
            ],
          ),
        ),
      ),
    );
  }

  // void updatePrice({
  //   required String minFee
  //   required String maxFee}) {
  //   final minFeeController = TextEditingController(text: minFee);
  //   final maxFeeController = TextEditingController(text: maxFee);
  //   final feeTypeController = TextEditingController(text: maxFee);
  //
  //   _showCommonUpdateSheet(
  //     context: context,
  //     title: AppStrings.price,
  //     onUpdate: () {
  //       Navigator.pop(context);
  //     },
  //     content: Column(
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 textEditController: minFeeController,
  //                 fontSize: SizeConfig.small,
  //                 fontWeight: FontWeight.w400,
  //                 titleColor: AppColors.mainTextColor,
  //                 hintText: "Min - ₹500",
  //                 keyBoardType: TextInputType.number,
  //               ),
  //             ),
  //             SizedBox(width: SizeConfig.paddingXSL),
  //             Expanded(
  //               child: CommonTextField(
  //                 textEditController: maxFeeController,
  //                 fontSize: SizeConfig.small,
  //                 fontWeight: FontWeight.w400,
  //                 titleColor: AppColors.mainTextColor,
  //                 hintText: "Max - ₹600",
  //                 keyBoardType: TextInputType.number,
  //               ),
  //             ),
  //           ],
  //         ),
  //        SizedBox(height: SizeConfig.paddingL),
  //
  //         /// Fee Type
  //         CommonTextField(
  //           textEditController: feeTypeController,
  //           title: 'Fee Type',
  //           fontSize: SizeConfig.small,
  //           fontWeight: FontWeight.w400,
  //           titleColor: AppColors.mainTextColor,
  //           hintText: "E.g. Per Visit",
  //           keyBoardType: TextInputType.text,
  //         ),
  //
  //         SizedBox(height: SizeConfig.paddingL),
  //
  //         // Common Update Button
  //         CustomBtn(
  //           radius: SizeConfig.size10,
  //           bgColor: AppColors.primaryColor,
  //           title: AppStrings.update,
  //           onTap: (){},
  //         ),
  //
  //       ],
  //     ),
  //   );
  // }

  void updateServiceType({
    required SelfWorkServiceController controller,
    required List<String> serviceType,
    required String designation,
  }) {
    controller.fetchPredefinedCategoryServiceType(
        designation: designation,
        selectedServiceKey: SelfWorkServiceController.keyServiceTypes);

    controller.selectedServiceTypes.assignAll(serviceType);

    _showCommonUpdateSheet(
      context: context,
      title: 'Service Type',
      onUpdate: () {
        Navigator.pop(context);
      },
      content: Column(
        children: [
          Obx(() {
            if (controller.isPredefinedCategoryServiceTypeLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (controller.serviceTypes.isEmpty) {
              return Center(
                  child: CustomText("No service types available",
                      color: AppColors.secondaryTextColor));
            }

            return Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size4, vertical: SizeConfig.size8),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5),
                  boxShadow: [AppShadows.textFieldShadow]),
              child: Column(
                children: controller.serviceTypes.map((item) {
                  // Check if this specific item is selected
                  final isSelected =
                      controller.selectedServiceTypes.contains(item);

                  return Theme(
                    data:
                        ThemeData(unselectedWidgetColor: Colors.grey.shade300),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity:
                          const VisualDensity(horizontal: -4, vertical: -3),
                      dense: true,
                      activeColor: AppColors.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: CustomText(
                        item,
                        fontSize: SizeConfig.medium,
                        color: AppColors.secondaryTextColor,
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        if (val == true) {
                          controller.selectedServiceTypes.add(item);
                        } else {
                          controller.selectedServiceTypes.remove(item);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          SizedBox(height: SizeConfig.paddingL),
          Obx(() => CustomBtn(
                radius: SizeConfig.size10,
                bgColor: AppColors.primaryColor,
                // Fixed logic: Title should show 'Update' unless handled internally by isLoading
                title: controller.isUpdateServiceLoading.value
                    ? null
                    : AppStrings.update,
                isLoading: controller.isUpdateServiceLoading.value,
                onTap: () {
                  if (controller.selectedServiceTypes.isEmpty) {
                    commonSnackBar(message: 'Please select a service type');
                    return;
                  }

                  Map<String, dynamic> params = {
                    ApiKeys.serviceType: controller.selectedServiceTypes,
                  };

                  controller.updateEarnServiceData(params: params);
                },
              )),
        ],
      ),
    );
  }

  void updateServiceDescription({
    required SelfWorkServiceController controller,
    required String desc,
    required String designation,
    String? experienceStartingDate,
  }) {
    // Initialize controllers
    controller.aboutController.text = desc;

    _showCommonUpdateSheet(
      context: context,
      title: 'Service Description',
      onUpdate: () {
        Navigator.pop(context); // Close sheet
      },
      content: Column(
        children: [
          if (experienceStartingDate != null) ...[
            Obx(() => Align(
                  alignment: Alignment.centerRight,
                  child: !controller.isGenerateDescLoading.value
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                              onTap: () {
                                final expData =
                                    calculateExperience(experienceStartingDate);

                                final int years = expData['years']!;
                                final int months = expData['months']!;

                                controller.generateDescriptions(bodyRequest: {
                                  ApiKeys.category: designation,
                                  ApiKeys.expYears: years,
                                  ApiKeys.expMonths: months,
                                });
                              },
                              child: LocalAssets(
                                height: 25,
                                width: 25,
                                imgColor: AppColors.primaryColor,
                                imagePath: AppIconAssets.ai_generative,
                              )),
                        )
                      : SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          )),
                )),
            SizedBox(height: SizeConfig.size8),
          ],

          CommonTextField(
              textEditController: controller.aboutController,
              maxLine: 4,
              hintText: "Horem ipsum dolor sit amet, consectetur adipiscing...",
              maxLength: 250,
              isCounterVisible: true,
              isValidate: true,
              validator: ValidationMethod().professionDescValidation),

          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          CustomBtn(
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            title: controller.isUpdateServiceLoading.value
                ? AppStrings.update
                : null,
            isLoading: controller.isUpdateServiceLoading.value,
            onTap: () {
              Map<String, dynamic> params = {
                ApiKeys.description: controller.aboutController.text.trim()
              };

              controller.updateEarnServiceData(params: params);
            },
          ),
        ],
      ),
    );
  }

  void updateWorkExperience({
    required SelfWorkServiceController controller,
    int? years,
    int? months,
  }) {
    controller.selectedExperienceYear.value = years.toString();
    controller.selectedExperienceMonth.value = months.toString();

    // 2. Show Sheet
    _showCommonUpdateSheet(
      context: context,
      title: 'Your Experience',
      onUpdate: () {
        // Your API Logic
        // controller.updateSchedule(...);
        Navigator.pop(context);
      },
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(AppStrings.years,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdown<String>(
                      items: controller.experienceYears,
                      selectedValue: controller.selectedExperienceYear.value,
                      hintText: "E.g 1 Year..",
                      onChanged: (val) {
                        controller.selectedExperienceYear.value = val;
                        log('val -- $val');
                        log('experience -- ${controller.selectedExperienceYear.value}');
                      },
                      displayValue: (val) => val,
                    ),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText('Months',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdown<String>(
                      items: controller.experienceMonths,
                      selectedValue: controller.selectedExperienceMonth.value,
                      hintText: "E.g 3 Months..",
                      onChanged: (val) =>
                          controller.selectedExperienceMonth.value = val,
                      displayValue: (val) => val,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          CustomBtn(
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            title: controller.isUpdateServiceLoading.value
                ? AppStrings.update
                : null,
            isLoading: controller.isUpdateServiceLoading.value,
            onTap: () {
              if (controller.selectedExperienceYear.value == null) {
                commonSnackBar(message: 'Please select experience (Years)');
                return;
              }

              if (controller.selectedExperienceMonth.value == null) {
                commonSnackBar(message: 'Please select experience (Months)');
                return;
              }

              Map<String, dynamic> params = {
                ApiKeys.experience: {
                  ApiKeys.years: controller.selectedExperienceYear.value,
                  ApiKeys.months: controller.selectedExperienceMonth.value,
                },
              };

              controller.updateEarnServiceData(params: params);
            },
          ),
        ],
      ),
    );
  }

  void updateBookingPrice(
      {required BookingController controller,
      required String minFee,
      required String maxFee,
      required String feeType}) {
    // 2. Show Sheet
    _showCommonUpdateSheet(
      context: context,
      title: 'Your Fee',
      onUpdate: () {
        Navigator.pop(context);
      },
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(AppStrings.min,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      textEditController: controller.minFeeController,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "Min - ₹500",
                      keyBoardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.paddingXSL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(AppStrings.max,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      textEditController: controller.maxFeeController,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "Max - ₹600",
                      keyBoardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: SizeConfig.paddingM),

          /// Fee Type
          CommonTextField(
            textEditController: controller.feeTypeController,
            title: 'Fee Type',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w400,
            titleColor: AppColors.mainTextColor,
            hintText: "E.g. Per Visit",
            keyBoardType: TextInputType.text,
          ),
          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          CustomBtn(
            title: controller.addUpdateAvailabilityResponse.value.status ==
                    Status.INITIAL
                ? null
                : AppStrings.update,
            isLoading: controller.addUpdateAvailabilityResponse.value.status ==
                Status.INITIAL,
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            onTap: () {
              Map<String, dynamic> params = {
                ApiKeys.minFee: controller.minFeeController.text.trim(),
                ApiKeys.maxFee: controller.maxFeeController.text.trim(),
                ApiKeys.feeType: controller.feeTypeController.text.trim(),
              };
              controller.updateBookingAvailability(id: userId, params: params);
            },
          ),
        ],
      ),
    );
  }

  void updateVisitingHours(
      {required BookingController controller,
      AvailabilityData? availabilityData}) {
    // 1. Sync Data Logic
    controller.syncScheduleToController(availabilityData?.schedule);

    // 2. Show Sheet
    _showCommonUpdateSheet(
      context: context,
      title: 'Visiting Hours',
      onUpdate: () {
        Navigator.pop(context);
      },
      content: Column(
        children: [
          VisitingHoursSelector(),
          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          CustomBtn(
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            title: controller.addUpdateAvailabilityResponse.value.status ==
                    Status.INITIAL
                ? null
                : AppStrings.update,
            isLoading: controller.addUpdateAvailabilityResponse.value.status ==
                Status.INITIAL,
            onTap: () {
              List<Map<String, dynamic>> visitingHoursData =
                  bookingController.payloadForVisitingHours();
              logs("Visiting Hours: $visitingHoursData");

              Map<String, dynamic> params = {
                ApiKeys.schedule: visitingHoursData,
              };
              controller.updateBookingAvailability(id: userId, params: params);
            },
          ),
        ],
      ),
    );
  }

  void updateServiceSelectionData({
    required SelfWorkServiceController controller,
    required String key,
    required List<String> preSelectedOptions,
    String? designation,
  }) {
    final _displayTitle = controller.categoryTitleMap[key] ?? key;

    _showCommonUpdateSheet(
      context: context,
      title: _displayTitle,
      onUpdate: () {
        Navigator.pop(context); // Close sheet
      },
      content: ServiceSelectionScreen(
          controller: controller,
          designation: designation ?? ELECTRICIAN,
          selectedCategoryKey: key,
          pageTitle: _displayTitle,
          preSelectedOptions: preSelectedOptions,
          isDataUpdate: true),
    );
  }
}

/// Lightweight value-type used to declare each profile section in a
/// single list, then render them as numbered cards. Keeps the build
/// method's structure flat and conditional sections from leaving
/// numbering gaps.
class _Section {
  final String title;
  final Widget body;
  final VoidCallback? onEdit;
  final String? actionLabel;
  final IconData? actionIcon;

  /// When `true`, the section card collapses the gap between the
  /// header row and the body — used by the gallery so its photos
  /// sit right under the title without a stray strip of whitespace.
  final bool tight;

  const _Section({
    required this.title,
    required this.body,
    this.onEdit,
    this.actionLabel,
    this.actionIcon,
    this.tight = false,
  });
}
