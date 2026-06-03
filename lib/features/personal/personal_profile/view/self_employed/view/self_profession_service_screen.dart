import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
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
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/availability_schedule_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/service_selection_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/working_hours_editor.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelfProfessionServiceScreen extends StatefulWidget {
  const SelfProfessionServiceScreen({Key? key}) : super(key: key);

  @override
  State<SelfProfessionServiceScreen> createState() =>
      _SelfProfessionServiceScreenState();
}

class _SelfProfessionServiceScreenState
    extends State<SelfProfessionServiceScreen> {
  final controller = getOrPut(() => SelfWorkServiceController());

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
        return _buildEmptyProfile(userProfessionGlobal);
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
          hasData: (service.photos?.length ?? 0) > 0,
          onEdit: (service.photos?.length ?? 0) >= _galleryMax
              ? null
              : () => _pickAndUploadGalleryPhoto(this.controller),
          tight: true,
          body: _galleryGrid(service.photos ?? []),
        ),
        _Section(
          title: 'Working Hours',
          hasData: service.schedule?.isNotEmpty ?? false,
          onEdit: () => updateVisitingHours(),
          // Empty vs. populated is handled inside the card itself,
          // mirroring `_buildTimingsSection` on the consultant screen
          // — so the section just hands over the schedule and the
          // same edit action for the empty-state CTA.
          body: AvailabilityScheduleCard(
            schedule: service.schedule ?? const [],
            onAdd: updateVisitingHours,
          ),
        ),
        _Section(
          title: AppStrings.price.tr,
          // Price counts as "added" when either bound is non-zero —
          // matches the `isEmpty` rule the price hero itself uses.
          hasData: (service.feeDetails?.minFee ?? 0) > 0 ||
              (service.feeDetails?.maxFee ?? 0) > 0,
          onEdit: () {
            this.controller.seedPriceInputsFromProfession();
            updateBookingPrice();
          },
          body: Obx(() {
            final details =
                this.controller.professionData.value.feeDetails;
            return _priceHero(
              min: details?.minFee?.toString() ?? '0',
              max: details?.maxFee?.toString() ?? '0',
              feeType: details?.feeType ?? '',
            );
          }),
        ),
        _Section(
          title: 'Service Type',
          hasData: service.serviceType?.isNotEmpty ?? false,
          onEdit: () => updateServiceType(
            controller: this.controller,
            serviceType: service.serviceType ?? [],
            professionCategory: service.category ?? ELECTRICIAN,
          ),
          body: _chipList(
            service.serviceType ?? const [],
            emptyMessage: 'Pick the services you offer.',
          ),
        ),
        _Section(
          title: 'Service Description',
          hasData: service.description?.isNotEmpty ?? false,
          onEdit: () => updateServiceDescription(
            controller: this.controller,
            desc: service.description ?? AppStrings.na,
            designation: service.category ?? ELECTRICIAN,
            experienceStartingDate: service.experienceStartDate,
          ),
          body: _descriptionBody(service.description ?? ''),
        ),
        _Section(
          title: 'Work Experience',
          hasData: hasExperience,
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
        // tap "Add" on each empty card and fill them in one by
        // one. _chipList shows a friendly placeholder hint until
        // the section has data.
        _Section(
          title: 'Services Offered',
          hasData: service.serviceOffered?.isNotEmpty ?? false,
          onEdit: () => updateServiceSelectionData(
            controller: this.controller,
            key: SelfWorkServiceController.keyServicesOffered,
            professionCategory: service.category,
            preSelectedOptions: service.serviceOffered ?? const [],
          ),
          body: _chipList(
            service.serviceOffered ?? const [],
            emptyMessage: 'Pick the services you offer to customers.',
          ),
        ),
        _Section(
          title: 'Expertise',
          hasData: service.expertise?.isNotEmpty ?? false,
          onEdit: () => updateServiceSelectionData(
            controller: this.controller,
            key: SelfWorkServiceController.keyExpertise,
            professionCategory: service.category,
            preSelectedOptions: service.expertise ?? const [],
          ),
          body: _chipList(
            service.expertise ?? const [],
            emptyMessage: 'Add the skills you specialise in.',
          ),
        ),
        _Section(
          title: 'Types of Installations',
          hasData: service.typesOfWork?.isNotEmpty ?? false,
          onEdit: () => updateServiceSelectionData(
            controller: this.controller,
            key: SelfWorkServiceController.keyTypeOfWork,
            professionCategory: service.category,
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
          hasData: service.workCategories?.isNotEmpty ?? false,
          onEdit: () => updateServiceSelectionData(
            controller: this.controller,
            key: SelfWorkServiceController.keyWorkCategories,
            professionCategory: service.category,
            preSelectedOptions: service.workCategories ?? const [],
          ),
          body: _chipList(
            service.workCategories ?? const [],
            emptyMessage: 'Pick categories that match your work.',
          ),
        ),
        _Section(
          title: 'Why Choose Me',
          hasData: service.whyChooseMe?.isNotEmpty ?? false,
          onEdit: () => updateServiceSelectionData(
            controller: this.controller,
            key: SelfWorkServiceController.keyWhyChooseMe,
            professionCategory: service.category,
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
                tight: sections[i].tight,
                hasData: sections[i].hasData,
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
    bool tight = false,
    bool hasData = true,
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
                        label: hasData ? AppStrings.edit.tr : AppStrings.edit.tr,
                        icon: hasData
                            ? Icons.edit_outlined
                            : Icons.add_rounded,
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
  // GALLERY — uniform 2-column square grid. Every tile shares the
  // same 1:1 aspect ratio so the grid reads as a calm spec-sheet
  // strip rather than a masonry portfolio. When the gallery is empty
  // the entire body collapses to a single full-width prompt so the
  // section never reads as a pile of empty placeholders.
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
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: SizeConfig.size8,
            crossAxisSpacing: SizeConfig.size8,
            childAspectRatio: 1.0,
          ),
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

  Widget _photoTile(
      SelfWorkServiceController controller,
      List<String> photos,
      int index,
      ) {
    final imagePath = photos[index];
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
          // The grid delegate sizes the cell to a 1:1 aspect ratio,
          // so the tile just fills it — no inner AspectRatio needed.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
  Future<void> _pickAndUploadGalleryPhoto(
      SelfWorkServiceController controller) async {
    final current = controller.professionData.value.photos?.length ?? 0;
    if (current >= _galleryMax) {
      commonSnackBar(
          message: 'You can showcase up to $_galleryMax work photos.');
      return;
    }
    final imgStr = await PhotoPickerService.pickSinglePhoto(
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

  // Empty-state CTA shown to existing users who registered before
  // the SELF_EMPLOYED auto-create branch existed. Tapping the button
  // posts a minimal earn-service row (only the four core fields), and
  // the Service tab swaps to its section cards so the user can fill
  // in the rest one by one.

  Widget _buildEmptyProfile(String professionCategory) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                    controller.professionCategory = professionCategory;
                    await controller.createMinimalEarnService(
                      serviceSubType: 'selfWork',
                      professionCategoryOverride: professionCategory,
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
                  professionCategory: professionCategory,
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
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        // Read viewInsets from the sheet's own context — the outer
        // screen's MediaQuery doesn't update when the keyboard opens
        // inside the modal, which is why the inputs were hiding behind
        // the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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

  // ─── SERVICE TYPE PICKER ─────────────────────────────────────
  // "Numbered Spec Sheet" multi-select. Each row carries a 01/02/…
  // index (echoing the parent section cards' numbered rhythm), the
  // service name, and a custom rounded-square selection box. Selected
  // rows wear a soft primary tint + a check inside the box; the
  // sheet header shows a live "N / Total" pill, and the Update button
  // appends "· N selected" so the count reads at all three altitudes
  // (header → row → CTA).
  void updateServiceType({
    required SelfWorkServiceController controller,
    required List<String> serviceType,
    required String professionCategory,
  }) {
    controller.fetchPredefinedCategoryServiceType(
        professionCategory: professionCategory,
        selectedServiceKey: SelfWorkServiceController.keyServiceTypes);
    controller.selectedServiceTypes.assignAll(serviceType);

    _showCommonUpdateSheet(
      context: context,
      title: 'Service Type',
      onUpdate: () => Navigator.pop(context),
      content: Column(
        children: [
          Obx(() {
            if (controller.isPredefinedCategoryServiceTypeLoading.value) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size32),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryColor),
                ),
              );
            }
            if (controller.serviceTypes.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size24),
                child: Center(
                  child: CustomText(
                    "No service types available",
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              );
            }
            return _serviceTypePicker(controller);
          }),
          SizedBox(height: SizeConfig.paddingL),
          Obx(() {
            final selectedCount = controller.selectedServiceTypes.length;
            final isLoading = controller.isUpdateServiceLoading.value;
            return CustomBtn(
              radius: SizeConfig.size10,
              bgColor: AppColors.primaryColor,
              title: isLoading
                  ? null
                  : (selectedCount > 0
                  ? '${AppStrings.update} · $selectedCount selected'
                  : AppStrings.update),
              isLoading: isLoading,
              onTap: () {
                if (controller.selectedServiceTypes.isEmpty) {
                  commonSnackBar(message: 'Please select a service type');
                  return;
                }
                controller.updateEarnServiceData(params: {
                  ApiKeys.serviceType: controller.selectedServiceTypes,
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _serviceTypePicker(SelfWorkServiceController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip — uppercase eyebrow + live N / Total pill.
          Obx(() {
            final selected = controller.selectedServiceTypes.length;
            final total = controller.serviceTypes.length;
            final any = selected > 0;
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14,
                vertical: SizeConfig.size10,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFBFE),
                border: Border(
                  bottom:
                  BorderSide(color: Color(0xFFE6E8EE), width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'SERVICE TYPES',
                      style: TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryTextColor,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: any
                          ? AppColors.primaryColor.withValues(alpha: 0.10)
                          : const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: any
                            ? AppColors.primaryColor.withValues(alpha: 0.25)
                            : const Color(0xFFE6E8EE),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      '$selected / $total',
                      style: TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: any
                            ? AppColors.primaryColor
                            : AppColors.secondaryTextColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Numbered rows. The list itself is short (≤20 items) and the
          // outer sheet handles scrolling, so a plain Column keeps the
          // numbering deterministic across rebuilds.
          Obx(() {
            final items = controller.serviceTypes;
            return Column(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isSelected =
                controller.selectedServiceTypes.contains(item);
                final isLast = i == items.length - 1;
                return _serviceTypeRow(
                  index: i + 1,
                  label: item,
                  isSelected: isSelected,
                  showDivider: !isLast,
                  onTap: () {
                    if (isSelected) {
                      controller.selectedServiceTypes.remove(item);
                    } else {
                      controller.selectedServiceTypes.add(item);
                    }
                  },
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _serviceTypeRow({
    required int index,
    required String label,
    required bool isSelected,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withValues(alpha: 0.06)
                : Colors.transparent,
            border: showDivider
                ? const Border(
              bottom:
              BorderSide(color: Color(0xFFEDEFF4), width: 0.6),
            )
                : null,
          ),
          child: Row(
            children: [
              // 01 / 02 / … — tracks the parent section-card rhythm.
              SizedBox(
                width: 26,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor
                        .withValues(alpha: 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText(
                  label,
                  fontSize: SizeConfig.medium,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color:
                  isSelected ? AppColors.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor
                        .withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: isSelected
                      ? const Icon(
                    Icons.check_rounded,
                    key: ValueKey('checked'),
                    size: 14,
                    color: Colors.white,
                  )
                      : const SizedBox.shrink(key: ValueKey('unchecked')),
                ),
              ),
            ],
          ),
        ),
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
                ? null
                : AppStrings.update,
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
                ? null
                : AppStrings.update,
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

  // ─── PRICE UPDATE SHEET ──────────────────────────────────────
  void updateBookingPrice() {
    _showCommonUpdateSheet(
      context: context,
      title: 'Your Fee',
      onUpdate: () => Navigator.pop(context),
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

          // Common Update Button — drives off the earn-service
          // controller's own loading flag.
          Obx(() {
            final isLoading = controller.isUpdateServiceLoading.value;
            return CustomBtn(
              title: isLoading ? null : AppStrings.update,
              isLoading: isLoading,
              radius: SizeConfig.size10,
              bgColor: AppColors.primaryColor,
              onTap: () {
                final minFee =
                    int.tryParse(controller.minFeeController.text.trim()) ?? 0;
                final maxFee =
                    int.tryParse(controller.maxFeeController.text.trim()) ?? 0;
                final params = <String, dynamic>{
                  ApiKeys.priceRange: {
                    ApiKeys.min: minFee,
                    ApiKeys.max: maxFee,
                  },
                  ApiKeys.feeType: controller.feeTypeController.text.trim(),
                };
                controller.updateEarnServiceData(params: params);
              },
            );
          }),
        ],
      ),
    );
  }

  // ─── WORKING HOURS UPDATE SHEET ──────────────────────────────
  void updateVisitingHours() {
    controller.syncWorkingHoursFromProfession();

    _showCommonUpdateSheet(
      context: context,
      title: 'Working Hours',
      onUpdate: () => Navigator.pop(context),
      content: Column(
        children: [
          const WorkingHoursEditor(),
          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          Obx(() {
            final isLoading = controller.isUpdateServiceLoading.value;
            return CustomBtn(
              radius: SizeConfig.size10,
              bgColor: AppColors.primaryColor,
              title: isLoading ? null : AppStrings.update,
              isLoading: isLoading,
              onTap: () {
                final payload = controller.payloadForWorkingHours();
                logs("Working Hours: $payload");
                controller.updateEarnServiceData(
                  params: {
                    ApiKeys.availability: {ApiKeys.schedule: payload},
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }

  void updateServiceSelectionData({
    required SelfWorkServiceController controller,
    required String key,
    required List<String> preSelectedOptions,
    String? professionCategory,
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
          professionCategory: professionCategory ?? ELECTRICIAN,
          selectedCategoryKey: key,
          preSelectedOptions: preSelectedOptions),
    );
  }
}

class _Section {
  final String title;
  final Widget body;
  final VoidCallback? onEdit;

  /// When `true`, the section card collapses the gap between the
  /// header row and the body — used by the gallery so its photos
  /// sit right under the title without a stray strip of whitespace.
  final bool tight;

  /// Drives the action-chip's label/icon: when `true` the chip reads
  /// "Edit" (pencil); when `false` it reads "Add" (plus).
  final bool hasData;

  const _Section({
    required this.title,
    required this.body,
    this.onEdit,
    this.tight = false,
    this.hasData = true,
  });
}

