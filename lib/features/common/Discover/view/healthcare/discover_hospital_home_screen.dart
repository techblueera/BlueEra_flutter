import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_contact_us_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/managment_card_widget.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/features/me/medical/controller/healthcare_enquiry_controller.dart';
import 'package:BlueEra/features/me/medical/widget/healthcare_enquiry_sheet.dart';
import 'package:BlueEra/features/me/medical/widget/hospital_appointment_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverHospitalHomeScreen extends StatefulWidget {
  const DiscoverHospitalHomeScreen({super.key});

  @override
  State<DiscoverHospitalHomeScreen> createState() => _DiscoverHospitalHomeScreenState();
}

class _DiscoverHospitalHomeScreenState extends State<DiscoverHospitalHomeScreen> {
  final controller = Get.find<HospitalServiceAiController>();
  final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
  final storeController = getOrPut(() => StoreController());

  /// Tracks whether the full hospital profile has finished loading at least
  /// once. Gates the first-load shimmer so pull-to-refresh keeps the existing
  /// content on screen instead of flashing back to the skeleton.
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    final id = controller.hospitalDataResModel?.value.data?.id ?? '';
    if (id.isNotEmpty) {
      _loadVisitedHospitalDetails(id);
      ProfileClickTracker.track(
        userId: id,
        source: ChatClickSource.searchResult,
      );
    }
  }

  /// Loads the visited hospital's profile and merges its OPD/IPD,
  /// management, gallery and emergency/other-facility sections into
  /// [HospitalServiceAiController.hospitalDataResModel].
  ///
  /// The list adapter that seeded the model (`toHospitalFullData()`)
  /// leaves those hospital-specific sections null, so they only become
  /// available from the full `viewBusinessProfileById` response.
  Future<void> _loadVisitedHospitalDetails(String id) async {
    await viewBusinessDetailsController.viewBusinessProfileById(id);
    _mergeHospitalSectionsFromBusinessProfile();
    if (mounted) setState(() => _hasLoadedOnce = true);
  }

  /// Parses [HospitalFullData] out of the raw `viewBusinessProfileById`
  /// response and merges the hospital-only sections onto the existing
  /// model, preserving the list-card fields (name/logo/cover/location)
  /// already on screen.
  void _mergeHospitalSectionsFromBusinessProfile() {
    final raw = viewBusinessDetailsController.viewBusinessResponseNew.data?.response?.data;
    _debugDumpKeys(raw);
    final hospitalJson = _extractHospitalJson(raw);
    if (hospitalJson == null) {
      debugPrint('[DiscoverHospital] no hospital JSON found in response');
      return;
    }

    final parsed = HospitalFullData.fromJson(hospitalJson);
    debugPrint('[DiscoverHospital] parsed departments=${parsed.departments?.length} '
        'types=${parsed.departments?.map((d) => d.type).toList()} '
        'management=${parsed.management?.length} gallery=${parsed.gallery?.length} '
        'emergencyCare=${parsed.emergencyCare != null} '
        'otherFacilities=${parsed.otherFacilities != null}');
    final existing = controller.hospitalDataResModel?.value.data;

    final merged = existing == null
        ? parsed
        : (existing
          // Backfill identity fields the list card normally seeds. On a
          // deep-link / QR cold start the model is seeded with only the id
          // (see splash `_openHospital`), so name/userId/logo/cover would
          // otherwise stay null — breaking the header title and the
          // "Inquiry" button (which needs userId as the owner id). Keep any
          // existing value (avoids flashing the in-app list card) and fall
          // back to the parsed full-profile value.
          ..name = (existing.name?.isNotEmpty ?? false) ? existing.name : parsed.name
          ..userId = (existing.userId?.isNotEmpty ?? false) ? existing.userId : parsed.userId
          ..logoUrl = (existing.logoUrl?.isNotEmpty ?? false) ? existing.logoUrl : parsed.logoUrl
          ..coverUrl = (existing.coverUrl?.isNotEmpty ?? false) ? existing.coverUrl : parsed.coverUrl
          ..departments = parsed.departments ?? existing.departments
          ..management = parsed.management ?? existing.management
          ..gallery = parsed.gallery ?? existing.gallery
          ..emergencyCare = parsed.emergencyCare ?? existing.emergencyCare
          ..otherFacilities = parsed.otherFacilities ?? existing.otherFacilities
          ..emergencyContactData = parsed.emergencyContactData ?? existing.emergencyContactData
          ..contacts = (parsed.contacts?.isNotEmpty ?? false) ? parsed.contacts : existing.contacts
          ..description =
              (parsed.description?.isNotEmpty ?? false) ? parsed.description : existing.description);

    controller.hospitalDataResModel?.value = HospitalFullDetailsResModel(success: true, data: merged);

    // Cache the OPD doctors as soon as the full profile lands — the
    // customer can tap "Inquiry" the instant the button appears (which
    // is gated only on `userId`, not on the departments merge), so
    // caching lazily inside `_openHospitalEnquirySheet` alone would
    // sometimes register an empty list before departments arrive. See
    // lib/docs/healthcare-appointment-ui-integration.md §0.
    final mergedId = (merged.id ?? '').trim();
    if (mergedId.isNotEmpty) {
      final doctors = _doctorsForAppointment(merged);
      HospitalAppointmentSheet.cacheDoctorsForHospital(mergedId, doctors);
      debugPrint('[DiscoverHospital] cached ${doctors.length} OPD doctor(s) '
          'for hospitalId=$mergedId');
    }
  }

  /// TEMP: prints the response key structure so we can locate where the
  /// hospital sections (departments/management/gallery/...) actually sit.
  void _debugDumpKeys(dynamic raw) {
    if (raw is! Map) {
      debugPrint('[DiscoverHospital] raw is not a Map: ${raw.runtimeType}');
      return;
    }
    debugPrint('[DiscoverHospital] root keys: ${raw.keys.toList()}');
    raw.forEach((k, v) {
      if (k == 'data') return;
      if (v is Map) {
        debugPrint('[DiscoverHospital] root.$k keys: ${v.keys.toList()}');
      } else if (v is List) {
        final first = v.isNotEmpty ? v.first : null;
        debugPrint('[DiscoverHospital] root.$k is List(len=${v.length}) '
            'firstKeys=${first is Map ? first.keys.toList() : first?.runtimeType}');
      }
    });
    final vp = raw['vertical_profile'];
    if (vp is Map && vp['data'] is Map) {
      final vpData = vp['data'] as Map;
      debugPrint('[DiscoverHospital] vertical_profile.data keys: ${vpData.keys.toList()}');
      vpData.forEach((k, v) {
        if (v is List) {
          final first = v.isNotEmpty ? v.first : null;
          debugPrint('[DiscoverHospital]   vp.data.$k is List(len=${v.length}) '
              'firstKeys=${first is Map ? first.keys.toList() : first?.runtimeType}');
        } else if (v is Map) {
          debugPrint('[DiscoverHospital]   vp.data.$k keys: ${v.keys.toList()}');
        }
      });
    }
    final data = raw['data'];
    if (data is Map) {
      debugPrint('[DiscoverHospital] data keys: ${data.keys.toList()}');
      data.forEach((k, v) {
        if (v is Map) {
          debugPrint('[DiscoverHospital]   data.$k keys: ${v.keys.toList()}');
        } else if (v is List) {
          final first = v.isNotEmpty ? v.first : null;
          debugPrint('[DiscoverHospital]   data.$k is List(len=${v.length}) '
              'firstKeys=${first is Map ? first.keys.toList() : first?.runtimeType}');
        }
      });
    }
  }

  /// Hospital fields read by [HospitalFullData.fromJson].
  static const _hospitalKeys = <String>[
    '_id',
    'name',
    'description',
    'userId',
    'location',
    'coverUrl',
    'logoUrl',
    'visionMission',
    'history',
    'management',
    'departments',
    'emergencyCare',
    'otherFacilities',
    'emergencyContact',
    'gallery',
    'contacts',
  ];

  /// Builds the hospital JSON from the business-profile response. The
  /// sections can live at the root, under `data`, or under an explicit
  /// `hospital`/`hospitalDetails` key — and not necessarily all in the
  /// same container — so each key is taken from the first container that
  /// actually carries it rather than committing to one object.
  Map<String, dynamic>? _extractHospitalJson(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    final vp = raw['vertical_profile'];
    final containers = <Map>[
      // Vertical-specific profile is where hospital sections live:
      // `vertical_profile.data.{departments,management,gallery,...}`.
      if (vp is Map && vp['data'] is Map) vp['data'],
      if (vp is Map) vp,
      if (raw['hospital'] is Map) raw['hospital'],
      if (raw['hospitalDetails'] is Map) raw['hospitalDetails'],
      if (data is Map && data['hospital'] is Map) data['hospital'],
      if (data is Map && data['hospitalDetails'] is Map) data['hospitalDetails'],
      if (data is Map) data,
      raw,
    ];

    final merged = <String, dynamic>{};
    for (final key in _hospitalKeys) {
      for (final c in containers) {
        if (c.containsKey(key) && c[key] != null) {
          merged[key] = c[key];
          break;
        }
      }
    }
    return merged.isEmpty ? null : merged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.whiteE5,
      bottomNavigationBar: _buildBottomBar(),
      appBar: CommonBackAppBar(
        title: AppStrings.hospital.tr,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          final id = controller.hospitalDataResModel?.value.data?.id ?? '';
          if (id.isNotEmpty) {
            await _loadVisitedHospitalDetails(id);
          }
        },
        child: Obx(() {
          final isProfileLoading = viewBusinessDetailsController.isProfileLoading.value;
          final data = controller.hospitalDataResModel?.value.data;

          /// First-load shimmer: keep the skeleton until the full profile
          /// has merged once, so the OPD/management/gallery sections don't
          /// briefly flash their empty states while the request is in flight.
          if (isProfileLoading && !_hasLoadedOnce) {
            return _buildLoadingShimmer();
          }

          if (data == null) {
            return _buildFullEmptyState();
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER — shared business profile header. Same layout
                /// as lab / medical detail screens: banner + logo +
                /// rating / follow / share row + address + availability.
                /// Rating and follow/unfollow re-fetch the business
                /// profile silently so counts stay in sync without a
                /// full-screen shimmer.
                Obx(() {
                  viewBusinessDetailsController.profileVersion.value;
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return buildBusinessHeaderSkeleton();
                  }
                  final details = viewBusinessDetailsController
                      .visitedBusinessProfileDetails?.data;
                  final businessId =
                      controller.hospitalDataResModel?.value.data?.id ?? '';
                  return Padding(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: VisitBusinessCommonHeader(
                      details: details,
                      onRated: () => viewBusinessDetailsController
                          .viewBusinessProfileById(businessId, silent: true),
                      onFollowChanged: () => viewBusinessDetailsController
                          .viewBusinessProfileById(businessId, silent: true),
                    ),
                  );
                }),

                // Only horizontal padding here — the shared header (above)
                // and the next section's card (below) already carry the
                // 10dp CommonCardWidget margin, so any vertical padding
                // here stacks on top of it and reads as an extra empty
                // band on the screen.
                Obx(() {
                  viewBusinessDetailsController.profileVersion.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: VisitBusinessStatsCard(
                      details: viewBusinessDetailsController.visitedBusinessProfileDetails?.data,
                    ),
                  );
                }),

                /// EMERGENCY ACTION CARDS
                _buildEmergencyActionCards(),

                /// OPD / IPD DEPARTMENTS
                _buildSectionWithEmptyCheck(
                  hasData: data.departments?.isNotEmpty ?? false,
                  icon: Icons.local_hospital_outlined,
                  title: AppStrings.opdDoctors.tr,
                  emptyMessage: AppStrings.noDepartmentsAvailable.tr,
                  child: HospitalBookingScreen(),
                ),

                // SizedBox(height: SizeConfig.paddingXS),

                /// EMERGENCY & CRITICAL CARE
                _buildSectionWithEmptyCheck(
                  hasData: _hasEmergencyData(),
                  icon: Icons.emergency_outlined,
                  title: AppStrings.otherFacilities.tr,
                  emptyMessage: AppStrings.noEmergencyServicesListed.tr,
                  child: EmergencyCriticalCareView(),
                ),

                SizedBox(height: SizeConfig.paddingXS),

                /// MANAGEMENT
                _buildSectionWithEmptyCheck(
                  hasData: data.management?.isNotEmpty ?? false,
                  icon: Icons.people_outline,
                  title: AppStrings.managementTrust.tr,
                  emptyMessage: AppStrings.noManagementDetailsAvailable.tr,
                  child: ManagementCardListWidget(),
                ),

                SizedBox(height: SizeConfig.paddingXS),

                /// GALLERY
                _buildGallerySection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// JOB VACANCY
                _buildJobVacancyCard(),

                SizedBox(height: SizeConfig.paddingXS),

                /// CONTACT US
                _buildContactSection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// WEBSITE PREVIEW
                WebsitePreviewCard(
                  url: data.contacts?.firstOrNull?.branch?.website ?? '',
                ),

                /// LOCATION MAP
                _buildLocationSection(),

                SizedBox(height: kBottomNavigationBarHeight + SizeConfig.paddingXSL),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// First-load skeleton mirroring the real layout (header, stats, emergency
  /// action cards and a few content sections). A single [buildLoadingShimmer]
  /// drives the whole tree so every block shares one animation controller
  /// instead of spawning a shimmer per placeholder.
  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: buildLoadingShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER (cover + logo + title lines)
            shimmerContainer(height: SizeConfig.size150, radius: 0),
            Padding(
              padding: EdgeInsets.all(SizeConfig.paddingS),
              child: Row(
                children: [
                  shimmerContainer(width: SizeConfig.size60, height: SizeConfig.size60, radius: 30),
                  SizedBox(width: SizeConfig.paddingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerContainer(height: SizeConfig.size16),
                        SizedBox(height: SizeConfig.paddingXS),
                        shimmerContainer(height: SizeConfig.size12, width: 180),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// STATS CARD
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
              child: shimmerContainer(height: SizeConfig.size60, radius: 12),
            ),
            SizedBox(height: SizeConfig.paddingS),

            /// EMERGENCY ACTION CARDS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
              child: Row(
                children: [
                  Expanded(child: shimmerContainer(height: SizeConfig.size150, radius: 12)),
                  SizedBox(width: SizeConfig.paddingS),
                  Expanded(child: shimmerContainer(height: SizeConfig.size150, radius: 12)),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.paddingS),

            /// CONTENT SECTION CARDS
            for (int i = 0; i < 3; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
                child: shimmerContainer(height: SizeConfig.size120, radius: 12),
              ),
              SizedBox(height: SizeConfig.paddingS),
            ],
          ],
        ),
      ),
    );
  }

  /// Full-screen empty state when no hospital data exists
  Widget _buildFullEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: EmptyStateWidget(
          message: AppStrings.noHospitalDataFound.tr,
        ),
      ),
    );
  }

  /// Bottom navigation bar with Book/Inquiry button
  Widget _buildBottomBar() {
    return Obx(() {
      return controller.hospitalDataResModel?.value.data?.userId != userId
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.paddingS,
                  right: SizeConfig.paddingS,
                  bottom: SizeConfig.paddingM,
                  top: SizeConfig.paddingXSL,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PositiveCustomBtn(
                        onTap: () => _openHospitalEnquirySheet(),
                        title: AppStrings.inquiry.tr,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink();
    });
  }

  /// Emergency action cards (Call Now + Book Now)
  Widget _buildEmergencyActionCards() {
    final emergencyNo =
        controller.hospitalDataResModel?.value.data?.emergencyContactData?.emergencyNumber ?? "";
    final appointmentNo =
        controller.hospitalDataResModel?.value.data?.emergencyContactData?.appointmentNumber ?? "";

    if (emergencyNo.isEmpty && appointmentNo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingS,
        vertical: SizeConfig.paddingXS,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (emergencyNo.isNotEmpty)
              Expanded(
                child: _buildActionCard(
                  icon: "assets/svg/call_24.svg",
                  title: AppStrings.emergencyContact.tr,
                  subtitle: AppStrings.immediateHelp24x7.tr,
                  buttonText: AppStrings.callNow.tr,
                  isEmergency: true,
                  phoneNo: emergencyNo,
                  onTap: () => _launchCaller(emergencyNo),
                ),
              ),
            if (emergencyNo.isNotEmpty && appointmentNo.isNotEmpty) SizedBox(width: SizeConfig.paddingS),
            if (appointmentNo.isNotEmpty)
              Expanded(
                child: _buildActionCard(
                  icon: "assets/svg/support_helth.svg",
                  title: AppStrings.appointmentNumber.tr,
                  subtitle: AppStrings.scheduleYourVisitEasily.tr,
                  buttonText: AppStrings.bookNow.tr,
                  isEmergency: false,
                  phoneNo: appointmentNo,
                  onTap: () async {
                    final chatViewController = Get.find<ChatViewController>();
                    chatViewController.checkChatConnectionAndOpenChat(
                      userId: controller.hospitalDataResModel?.value.data?.userId ?? '',
                      route: AppConstants.route_discover,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Section wrapper with empty state fallback
  Widget _buildSectionWithEmptyCheck({
    required bool hasData,
    required IconData icon,
    required String title,
    required String emptyMessage,
    required Widget child,
  }) {
    if (!hasData) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingXSL,
          vertical: SizeConfig.paddingXSmall,
        ),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
            children: [
              _sectionHeader(icon: icon, title: title),
              SizedBox(height: SizeConfig.paddingM),
              EmptyStateWidget(
                message: emptyMessage,
                imageSize: SizeConfig.size60,
              ),
              // SizedBox(height: SizeConfig.paddingS),
            ],
          ),
        ),
      );
    }
    return child;
  }

  /// Section header row with icon and title
  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: SizeConfig.size20),
        SizedBox(width: SizeConfig.paddingXS),
        ServiceHomeTitleWidget(title: title),
      ],
    );
  }

  /// Gallery section with empty state
  Widget _buildGallerySection() {
    final gallery = controller.hospitalDataResModel?.value.data?.gallery;
    final allImages = gallery?.expand((photo) => photo.images ?? <String>[]).toList() ?? [];

    if (allImages.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
            children: [
              _sectionHeader(
                icon: Icons.photo_library_outlined,
                title: AppStrings.gallery.tr,
              ),
              SizedBox(height: SizeConfig.paddingM),
              EmptyStateWidget(
                message: AppStrings.noPhotosAvailable.tr,
                imageSize: SizeConfig.size60,
              ),
              SizedBox(height: SizeConfig.paddingS),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(SizeConfig.paddingXSL),
      child: HospitalHomeGalleryWidget(
        photos: gallery,
      ),
    );
  }

  /// Job vacancy card with icon and arrow
  Widget _buildJobVacancyCard() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingXSL,
        vertical: SizeConfig.paddingXSmall,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Get.to(() => HospitalJobListingScreen(isReadOnly: true));
        },
        child: CommonCardWidget(
          cardMargin: 0,
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                color: AppColors.primaryColor,
                size: SizeConfig.size20,
              ),
              SizedBox(width: SizeConfig.paddingXS),
              Expanded(
                child: ServiceHomeTitleWidget(title: AppStrings.jobVacancy.tr),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primaryColor,
                size: SizeConfig.size16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Contact us section with empty state
  Widget _buildContactSection() {
    final contacts = controller.hospitalDataResModel?.value.data?.contacts ?? [];

    if (contacts.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
            children: [
              _sectionHeader(
                icon: Icons.phone_outlined,
                title: AppStrings.contactUs.tr,
              ),
              SizedBox(height: SizeConfig.paddingM),
              EmptyStateWidget(
                message: AppStrings.noContactDetailsAvailable.tr,
              ),
              SizedBox(height: SizeConfig.paddingS),
            ],
          ),
        ),
      );
    }

    return HospitalContactUsView(
      contacts: contacts,
      isReadOnly: true,
      description: controller.hospitalDataResModel?.value.data?.description,
    );
  }

  /// Location section - only shown when valid coordinates exist
  Widget _buildLocationSection() {
    final contacts = controller.hospitalDataResModel?.value.data?.contacts;
    final coordinates = contacts?.firstOrNull?.branch?.location?.coordinates;

    if (coordinates == null || coordinates.length < 2 || coordinates[0] == 0.0 || coordinates[1] == 0.0) {
      return const SizedBox.shrink();
    }

    return BusinessLocationWidget(
      locationText: contacts?.firstOrNull?.branch?.location?.name,
      latitude: double.tryParse(coordinates[1].toString()) ?? 0.0,
      longitude: double.tryParse(coordinates[0].toString()) ?? 0.0,
      businessName: controller.hospitalDataResModel?.value.data?.name ?? "",
      padding: 0,
      isTitleShow: true,
    );
  }

  /// Check if any emergency or facility data is available
  bool _hasEmergencyData() {
    final data = controller.hospitalDataResModel?.value.data;
    final ec = data?.emergencyCare;
    final of = data?.otherFacilities;

    if (ec == null && of == null) return false;

    return (ec?.emergencyCasualty ?? false) ||
        (ec?.traumaCare ?? false) ||
        (ec?.icu ?? false) ||
        (ec?.ccu ?? false) ||
        (ec?.nicu ?? false) ||
        (ec?.picu ?? false) ||
        (of?.ambulance ?? false) ||
        (of?.bloodBank ?? false) ||
        (of?.diagnosticDepartments ?? false) ||
        (of?.medicalStore ?? false) ||
        (of?.pmSwasthyaBimaYojana ?? false);
  }

  /// Action card for emergency/appointment
  Widget _buildActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required String phoneNo,
    required bool isEmergency,
    required VoidCallback onTap,
  }) {
    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          LocalAssets(imagePath: icon, height: 50, width: 50),
          SizedBox(height: SizeConfig.paddingM),
          CustomText(
            title,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          _buildCallButton(buttonText, isEmergency, onTap),
        ],
      ),
    );
  }

  Widget _buildCallButton(String text, bool isEmergency, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.paddingM,
          vertical: SizeConfig.paddingXSL,
        ),
        decoration: BoxDecoration(
          color: isEmergency ? const Color(0xFFC8554D) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isEmergency ? null : Border.all(color: AppColors.primaryColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isEmergency)
              Icon(
                Icons.phone,
                size: SizeConfig.size18,
                color: Colors.white,
              ),
            if (isEmergency) SizedBox(width: SizeConfig.paddingXS),
            CustomText(
              text,
              color: isEmergency ? Colors.white : AppColors.primaryColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the unified healthcare-enquiry sheet for this hospital. Pulls
  /// the listing snapshot (id / owner id / name / cover / first-contact
  /// location) from the loaded hospital model so the sheet header — and
  /// the eventual in-chat card — renders without an extra fetch.
  ///
  /// Before opening we register the hospital's OPD doctors with
  /// [HospitalAppointmentSheet.cacheDoctorsForHospital] so the
  /// enquiry-first flow (customer taps "Book Appointment" on the
  /// accepted chat card) can render a real doctor picker instead of the
  /// empty-state fallback. The cache is keyed by hospitalId and lives
  /// only for this session — losing it on restart is fine, the sheet
  /// gracefully shows an empty state prompting the customer to reopen
  /// the hospital screen. See
  /// lib/docs/healthcare-appointment-ui-integration.md §0
  /// (enquiry-first flow).
  void _openHospitalEnquirySheet() {
    final data = controller.hospitalDataResModel?.value.data;
    final listingId = (data?.id ?? '').trim();
    final ownerId = (data?.userId ?? '').trim();
    if (listingId.isEmpty || ownerId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    HospitalAppointmentSheet.cacheDoctorsForHospital(
        listingId, _doctorsForAppointment(data));
    final firstContact = data?.contacts?.firstOrNull?.branch;
    HealthcareEnquirySheet.open(
      context,
      category: HealthcareEnquiryController.categoryHospital,
      listing: HealthcareEnquiryListing(
        listingId: listingId,
        ownerId: ownerId,
        ownerName: (data?.name ?? '').trim(),
        listingName: (data?.name ?? '').trim(),
        listingImage: data?.coverUrl,
        location: firstContact?.location?.name,
      ),
    );
  }

  /// Flattens the loaded hospital's departments → OPD doctors into the
  /// slim shape the appointment sheet consumes. Each doctor carries its
  /// parent department name so the picker can display it. Doctors
  /// missing an id are dropped (server would reject them as `opd_id`).
  ///
  /// Iterates every department (not just `type == 'OPD'`) because the
  /// backend sometimes leaves `type` blank on OPD-only entries — as
  /// long as `dept.opd` is populated we take those doctors. IPD-only
  /// entries naturally drop out (their `opd` is null).
  ///
  /// `fees` is not on the discover-side OPD shape — that's fine: the
  /// server snapshots fees from the OPD record when the booking is
  /// created (doc §1), so the client never sends them.
  List<HospitalAppointmentDoctorOption> _doctorsForAppointment(
      HospitalFullData? data) {
    final out = <HospitalAppointmentDoctorOption>[];
    final departments = data?.departments ?? const <IpdOpdDepartments>[];
    debugPrint('[DiscoverHospital] _doctorsForAppointment: '
        'departments=${departments.length} '
        'types=${departments.map((d) => d.type).toList()} '
        'opdCounts=${departments.map((d) => d.opd?.length ?? 0).toList()}');
    for (final dept in departments) {
      final deptName = (dept.name ?? '').trim();
      for (final doc in dept.opd ?? const <Opd>[]) {
        final id = (doc.id ?? '').trim();
        if (id.isEmpty) continue;
        out.add(HospitalAppointmentDoctorOption(
          id: id,
          name: (doc.name ?? '').trim(),
          department: deptName.isNotEmpty ? deptName : null,
          image: doc.imageUrl,
          timing: doc.timing,
        ));
      }
    }
    return out;
  }

  void _launchCaller(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(
          message: AppStrings.errorCouldNotOpenDialer.tr,
        );
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }
}
