import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/content_creator/controller/earn_artist_controller.dart';
import 'package:BlueEra/features/me/content_creator/model/earn_artist_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Content-creator "Channel" tab. Lists the creator's linked social channels
/// (`EarnArtist.channels`) and a top CTA to add a new one. Adding runs a small
/// two-step sheet: an in-app "BlueEra Channel" (coming soon) or an external
/// social channel/page (YouTube / Instagram / any link), the latter saved to
/// `channels[]` via the section-wise PUT.
class ContentCreatorChannelTab extends StatelessWidget {
  const ContentCreatorChannelTab({super.key});

  static const _hMargin = 12.0;

  @override
  Widget build(BuildContext context) {
    final ctrl = getOrPut(() => EarnArtistController());
    return Obx(() {
      final channels = ctrl.artist.value?.channels ?? const <ArtistChannel>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _addChannelCta(context, ctrl),
          if (channels.isEmpty)
            _emptyState()
          else
            for (var i = 0; i < channels.length; i++)
              _channelCard(context, ctrl, channels[i], i),
        ],
      );
    });
  }

  // ─── ADD CTA (matches the mockup's top button) ──────────────────────────
  Widget _addChannelCta(BuildContext context, EarnArtistController ctrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _hMargin),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
      ),
      child: InkWell(
        onTap: () => _openSourceSheet(context, ctrl),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_rounded, color: AppColors.primaryColor, size: 18),
              SizedBox(width: SizeConfig.size8),
              CustomText('Add Social Channel/Page',
                  fontSize: SizeConfig.medium15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hMargin, 40, _hMargin, 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.hub_outlined,
                size: 40, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size10),
            CustomText('No channels yet',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor),
            SizedBox(height: SizeConfig.size4),
            CustomText('Link your YouTube, Instagram or any page above.',
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── CHANNEL CARD ───────────────────────────────────────────────────────
  Widget _channelCard(BuildContext context, EarnArtistController ctrl,
      ArtistChannel ch, int index) {
    final meta = _ChannelPlatform.forName(ch.name);
    final link = ch.url.isNotEmpty ? ch.url : ch.channelId;
    return Container(
      margin: const EdgeInsets.fromLTRB(_hMargin, 12, _hMargin, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: meta.brand.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, color: meta.brand, size: 20),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText('${meta.label} Channel',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.secondaryTextColor, size: 20),
                onSelected: (v) async {
                  if (v == 'open') {
                    _openUrl(link);
                  } else if (v == 'remove') {
                    await ctrl.removeChannel(index);
                  }
                },
                itemBuilder: (_) => [
                  if (link.isNotEmpty)
                    const PopupMenuItem(value: 'open', child: Text('Open')),
                  const PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
            ],
          ),
          if (link.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size6),
            InkWell(
              onTap: () => _openUrl(link),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 16, color: AppColors.secondaryTextColor),
                    SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child: CustomText(link,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.open_in_new_rounded,
                        size: 15, color: AppColors.primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ─── STEP 1: PICK A SOURCE ──────────────────────────────────────────────
  void _openSourceSheet(BuildContext context, EarnArtistController ctrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size12,
                SizeConfig.size16, SizeConfig.size16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _dragHandle()),
                SizedBox(height: SizeConfig.size16),
                CustomText('Add a Channel',
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor),
                SizedBox(height: SizeConfig.size4),
                CustomText('Bring in a channel from BlueEra or link one from '
                    'another platform.',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor),
                SizedBox(height: SizeConfig.paddingM),
                // In-app channel — reserved for the BlueEra channel concept.
                _sourceTile(
                  iconAsset: AppImageAssets.channelEarnService,
                  title: 'BlueEra Channel',
                  subtitle: 'Create a channel inside BlueEra',
                  comingSoon: true,
                  onTap: () => commonSnackBar(message: 'Coming soon'),
                ),
                SizedBox(height: SizeConfig.size12),
                // External social channel/page.
                _sourceTile(
                  icon: Icons.public_rounded,
                  title: 'Social Channel / Page',
                  subtitle: 'YouTube, Instagram or any other link',
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _openLinkSheet(context, ctrl);
                  },
                ),
                SizedBox(height: SizeConfig.size8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sourceTile({
    IconData? icon,
    String? iconAsset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool comingSoon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.20), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: iconAsset != null
                  ? LocalAssets(imagePath: iconAsset, height: 24, width: 24)
                  : Icon(icon, color: AppColors.primaryColor, size: 22),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: CustomText(title,
                            fontSize: SizeConfig.medium15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor),
                      ),
                      if (comingSoon) ...[
                        SizedBox(width: SizeConfig.size8),
                        _comingSoonBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  CustomText(subtitle,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _comingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText('Coming soon',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFB77400)),
    );
  }

  // ─── STEP 2: PLATFORM + LINK ────────────────────────────────────────────
  void _openLinkSheet(BuildContext context, EarnArtistController ctrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChannelLinkSheet(controller: ctrl),
    );
  }

  Widget _dragHandle() => Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

/// Platform display metadata for a channel, resolved from its stored `name`.
class _ChannelPlatform {
  final String label;
  final IconData icon;
  final Color brand;
  const _ChannelPlatform(this.label, this.icon, this.brand);

  static const _all = <String, _ChannelPlatform>{
    'youtube':
        _ChannelPlatform('YouTube', Icons.play_circle_fill, Color(0xFFFF0000)),
    'instagram': _ChannelPlatform(
        'Instagram', Icons.camera_alt_outlined, Color(0xFFE1306C)),
    'facebook':
        _ChannelPlatform('Facebook', Icons.facebook, Color(0xFF1877F2)),
    'twitter':
        _ChannelPlatform('X / Twitter', Icons.alternate_email, Color(0xFF1DA1F2)),
  };

  static const _other =
      _ChannelPlatform('Social', Icons.public, Color(0xFF64748B));

  static _ChannelPlatform forName(String name) {
    final n = name.toLowerCase();
    for (final e in _all.entries) {
      if (n.contains(e.key) || n.contains(e.value.label.toLowerCase())) {
        return e.value;
      }
    }
    if (n.contains('twitter') || n == 'x') return _all['twitter']!;
    return _other;
  }
}

/// The platform-picker + URL sheet used to add an external social channel.
class _ChannelLinkSheet extends StatefulWidget {
  final EarnArtistController controller;
  const _ChannelLinkSheet({required this.controller});

  @override
  State<_ChannelLinkSheet> createState() => _ChannelLinkSheetState();
}

class _ChannelLinkSheetState extends State<_ChannelLinkSheet> {
  final TextEditingController _urlCtrl = TextEditingController();
  String _platform = 'youtube';

  static const _platforms = <_PlatformOption>[
    _PlatformOption('youtube', 'YouTube', Icons.play_circle_fill,
        Color(0xFFFF0000)),
    _PlatformOption('instagram', 'Instagram', Icons.camera_alt_outlined,
        Color(0xFFE1306C)),
    _PlatformOption('facebook', 'Facebook', Icons.facebook, Color(0xFF1877F2)),
    _PlatformOption('twitter', 'X / Twitter', Icons.alternate_email,
        Color(0xFF1DA1F2)),
    _PlatformOption('other', 'Other', Icons.public, Color(0xFF64748B)),
  ];

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  String get _platformLabel => _platforms
      .firstWhere((p) => p.key == _platform,
          orElse: () => _platforms.last)
      .label;

  bool get _ready => _urlCtrl.text.trim().length > 8;

  Future<void> _submit() async {
    final ok = await widget.controller
        .addChannel(platform: _platformLabel, url: _urlCtrl.text);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size12,
                SizeConfig.size16, SizeConfig.size16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.greyE5,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size16),
                  CustomText('Add Social Channel',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor),
                  SizedBox(height: SizeConfig.size4),
                  CustomText('Pick a platform and paste your channel or page link.',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor),
                  SizedBox(height: SizeConfig.paddingM),
                  _platformRow(),
                  SizedBox(height: SizeConfig.paddingM),
                  _urlField(),
                  SizedBox(height: SizeConfig.paddingM),
                  _submitButton(),
                  SizedBox(height: SizeConfig.size8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _platformRow() {
    const spacing = 10.0;
    return LayoutBuilder(
      builder: (context, c) {
        final fourUp =
            (c.maxWidth - spacing * (_platforms.length - 1)) / _platforms.length;
        final itemWidth = fourUp >= 76 ? fourUp : (c.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final opt in _platforms)
              SizedBox(width: itemWidth, child: _platformChip(opt)),
          ],
        );
      },
    );
  }

  Widget _platformChip(_PlatformOption opt) {
    final selected = _platform == opt.key;
    return InkWell(
      onTap: () => setState(() => _platform = opt.key),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryColor : const Color(0xFFE6E8EE),
            width: selected ? 1.8 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: opt.brand.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(opt.icon, color: opt.brand, size: 18),
            ),
            const SizedBox(height: 8),
            CustomText(opt.label,
                fontSize: SizeConfig.small,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primaryColor
                    : AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _urlField() {
    return TextField(
      controller: _urlCtrl,
      onChanged: (_) => setState(() {}),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      maxLines: 1,
      style: TextStyle(
          fontSize: SizeConfig.medium,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Paste your channel/page link',
        hintStyle: TextStyle(
            fontSize: SizeConfig.medium,
            color: AppColors.secondaryTextColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child:
              Icon(Icons.link_rounded, color: AppColors.primaryColor, size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        suffixIcon: _urlCtrl.text.isEmpty
            ? null
            : IconButton(
                onPressed: () => setState(() => _urlCtrl.clear()),
                icon: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.secondaryTextColor),
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6E8EE), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6E8EE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.6),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Obx(() {
      final loading = widget.controller.isUpdating.value;
      return SizedBox(
        width: double.infinity,
        child: CustomBtn(
          height: 48,
          radius: 12,
          isValidate: _ready,
          bgColor: _ready
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.35),
          textColor: AppColors.white,
          isLoading: loading,
          title: loading ? null : 'Add Channel',
          onTap: (!_ready || loading) ? null : _submit,
        ),
      );
    });
  }
}

class _PlatformOption {
  final String key;
  final String label;
  final IconData icon;
  final Color brand;
  const _PlatformOption(this.key, this.label, this.icon, this.brand);
}
