import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/model/doctor_discover_summary.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_certificate_model.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_appointment_sheet.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_profile_model.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_profile_repo.dart';
import 'package:BlueEra/features/me/medical/widget/healthcare_enquiry_sheet.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/visit_business_hero.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// What a patient sees before enquiring with a standalone doctor.
///
/// This is the doctor-specific detail screen the Discover card opens — NOT
/// `DiscoverHospitalHomeScreen`. A standalone doctor has no hospital record,
/// so the hospital screen renders a mostly-empty page and, worse, its enquiry
/// button posts to the hospital endpoint, which is what filed doctor enquiries
/// into the wrong collection (guide §24.1 / §26).
///
/// Two calls, in parallel (guide §25.3):
///   • `GET user-service/business/{businessId}` — identity, photos, contact,
///     availability, ratings. A failure here is a real error.
///   • `GET hospital-service/doctors/full/{ownerUserId}` — degree, fee,
///     expertise, certificates. **A 404 is NORMAL** and simply means the
///     doctor hasn't completed their professional profile: the page still
///     renders from business data with the professional rows hidden.
class DoctorPublicProfileScreen extends StatefulWidget {
  /// `Business._id` — enquiry / booking / ratings key.
  final String businessId;

  /// `Business.user_id` — the OWNER's user id, which is what
  /// `/doctors/full/:userId` expects. Passing `businessId` here returns 404
  /// for every doctor.
  final String ownerUserId;

  /// Optional prefill from the Discover card so the header has something to
  /// show on the first frame.
  final DoctorDiscoverSummary? summary;

  const DoctorPublicProfileScreen({
    super.key,
    required this.businessId,
    required this.ownerUserId,
    this.summary,
  });

  @override
  State<DoctorPublicProfileScreen> createState() =>
      _DoctorPublicProfileScreenState();
}

