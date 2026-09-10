import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/profile_category/controller/profile_category_controller.dart';
import 'package:BlueEra/features/common/profile_category/model/category_option.dart';
import 'package:BlueEra/features/common/profile_category/widget/change_category_confirm_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The picker for the one-time category change (§6).
///
/// Lists the catalog the state's `options_endpoint` pointed at — professions
/// for an individual, business categories for a business — with the CURRENT
/// category pre-selected and un-selectable, because picking it is rejected
/// (`409 same_category`) and there is nothing useful to do with that error.
///
/// Everything about the submit lives behind [ChangeCategoryConfirmSheet]: this
/// screen only chooses. That split exists because the confirmation is the last
/// point the user can back out of something they get to do exactly once.
class ChangeCategoryScreen extends StatefulWidget {
  const ChangeCategoryScreen({super.key, required this.controller});

  final ProfileCategoryController controller;

  @override
  State<ChangeCategoryScreen> createState() => _ChangeCategoryScreenState();
}

class _ChangeCategoryScreenState extends State<ChangeCategoryScreen> {
  late final List<CategoryOption> _options;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  ProfileCategoryController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Driven by options_endpoint rather than by account type — §5 says to use
    // the endpoint the API named, so a future account type routes itself.
    _options = _controller.state.value.usesProfessionsCatalog
        ? CategoryOptionsSource.professions()
        : CategoryOptionsSource.businessCategories();
    _search.addListener(() {
      final next = _search.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CategoryOption> get _visible {
    if (_query.isEmpty) return _options;
    return _options
        .where((o) => o.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentTag = _controller.currentTagId;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: AppStrings.changeCategoryTitle.tr,
        isLeading: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size12,
                SizeConfig.size16, SizeConfig.size8),
            child: CustomText(
              AppStrings.changeCategoryOneTimeWarning.tr,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 3,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: AppStrings.searchCategories.tr,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size8),
          Expanded(
            child: _options.isEmpty
                // The catalogs live in AuthController and are loaded
                // cache-first at app start. Empty here means they haven't
                // arrived yet (or the fetch failed) — offering an empty picker
                // would read as "there is nothing to change to".
                ? _emptyState(AppStrings.changeCategoryNoOptions.tr)
                : _visible.isEmpty
                    ? _emptyState(AppStrings.noResultsFound.tr)
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            SizeConfig.size16,
                            0,
                            SizeConfig.size16,
                            MediaQuery.of(context).padding.bottom +
                                SizeConfig.size16),
                        itemCount: _visible.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: SizeConfig.size8),
                        itemBuilder: (_, i) {
                          final option = _visible[i];
                          return _OptionTile(
                            option: option,
                            isCurrent: option.tagId == currentTag,
                            onTap: () => _onPick(option),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) => Center(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: CustomText(
            message,
            textAlign: TextAlign.center,
            color: AppColors.secondaryTextColor,
            fontSize: SizeConfig.medium,
            maxLines: 4,
          ),
        ),
      );

  Future<void> _onPick(CategoryOption option) async {
    final changed = await showChangeCategoryConfirmSheet(
      context: context,
      controller: _controller,
      option: option,
    );
    if (changed == true && mounted) {
      // Hand the result back to the Settings screen, which owns the §9.1
      // profile re-fetch — this screen has no business refreshing controllers
      // it didn't open.
      Navigator.of(context).pop(true);
    }
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isCurrent,
    required this.onTap,
  });

  final CategoryOption option;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      // Pre-selected AND un-selectable: submitting the category you already
      // have comes back 409 same_category, so the picker simply doesn't let
      // it happen (§6).
      onTap: isCurrent ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.greyE5 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? AppColors.primaryColor : AppColors.whiteE5,
            width: isCurrent ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                option.name,
                fontSize: SizeConfig.medium,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
            ),
            if (isCurrent)
              CustomText(
                AppStrings.changeCategoryCurrent.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              )
            else
              Icon(Icons.chevron_right,
                  size: 20, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }
}

/// Opens the picker, guarding the two states in which it must not open.
/// Returns true when a change actually happened.
Future<bool> openChangeCategoryPicker(
  BuildContext context,
  ProfileCategoryController controller,
) async {
  if (!controller.isVisible) {
    logs('[ProfileCategory] picker suppressed — account has no category');
    return false;
  }
  if (!controller.canChange) {
    commonSnackBar(message: AppStrings.changeCategoryLimitReached.tr);
    return false;
  }
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ChangeCategoryScreen(controller: controller),
    ),
  );
  return result == true;
}
