import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/health_camp_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_detail_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmptyHealthCampWidget extends StatefulWidget {
  final bool isOwnProfile;
  final String? labId;

  const EmptyHealthCampWidget({
    super.key,
    this.isOwnProfile = true,
    this.labId,
  });

  @override
  State<EmptyHealthCampWidget> createState() => _EmptyHealthCampWidgetState();
}

class _EmptyHealthCampWidgetState extends State<EmptyHealthCampWidget> {
  List<HealthCamp> _healthCamps = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isOwnProfile && widget.labId != null) {
      _fetchHealthCamps();
    }
  }

  Future<void> _fetchHealthCamps() async {
    setState(() => _isLoading = true);
    try {
      final res = await HealthCampRepo().getHealthCampsByLab(widget.labId!);
      if (res.isSuccess) {
        List data = res.response?.data['data'] ?? [];
        setState(() {
          _healthCamps = data.map((e) => HealthCamp.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print("Error fetching health camps: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDetail() {
    Get.to(() => HealthCampDetailScreen(
          isOwnProfile: widget.isOwnProfile,
          labId: widget.labId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    // Own profile → navigate to detail screen (has add/edit/delete)
    if (widget.isOwnProfile) {
      return _buildOwnProfileView();
    }

    // Other user → loading / data / empty
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(AppStrings.healthCamp, fontWeight: FontWeight.w700),
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    if (_healthCamps.isEmpty) {
      return _buildEmptyOtherUserView();
    }

    return _buildOtherUserCampView(_healthCamps.first);
  }

  /// Own profile: tap to manage health camp (add/edit/delete in detail screen)
  Widget _buildOwnProfileView() {
    return InkWell(
      onTap: _navigateToDetail,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              AppStrings.healthCamp,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/category/medical/health_camp_bg.png',
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LocalAssets(
                          imagePath:
                              "assets/category/medical/empty_white_data.png",
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          "no_tests_posted".tr,
                          color: Colors.white,
                          textAlign: TextAlign.center,
                          fontSize: SizeConfig.size15,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white54),
                          ),
                          child: CustomText(
                            AppStrings.healthCamp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Other user: no health camp available (message only)
  Widget _buildEmptyOtherUserView() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(AppStrings.healthCamp, fontWeight: FontWeight.w700),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/category/medical/health_camp_bg.png',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LocalAssets(
                        imagePath:
                            "assets/category/medical/empty_white_data.png",
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(height: 12),
                      CustomText(
                        "no_health_camp_available".tr,
                        color: Colors.white,
                        textAlign: TextAlign.center,
                        fontSize: SizeConfig.size15,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Other user: show health camp preview (read-only), tap for full details
  Widget _buildOtherUserCampView(HealthCamp camp) {
    final hasImage = camp.images != null && camp.images!.isNotEmpty;
    String dateRange = '';
    try {
      final start = DateTime.tryParse(camp.startDate ?? '');
      final end = DateTime.tryParse(camp.endDate ?? '');
      if (start != null && end != null) {
        dateRange =
            '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
      }
    } catch (_) {}

    return InkWell(
      onTap: _navigateToDetail,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(AppStrings.healthCamp, fontWeight: FontWeight.w700),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasImage)
                    Image.network(
                      camp.images!.first,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/category/medical/health_camp_bg.png',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Image.asset(
                      'assets/category/medical/health_camp_bg.png',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Positioned.fill(
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.3)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          camp.title ?? AppStrings.healthCamp,
                          color: Colors.white,
                          textAlign: TextAlign.center,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        if (camp.description?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          CustomText(
                            camp.description!,
                            color: Colors.white,
                            textAlign: TextAlign.center,
                            fontSize: SizeConfig.size15,
                            fontWeight: FontWeight.w400,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (dateRange.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white54),
                            ),
                            child: CustomText(
                              dateRange,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