class _DoctorPublicProfileScreenState extends State<DoctorPublicProfileScreen> {
  final viewBusinessDetailsController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  DoctorProfile? _doctorProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.ownerUserId.isNotEmpty) {
      ProfileClickTracker.track(
        userId: widget.ownerUserId,
        source: ChatClickSource.storeDetail,
      );
    }
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    // Both calls in parallel — neither depends on the other's result.
    await Future.wait([
      if (widget.businessId.isNotEmpty)
        viewBusinessDetailsController.viewBusinessProfileById(widget.businessId),
      _loadDoctorProfile(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  /// Never surfaces an error. `/doctors/full/:userId` 404s for any doctor who
  /// registered but hasn't filled in their profile yet — that is a normal,
  /// expected state, so the failure just leaves [_doctorProfile] null and the
  /// professional sections hide themselves.
  Future<void> _loadDoctorProfile() async {
    if (widget.ownerUserId.isEmpty) return;
    try {
      final res = await DoctorProfileRepo()
          .getPublicProfile(ownerUserId: widget.ownerUserId);
      if (!res.isSuccess) return;
      final data = res.response?.data;
      final profile = (data is Map) ? data['data'] : null;
      if (profile is Map) {
        _doctorProfile =
            DoctorProfile.fromJson(Map<String, dynamic>.from(profile));
      }
    } catch (_) {
      // Same as a 404 — render from business data alone.
    }
  }

  Future<void> _refresh() => _load();

  BusinessProfileDetails? get _business =>
      viewBusinessDetailsController.visitedBusinessProfileDetails?.data;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Obx(() {
        viewBusinessDetailsController.profileVersion.value;
        return _enquiryBottomBar(_business) ?? const SizedBox.shrink();
      }),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared business header — banner, logo, rating, follow / share.
              Obx(() {
                viewBusinessDetailsController.profileVersion.value;
                if (viewBusinessDetailsController.isProfileLoading.value) {
                  return buildBusinessHeaderSkeleton();
                }
                return VisitBusinessHero(
                  details: _business,
                  onRated: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.businessId,
                    silent: true,
                  ),
                  onFollowChanged: () =>
                      viewBusinessDetailsController.viewBusinessProfileById(
                    widget.businessId,
                    silent: true,
                  ),
                );
              }),
              SizedBox(height: SizeConfig.size10),

              _headlineCard(),

              if (_hasAboutRows) ...[
                SizedBox(height: SizeConfig.size10),
                _aboutCard(),
              ],

              if ((_doctorProfile?.expertise.isNotEmpty ?? false)) ...[
                SizedBox(height: SizeConfig.size10),
                _expertiseCard(),
              ],

              if ((_doctorProfile?.certificates.isNotEmpty ?? false)) ...[
                SizedBox(height: SizeConfig.size10),
                _certificatesCard(),
              ],

              if (_galleryPhotos.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size10),
                _galleryCard(),
              ],

              SizedBox(height: SizeConfig.size10),
              Obx(() {
                viewBusinessDetailsController.profileVersion.value;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  child: BusinessContactMapCard(
                    businessProfileDetails: _business,
                    showEditButton: false,
                  ),
                );
              }),
              SizedBox(height: kBottomNavigationBarHeight + 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Headline: name + specialization + fee ───────────────────────────
  /// Rendered from the doctor profile where available, falling back to the
  /// Discover card's snapshot so the section still has content when
  /// `/doctors/full` 404s.
  String get _headline {
    final fromProfile = _doctorProfile?.headline ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    return widget.summary?.headline ?? '';
  }

  String get _feeLabel {
    final fromProfile = _doctorProfile?.feeLabel ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    // Only fall back when the card actually carried a fee — a null fee means
    // "not set" and must never render as ₹0.
    return (widget.summary?.hasFee ?? false) ? widget.summary!.feeLabel : '';
  }

  Widget _headlineCard() {
    final name = (_business?.businessName ?? widget.summary?.name ?? '').trim();
    final headline = _headline;
    final fee = _feeLabel;
    final experience = _experienceLabel;

    if (name.isEmpty && headline.isEmpty && fee.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty)
              CustomText(
                name,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
            if (headline.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size4),
              CustomText(
                headline,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ],
            if (experience.isNotEmpty || fee.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size10),
              Row(
                children: [
                  if (experience.isNotEmpty)
                    Expanded(
                      child: _statTile(
                          AppStrings.doctorExperience.tr, experience),
                    ),
                  if (experience.isNotEmpty && fee.isNotEmpty)
                    SizedBox(width: SizeConfig.size10),
                  // Fee tile is omitted entirely when unset — never "₹0".
                  if (fee.isNotEmpty)
                    Expanded(
                      child: _statTile(
                          AppStrings.doctorConsultationFee.tr, fee),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: AppColors.geryFC,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
          const SizedBox(height: 2),
          CustomText(
            value,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── About the doctor ────────────────────────────────────────────────
  /// Built from the year count rather than from `summary.experienceLabel`,
  /// which bakes in the English "Years" — the fallback has to go through the
  /// same translated unit as the primary path or the label flips language
  /// depending on whether `/doctors/full` answered.
  String get _experienceLabel {
    final years = _doctorProfile?.experienceYears ??
        widget.summary?.experienceYears ??
        0;
    if (years <= 0) return '';
    return '$years ${(years == 1 ? AppStrings.yearLabel : AppStrings.doctorYears).tr}';
  }

  /// Every row is optional — a doctor may have filled in only some of them.
  List<MapEntry<String, String>> get _aboutRows {
    final p = _doctorProfile;
    final degree = (p?.degree.isNotEmpty ?? false)
        ? p!.degree.join(', ')
        : (widget.summary?.degreeLabel ?? '');
    final specialization = (p?.specialization.isNotEmpty ?? false)
        ? p!.specialization.join(', ')
        : (widget.summary?.specialization.join(', ') ?? '');
    final languages = (p?.languagesSpoken.isNotEmpty ?? false)
        ? p!.languagesSpoken.join(', ')
        : (widget.summary?.languagesLabel ?? '');
    final address = (p?.address ?? '').trim().isNotEmpty
        ? p!.address!.trim()
        : (_business?.address ?? widget.summary?.address ?? '').trim();

    return [
      if (degree.isNotEmpty) MapEntry(AppStrings.doctorDegree.tr, degree),
      if (specialization.isNotEmpty)
        MapEntry(AppStrings.doctorSpecialization.tr, specialization),
      if (_experienceLabel.isNotEmpty)
        MapEntry(AppStrings.doctorExperience.tr, _experienceLabel),
      if ((p?.registrationNumber ?? '').trim().isNotEmpty)
        MapEntry(AppStrings.doctorRegistrationNumber.tr,
            p!.registrationNumber!.trim()),
      if (_feeLabel.isNotEmpty)
        MapEntry(AppStrings.doctorConsultationFee.tr, _feeLabel),
      if (languages.isNotEmpty)
        MapEntry(AppStrings.doctorLanguagesSpoken.tr, languages),
      if (address.isNotEmpty) MapEntry(AppStrings.addressLabel.tr, address),
    ];
  }

  bool get _hasAboutRows =>
      _aboutRows.isNotEmpty ||
      (_doctorProfile?.description ?? '').trim().isNotEmpty;

  Widget _aboutCard() {
    final description = (_doctorProfile?.description ?? '').trim();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.doctorAboutTheDoctor.tr),
            SizedBox(height: SizeConfig.size8),
            ..._aboutRows.map(
              (row) => Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: SizeConfig.size120,
                      child: CustomText(
                        row.key,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    Expanded(
                      child: CustomText(
                        row.value,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size4),
              ExpandableText(
                text: description,
                trimLines: 4,
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontFamily: AppConstants.OpenSans,
                  fontWeight: FontWeight.w400,
                  fontSize: SizeConfig.small,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Expertise ───────────────────────────────────────────────────────
  Widget _expertiseCard() {
    final expertise = _doctorProfile!.expertise;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.doctorExpertise.tr),
            SizedBox(height: SizeConfig.size8),
            ...expertise.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: CustomText(
                        item,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Certificates & Awards ───────────────────────────────────────────
  Widget _certificatesCard() {
    final certificates = _doctorProfile!.certificates;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.doctorCertificateAwards.tr),
            SizedBox(height: SizeConfig.size10),
            SizedBox(
              height: SizeConfig.size180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: certificates.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size10),
                itemBuilder: (context, index) =>
                    _certificateTile(certificates[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _certificateTile(DoctorCertificate certificate) {
    final image = certificate.imageUrl ?? '';
    return SizedBox(
      width: SizeConfig.size150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: image.isEmpty
                ? null
                : () => Get.to(() => ImageViewScreen(
                      imageUrls: [image],
                      initialIndex: 0,
                      appBarTitle:
                          certificate.title ?? AppStrings.certificate.tr,
                    )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: SizeConfig.size110,
                width: double.infinity,
                child: image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.greyE5),
                        errorWidget: (_, __, ___) => _certificateFallback(),
                      )
                    : _certificateFallback(),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            certificate.title ?? '',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if ((certificate.issuedBy ?? '').trim().isNotEmpty)
            CustomText(
              certificate.issuedBy!.trim(),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.grey7E,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _certificateFallback() => Container(
        color: AppColors.greyE5,
        alignment: Alignment.center,
        child: Icon(
          Icons.workspace_premium_outlined,
          size: 28,
          color: Colors.grey.shade500,
        ),
      );

  // ── Gallery (business live photos) ──────────────────────────────────
  List<String> get _galleryPhotos =>
      (_business?.livePhotos ?? [])
          .where((p) => p.trim().isNotEmpty)
          .toList();

  Widget _galleryCard() {
    final photos = _galleryPhotos;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.gallery.tr),
            SizedBox(height: SizeConfig.size10),
            SizedBox(
              height: SizeConfig.size100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => Get.to(() => ImageViewScreen(
                        imageUrls: photos,
                        initialIndex: index,
                        appBarTitle: AppStrings.gallery.tr,
                      )),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photos[index],
                      width: SizeConfig.size100,
                      height: SizeConfig.size100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.greyE5),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.greyE5,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_outlined,
                            color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => CustomText(
        title,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w700,
        color: AppColors.mainTextColor,
      );

  // ── Enquiry CTA ─────────────────────────────────────────────────────
  /// Hidden on your own listing — the server rejects a self-enquiry anyway.
  Widget? _enquiryBottomBar(BusinessProfileDetails? profile) {
    final ownerId = (profile?.userId ?? widget.ownerUserId).trim();
    if (ownerId.isEmpty) return null;
    if (ownerId == userId) return const SizedBox.shrink();

    // Two CTAs, not one: an enquiry is a question, a booking is a request for
    // a specific date. Before this, a customer viewing a doctor could only
    // enquire, which is why `doctorappointments` was empty — nothing in the
    // app ever called `createAppointment()` (guide §3.1).
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        child: Row(
          children: [
            Expanded(
              child: PositiveCustomBtn(
                onTap: () => _openEnquirySheet(profile, ownerId),
                title: AppStrings.inquiry.tr,
                bgColor: AppColors.white,
                textColor: AppColors.primaryColor,
                borderColor: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: PositiveCustomBtn(
                onTap: () => _openAppointmentSheet(profile, ownerId),
                title: AppStrings.bookAppointment.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Direct booking — no `enquiry_id`, since the customer never raised an
  /// enquiry on this path. The enquiry-first path goes through the chat card
  /// instead and does pass one.
  void _openAppointmentSheet(BusinessProfileDetails? profile, String ownerId) {
    final name = (profile?.businessName ?? widget.summary?.name ?? '').trim();
    DoctorAppointmentSheet.open(
      context,
      listing: DoctorAppointmentListing(
        // Business._id, never DoctorProfile._id — different id spaces, and
        // the profile id 404s (guide §6.3).
        businessId: widget.businessId,
        ownerId: ownerId,
        doctorName: name,
        doctorImage: profile?.logo ?? widget.summary?.logo,
        location: (profile?.address ?? widget.summary?.address ?? '').trim(),
        // Display only — shown as "You will be charged … at the clinic".
        feeLabel: _feeLabel,
      ),
    );
  }

  /// Opens the shared healthcare enquiry sheet under the **DOCTOR** category,
  /// which routes the POST to `user-service/business-enquiries` with a
  /// `selections{}` map. It must never go to
  /// `hospital-service/hospital-enquiries` — that stores the enquiry as
  /// `category: "HOSPITAL"` in the hospital collection, where the doctor never
  /// sees it (guide §24.1, §25.4).
  void _openEnquirySheet(BusinessProfileDetails? profile, String ownerId) {
    final name =
        (profile?.businessName ?? widget.summary?.name ?? '').trim();
    HealthcareEnquirySheet.open(
      context,
      category: 'DOCTOR',
      listing: HealthcareEnquiryListing(
        // Enquiries key on Business._id, never DoctorProfile._id.
        listingId: widget.businessId,
        ownerId: ownerId,
        ownerName: name,
        listingName: name,
        listingImage: profile?.coverimage ?? widget.summary?.heroImage,
        location: (profile?.address ?? widget.summary?.address ?? '').trim(),
      ),
    );
  }
}
