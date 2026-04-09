import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/language_localization_service/language_model_new.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shown on first install (and any time the user has not yet picked a
/// language) so a brand-new user is never stuck inside the app in a
/// language they cannot read. The user can pick any language or tap
/// "Skip" to continue with the English default.
class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({super.key});

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  final LanguageControllerNew controller =
      getOrPut(() => LanguageControllerNew());

  final RxString _pendingCode = ''.obs;
  final RxBool _busy = false.obs;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  final langs = controller.languages;
                  if (langs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: langs.length,
                    itemBuilder: (context, index) {
                      final lang = langs[index];
                      return Obx(() {
                        final bool isSelected = _pendingCode.value == lang.code;
                        return _LanguageTile(
                          lang: lang,
                          isSelected: isSelected,
                          onTap: () => _pendingCode.value = lang.code,
                        );
                      });
                    },
                  );
                }),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              AppStrings.selectLanguage.tr,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: _busy.value ? null : _onSkip,
            child: CustomText(
              AppStrings.skip.tr,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final hasSelection = _pendingCode.value.isNotEmpty;
      final loading = _busy.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (!hasSelection || loading) ? null : _onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              disabledBackgroundColor:
                  AppColors.primaryColor.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : CustomText(
                    AppStrings.continueText.tr,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
          ),
        ),
      );
    });
  }

  Future<void> _onContinue() async {
    final code = _pendingCode.value;
    if (code.isEmpty) return;

    LanguageModelNew? lang;
    for (final l in controller.languages) {
      if (l.code == code) {
        lang = l;
        break;
      }
    }
    if (lang == null) return;

    _busy.value = true;
    try {
      if (!lang.isDownloaded && lang.code != 'en') {
        await controller.downloadLanguage(lang);
      }
      await controller.changeLanguage(lang);
      await _markSelectedAndProceed();
    } catch (_) {
      // Fall back to English so the user is never stranded.
      await LocalizationService().updateLanguage('en');
      await _markSelectedAndProceed();
    } finally {
      _busy.value = false;
    }
  }

  Future<void> _onSkip() async {
    _busy.value = true;
    try {
      // Default to English so a new user can always read the app.
      await LocalizationService().updateLanguage('en');
      await _markSelectedAndProceed();
    } finally {
      _busy.value = false;
    }
  }

  Future<void> _markSelectedAndProceed() async {
    await SharedPreferenceUtils.setSecureValue(
      SharedPreferenceUtils.hasSelectedLanguage,
      'true',
    );
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteHelper.getMobileNumberLoginRoute(),
      (route) => false,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageModelNew lang;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                lang.name,
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryColor : Colors.black87,
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? AppColors.primaryColor
                  : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}
