import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/repo/referral_repo.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSocialLinkSheet extends StatefulWidget {
  final ReferralController controller;
  const AddSocialLinkSheet({super.key, required this.controller});

  @override
  State<AddSocialLinkSheet> createState() => _AddSocialLinkSheetState();
}

class _AddSocialLinkSheetState extends State<AddSocialLinkSheet> {
  final TextEditingController _urlCtrl = TextEditingController();

  /// The platform the user is targeting. Either auto-set from the URL
  /// (when the user hasn't tapped a chip) or whatever chip the user
  /// last tapped.
  String _platform = 'unknown';

  /// Platform inferred from the current URL string. Kept separate from
  /// [_platform] so we can detect mismatches when the user has picked
  /// a chip that disagrees with what they pasted.
  String _detectedFromUrl = 'unknown';

  /// The cleaned, tracking-free URL the backend will actually receive —
  /// recomputed on every edit so we can preview it to the user when it
  /// differs from what they pasted (e.g. a share link with an `si` token).
  String _canonicalUrl = '';

  /// True once the user has explicitly tapped any chip. While this is
  /// false the chip selection passively mirrors [_detectedFromUrl]; as
  /// soon as the user picks one, we stop auto-overriding and start
  /// surfacing mismatches.
  bool _userSelectedChip = false;

