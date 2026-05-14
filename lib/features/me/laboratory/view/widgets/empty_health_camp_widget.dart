import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/health_camp_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/health_camp_detail_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Renders the "Health Camp" tile on the lab profile.
///
/// - Own profile: always shows the add/manage CTA (lazy fetch happens inside
///   the detail screen).
/// - Other profile: fetches via [HealthCampRepo] and shows a loading state,
///   the first camp preview, or an empty placeholder.
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
  static const String _backgroundAsset =
      'assets/category/medical/health_camp_bg.png';
  static const String _emptyIconAsset =
      'assets/category/medical/empty_white_data.png';
  static const double _stackHeight = 220;

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
        final List data = res.response?.data['data'] ?? [];
        if (!mounted) return;
        setState(() {
          _healthCamps = data.map((e) => HealthCamp.fromJson(e)).toList();
        });
      }
    } catch (e) {
      logs('EmptyHealthCampWidget._fetchHealthCamps ERROR $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    if (widget.isOwnProfile) return _buildOwnProfileView();
    if (_isLoading) return _buildLoadingView();
    if (_healthCamps.isEmpty) return _buildEmptyOtherUserView();
    return _buildOtherUserCampView(_healthCamps.first);
  }

  /// Standard rounded white shell that every variant of this widget shares.
  Widget _buildCard({required Widget child}) {
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
          child,
        ],
      ),
    );
  }

  /// Standard rounded image stack used as the body of every variant.
  /// Pass [imageUrl] to render a network header (with the asset as a fallback);
  /// pass null to use only the asset background.
  Widget _buildImageStack({
    required Widget content,
    String? imageUrl,
    bool overlay = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: _stackHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _assetBackground(),
            )
          else
            _assetBackground(),
          if (overlay)
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          Padding(padding: const EdgeInsets.all(20.0), child: content),
        ],
      ),
    );
  }

  Widget _assetBackground() => Image.asset(
        _backgroundAsset,
        height: _stackHeight,
        width: double.infinity,
        fit: BoxFit.cover,
      );

  /// Own profile: tap to manage health camp (add/edit/delete in detail screen)
  Widget _buildOwnProfileView() {
    return InkWell(
      onTap: _navigateToDetail,
      child: _buildCard(
        child: _buildImageStack(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(imagePath: _emptyIconAsset, width: 60, height: 60),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
      ),
    );
  }

  Widget _buildLoadingView() {
    return _buildCard(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Other user: no health camp available (message only)
  Widget _buildEmptyOtherUserView() {
    return _buildCard(
      child: _buildImageStack(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(imagePath: _emptyIconAsset, width: 60, height: 60),
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
    );
  }

  /// Other user: show health camp preview (read-only), tap for full details
  Widget _buildOtherUserCampView(HealthCamp camp) {
    final dateRange = _formatDateRange(camp.startDate, camp.endDate);
    final hasImage = camp.images?.isNotEmpty ?? false;

    return InkWell(
      onTap: _navigateToDetail,
      child: _buildCard(
        child: _buildImageStack(
          imageUrl: hasImage ? camp.images!.first : null,
          overlay: true,
          content: Column(
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
      ),
    );
  }

  static String _formatDateRange(String? startIso, String? endIso) {
    final start = DateTime.tryParse(startIso ?? '');
    final end = DateTime.tryParse(endIso ?? '');
    if (start == null || end == null) return '';
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }
}