  static const _platforms = <_PlatformOption>[
    _PlatformOption(
      key: 'instagram',
      label: 'Instagram',
      icon: Icons.camera_alt_outlined,
      brand: Color(0xFFE1306C),
    ),
    _PlatformOption(
      key: 'twitter',
      label: 'X / Twitter',
      icon: Icons.alternate_email,
      brand: Color(0xFF1DA1F2),
    ),
    _PlatformOption(
      key: 'youtube',
      label: 'YouTube',
      icon: Icons.play_circle_fill,
      brand: Color(0xFFFF0000),
    ),
  ];

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    final detected = ReferralRepoNew.detectPlatform(value);
    final newPlatform = _userSelectedChip ? _platform : detected;
    final canonical = value.trim().isEmpty
        ? ''
        : ReferralRepoNew.canonicalizeSharedUrl(value);
    if (detected == _detectedFromUrl &&
        newPlatform == _platform &&
        canonical == _canonicalUrl) {
      return;
    }
    setState(() {
      _detectedFromUrl = detected;
      _platform = newPlatform;
      _canonicalUrl = canonical;
    });
  }

  /// Replaces the field with the cleaned URL so what the user sees matches
  /// exactly what gets saved. Moves the caret to the end after applying.
  void _applyCleanedUrl() {
    _urlCtrl.value = TextEditingValue(
      text: _canonicalUrl,
      selection: TextSelection.collapsed(offset: _canonicalUrl.length),
    );
    _onUrlChanged(_canonicalUrl);
  }

  /// True when normalization actually changed the link (supported platform,
  /// no mismatch) — only then is the preview worth showing.
  bool get _showCleanedPreview =>
      _canonicalUrl.isNotEmpty &&
      _detectedFromUrl != 'unknown' &&
      !_hasMismatch &&
      _canonicalUrl != _urlCtrl.text.trim();

  void _selectPlatform(String key) {
    setState(() {
      _platform = key;
      _userSelectedChip = true;
    });
  }

  /// True when the user has picked a chip whose platform doesn't match
  /// the URL they pasted (and the URL is recognised).
  bool get _hasMismatch =>
      _userSelectedChip &&
      _detectedFromUrl != 'unknown' &&
      _detectedFromUrl != _platform;

  /// True when the URL is non-empty but doesn't match any supported
  /// platform — e.g. a random Wikipedia link.
  bool get _hasUnsupportedUrl =>
      _urlCtrl.text.trim().isNotEmpty && _detectedFromUrl == 'unknown';

  /// Looks up the friendly label for a platform key, falling back to
  /// the raw key when nothing matches (shouldn't happen in practice).
  String _labelFor(String key) => _platforms
      .firstWhere(
        (p) => p.key == key,
        orElse: () => const _PlatformOption(
          key: '',
          label: '',
          icon: Icons.link,
          brand: Colors.grey,
        ),
      )
      .label;

  bool get _ready =>
      _platform != 'unknown' &&
      _urlCtrl.text.trim().length > 8 &&
      !_hasMismatch &&
      !_hasUnsupportedUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size16,
              SizeConfig.size10,
              SizeConfig.size16,
              SizeConfig.size16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dragHandle(),
                SizedBox(height: SizeConfig.size12),
                _header(),
                SizedBox(height: SizeConfig.paddingM),
                _stepLabel(1, 'PICK A PLATFORM'),
                const SizedBox(height: 10),
                _platformRow(),
                SizedBox(height: SizeConfig.paddingM),
                _stepLabel(2, 'PASTE YOUR URL'),
                const SizedBox(height: 10),
                _urlField(),
                _validationBanner(),
                _cleanedUrlPreview(),
                _instagramNote(),
                SizedBox(height: SizeConfig.paddingM),
                _submitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Drag handle ────────────────────────────────────────────────────
  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Title row with close button ────────────────────────────────────
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.link_rounded,
              color: AppColors.primaryColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'Add a video link',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 2),
              CustomText(
                'Bring your reels in from anywhere.',
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.greyE5.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded,
                size: 18, color: AppColors.secondaryTextColor),
          ),
        ),
      ],
    );
  }

  // ── Numbered step label ────────────────────────────────────────────
  Widget _stepLabel(int n, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CustomText(
          text,
          fontSize: SizeConfig.extraSmall,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
          letterSpacing: 1.2,
        ),
      ],
    );
  }

  // ── Three platform chips ───────────────────────────────────────────
  Widget _platformRow() {
    return Row(
      children: [
        for (int i = 0; i < _platforms.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _platformChip(_platforms[i])),
        ],
      ],
    );
  }

  Widget _platformChip(_PlatformOption opt) {
    final selected = _platform == opt.key;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        // Selection now lives in the BORDER, not the fill — chip
        // stays white either way so the icon's brand color reads
        // cleanly. Width steps up from 1 → 1.8 on selection.
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.primaryColor
              : const Color(0xFFE6E8EE),
          width: selected ? 1.8 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPlatform(opt.key),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
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
                CustomText(
                  opt.label,
                  fontSize: SizeConfig.small,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── URL field ──────────────────────────────────────────────────────
  //
  // Plain Material TextField — no controller listeners or auto-prefix
  // logic. Paste lands instantly and a single onChanged fires per
  // edit, which avoids the rebuild double-hit the previous wrapper
  // caused.
  Widget _urlField() {
    final showError = _hasMismatch || _hasUnsupportedUrl;
    final borderColor = showError ? AppColors.red : const Color(0xFFE6E8EE);
    final focusedBorderColor =
        showError ? AppColors.red : AppColors.primaryColor;
    return TextField(
      controller: _urlCtrl,
      onChanged: _onUrlChanged,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      maxLines: 1,
      style: TextStyle(
        fontSize: SizeConfig.medium,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Paste your link here',
        hintStyle: TextStyle(
          fontSize: SizeConfig.medium,
          color: AppColors.secondaryTextColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.link_rounded,
              color: AppColors.primaryColor, size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        suffixIcon: _urlCtrl.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _urlCtrl.clear();
                  _onUrlChanged('');
                },
                icon: Icon(Icons.close_rounded,
                    size: 18,
                    color: AppColors.secondaryTextColor),
                splashRadius: 18,
              ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: focusedBorderColor, width: 1.6),
        ),
      ),
    );
  }

  // ── Inline validation banner ───────────────────────────────────────
  //
  // Shown when the URL the user pasted doesn't agree with the platform
  // they picked, OR when the URL doesn't match any supported platform
  // at all. Animates in / out so it doesn't pop the layout.
  Widget _validationBanner() {
    String? message;
    if (_hasMismatch) {
      message = 'You picked ${_labelFor(_platform)}, but this looks '
          'like a ${_labelFor(_detectedFromUrl)} link. Switch the '
          'platform above or paste a ${_labelFor(_platform)} URL.';
    } else if (_hasUnsupportedUrl) {
      message = "We can only add Instagram, X / Twitter or YouTube "
          "links right now.";
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.red.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: AppColors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      message,
                      fontSize: SizeConfig.small,
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Cleaned-URL preview ────────────────────────────────────────────
  //
  // Surfaces the canonical, tracking-free link the backend will receive
  // whenever it differs from what the user pasted — so "copied from
  // share" (with `si` / `igsh` tokens or wrapping text) visibly resolves
  // to the same clean address as "copied from browser". Tap to apply it
  // to the field; submitting already sends the cleaned form regardless.
  Widget _cleanedUrlPreview() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: !_showCleanedPreview
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.30),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _applyCleanedUrl,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_fix_high_rounded,
                            color: AppColors.primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText(
                                'Will be saved as',
                                fontSize: SizeConfig.extraSmall,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryColor,
                                letterSpacing: 0.6,
                              ),
                              const SizedBox(height: 2),
                              CustomText(
                                _canonicalUrl,
                                fontSize: SizeConfig.small,
                                color: AppColors.mainTextColor,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomText(
                          'Apply',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Instagram heads-up note ────────────────────────────────────────
  //
  // Instagram's login wall often blocks preview scraping, so an IG link
  // can save without a thumbnail/caption (YouTube & X resolve reliably).
  // Surface that *before* the user submits — both so they understand a
  // missing preview later isn't a bug, and so they know the link still
  // works. Shown whenever Instagram is the active platform and there's
  // no blocking validation error.
  Widget _instagramNote() {
    final show = _platform == 'instagram' &&
        !_hasMismatch &&
        !_hasUnsupportedUrl;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE1306C).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE1306C).withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFE1306C), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      'Instagram limits link previews, so the thumbnail '
                      'and caption may not load. Your link will still be '
                      'saved and will open in Instagram.',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────
  //
  // While the create-post API is in flight we swap the button for a
  // compact "Generating…" state — a small circular spinner + label —
  // instead of CustomBtn's wave loader, which reads as a heavier
  // "uploading" affordance than fits a metadata fetch. The loading
  // state is non-tappable, so it doubles as the double-submit guard.
  Widget _submitButton() {
    return Obx(() {
      if (widget.controller.creatingPost.value) {
        return _generatingState();
      }
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
          isLoading: false,
          onTap: !_ready
              ? null
              : () async {
                  final ok = await widget.controller
                      .createUserPost(_urlCtrl.text);
                  if (ok && mounted) Navigator.of(context).pop();
                },
          title: 'Add Link',
        ),
      );
    });
  }

  /// In-flight state for the submit button: small circular indicator +
  /// "Generating…". Matches the active button's size/shape so the layout
  /// doesn't jump when it swaps in.
  Widget _generatingState() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.white),
            ),
          ),
          const SizedBox(width: 10),
          CustomText(
            'Generating…',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _PlatformOption {
  final String key;
  final String label;
  final IconData icon;
  final Color brand;
  const _PlatformOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.brand,
  });
}
