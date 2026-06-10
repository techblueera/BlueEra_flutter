import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../personal/personal_profile/controller/languge_list_controller.dart';
import '../../model/get_categories_model.dart';

enum _AccountTab { business, professional, manufacturing }

class CreateAccountTypeScreen extends StatefulWidget {
  final String? accountType;

  /// Kept for call-site compatibility. With Personal merged into the
  /// Professional tab, this no longer changes the entry tab.
  final int initialIndividualIndex;

  const CreateAccountTypeScreen({
    super.key,
    this.accountType,
    this.initialIndividualIndex = 0,
  });

  @override
  State<CreateAccountTypeScreen> createState() => _CreateAccountTypeScreenState();
}

class _CreateAccountTypeScreenState extends State<CreateAccountTypeScreen>
    with TickerProviderStateMixin {
  final authController = getOrPut(() => AuthController());
  final LanguageListController langController =
      Get.find<LanguageListController>();

  /// Currently selected pill — `CategoryData` for business or
  /// `ProfessionTypeData` for individual.
  final Rxn<Object> selectedItem = Rxn<Object>();

  /// Sub-category picked in the bottom sheet alongside a business pill.
  /// Null for individual pills, manufacturing, or categories with no subs.
  final Rxn<SubCategories> selectedSubCategory = Rxn<SubCategories>();

  late final List<_AccountTab> _tabs;
  late final TabController _tabController;

  /// Debounces the overscroll-auto-advance gesture so a single fling
  /// doesn't skip past multiple tabs in one go.
  DateTime _lastAutoAdvance = DateTime.fromMillisecondsSinceEpoch(0);

  /// Pull distance (in logical pixels) past the bottom edge required to
  /// trigger the auto-advance. Tuned so it feels like a deliberate pull,
  /// not an accidental flick.
  static const double _autoAdvanceThreshold = 70.0;

  @override
  void initState() {
    super.initState();
    authController.loadCategoriesCacheFirstThenRefresh();

    _tabs = _buildTabs();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _initialTabIndex(),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _onTabChanged(_tabs[_tabController.index]);
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onTabChanged(_tabs[_tabController.index]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_AccountTab> _buildTabs() {
    final showBusiness =
        widget.accountType == null || widget.accountType == AppConstants.business;
    final showIndividual =
        widget.accountType == null || widget.accountType == AppConstants.individual;
    return [
      if (showBusiness) _AccountTab.business,
      if (showIndividual) _AccountTab.professional,
      if (showBusiness) _AccountTab.manufacturing,
    ];
  }

  int _initialTabIndex() {
    if (widget.accountType == AppConstants.individual) {
      final idx = _tabs.indexOf(_AccountTab.professional);
      return idx < 0 ? 0 : idx;
    }
    return 0;
  }

  String _labelFor(_AccountTab tab) {
    switch (tab) {
      case _AccountTab.business:
        return langController.tr('Business');
      case _AccountTab.professional:
        return langController.tr('Social / Professional');
      case _AccountTab.manufacturing:
        return langController.tr('Manufacturing');
    }
  }

  IconData _iconFor(_AccountTab tab) {
    switch (tab) {
      case _AccountTab.business:
        return Icons.storefront_outlined;
      case _AccountTab.professional:
        return Icons.person_outline;
      case _AccountTab.manufacturing:
        return Icons.precision_manufacturing_outlined;
    }
  }

  void _onTabChanged(_AccountTab tab) {
    selectedItem.value = null;
    selectedSubCategory.value = null;
    switch (tab) {
      case _AccountTab.business:
      case _AccountTab.manufacturing:
        authController.selectedParentSlug.value = AppConstants.business;
        authController.selectedIndividualOnboardingProfile.value = null;
        break;
      case _AccountTab.professional:
        authController.selectedParentSlug.value = AppConstants.individual;
        authController.selectedBusinessOnboardingProfile.value = null;
        break;
    }
  }

  /// Confirmation dialog shown for every exit attempt (app-bar back, system
  /// back button, and edge-swipe gesture). "Yes" lands the user on the main
  /// bottom-navigation home; "No" keeps them on this screen.
  void _confirmExit() {
    commonConformationDialog(
      context: context,
      text: langController.tr('Are you sure you want to leave this screen?'),
      confirmCallback: () {
        Navigator.of(context, rootNavigator: true).pop();
        Get.offAllNamed(RouteHelper.getBottomNavigationBarScreenRoute());
      },
      cancelCallback: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }

  /// Called by [_OverscrollAdvancer] once the user has pulled past the
  /// bottom edge by [_autoAdvanceThreshold] pixels. Forward-only — bails
  /// at the last tab so the user never wraps unexpectedly. Debounced so a
  /// single fling can't skip past multiple tabs.
  void _maybeAdvanceTab() {
    final now = DateTime.now();
    if (now.difference(_lastAutoAdvance).inMilliseconds < 600) return;
    final next = _tabController.index + 1;
    if (next >= _tabs.length) return;
    _lastAutoAdvance = now;
    _tabController.animateTo(next);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CommonBackAppBar(
          isLeading: true,
          appBarColor: Colors.white,
          title: AppStrings.chooseYourAccountType,
          onBackTap: _confirmExit,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTopTabs(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F5FB),
                  child: Obx(() {
                    // Subscribe to every onboarding bucket so the silent
                    // network refresh repaints the category grid even on the
                    // cache-hit path (where isInitialCategoriesLoading never
                    // flips again). The grid items are read across a build
                    // boundary, so this explicit read is what registers the dep.
                    authController.onboardingBucketsWatch;
                    if (authController.isInitialCategoriesLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Touch the selection Rx so the body rebuilds when a
                    // pill is tapped (so its highlight state updates).
                    selectedItem.value;
                    return TabBarView(
                      controller: _tabController,
                      children: _tabs.map(_buildBodyForTab).toList(),
                    );
                  }),
                ),
              ),
              _buildBottomNext(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size20,
        SizeConfig.size8,
        SizeConfig.size20,
        SizeConfig.size12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            langController.tr('Pick what describes you best'),
            fontSize: SizeConfig.size18,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),

        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.secondaryTextColor,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 3,
        labelPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
        labelStyle: TextStyle(
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs
            .map(
              (t) => Tab(
                height: SizeConfig.size48,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(t), size: SizeConfig.size18),
                    SizedBox(width: SizeConfig.size6),
                    Text(_labelFor(t)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBodyForTab(_AccountTab tab) {
    Widget body;
    switch (tab) {
      case _AccountTab.business:
        body = _sectionedBusinessBody([
          _Section(
            title: langController.tr('Grocery & Stationary Stores'),
            items: authController.businessOnboardingGroceriesCategories,
          ),
          _Section(
            title: langController.tr('Food & Restaurant'),
            items: authController.businessOnboardingFoodsCategories,
          ),
          _Section(
            title: langController.tr('Shop & Store'),
            items: authController.businessOnboardingProductsCategories,
          ),
          _Section(
            title: langController.tr('Services'),
            items: authController.businessOnboardingServicesCategories,
          ),
          _Section(
            title: langController.tr('Automotive Services'),
            items: authController.businessOnboardingAutomotiveServicesCategories,
          ),
          _Section(
            title: langController.tr('Health Care'),
            items: authController.businessOnboardingHealthcareSectorsCategories,
          ),
          _Section(
            title: langController.tr('Hospitality & Stay'),
            items: authController.businessOnboardingHospitalityStayCategories,
          ),
          _Section(
            title: langController.tr('Education & Training Sectors'),
            items: authController.businessOnboardingEducationTrainingCategories,
          ),
          _Section(
            title: langController.tr('Financial Sectors'),
            items: authController.businessOnboardingFinancialSectorsCategories,
          ),
        ]);
        break;
      case _AccountTab.manufacturing:
        body = _sectionedBusinessBody([
          _Section(
            title: langController.tr('Manufacturing'),
            items: authController.businessOnboardingManufacturingCategories,
          ),
        ]);
        break;
      case _AccountTab.professional:
        body = _sectionedIndividualBody([
          _IndividualSection(
            title: langController.tr('Skill Work'),
            items: authController.individualOnboardingSkillWorkList,
          ),
          _IndividualSection(
            title: langController.tr('Self Employed'),
            items: authController.individualOnboardingGigWorkList,
          ),
          _IndividualSection(
            title: langController.tr('Consultant'),
            items: authController.individualOnboardingConsultationList,
          ),
          _IndividualSection(
            title: langController.tr('Social Profile'),
            items: authController.individualOnboardingSocialProfileList,
          ),
        ]);
        break;
    }
    return _OverscrollAdvancer(
      threshold: _autoAdvanceThreshold,
      onTriggered: _maybeAdvanceTab,
      child: body,
    );
  }

  Widget _sectionedBusinessBody(List<_Section> sections) {
    final nonEmpty = sections.where((s) => s.items.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return EmptyStateWidget(message: langController.tr('No category found'));
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in nonEmpty) ...[
            _sectionCard(
              title: section.title,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: SizeConfig.size10,
                runSpacing: SizeConfig.size12,
                children: section.items.map(_businessPill).toList(),
              ),
            ),
            SizedBox(height: SizeConfig.size16),
          ],
          // _endOfListHint(),
        ],
      ),
    );
  }

  Widget _sectionedIndividualBody(List<_IndividualSection> sections) {
    final nonEmpty = sections.where((s) => s.items.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return EmptyStateWidget(message: langController.tr('No profession found'));
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in nonEmpty) ...[
            _sectionCard(
              title: section.title,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: SizeConfig.size10,
                runSpacing: SizeConfig.size12,
                children: section.items.map(_individualPill).toList(),
              ),
            ),
            SizedBox(height: SizeConfig.size16),
          ],
          // _endOfListHint(),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomText(
            title,
            fontSize: SizeConfig.size16,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size12),
          child,
        ],
      ),
    );
  }


  Widget _businessPill(CategoryData c) {
    final selected = identical(selectedItem.value, c);
    return _pill(
      label: c.name ?? '',
      selected: selected,
      onTap: () => _onBusinessPillTap(c),
    );
  }

  Widget _individualPill(ProfessionTypeData p) {
    final selected = identical(selectedItem.value, p);
    return _pill(
      label: p.name ?? '',
      selected: selected,
      onTap: () {
        selectedItem.value = p;
        selectedSubCategory.value = null;
      },
    );
  }

  Future<void> _onBusinessPillTap(CategoryData c) async {
    // Manufacturing has no sub-categories — select directly.
    if (c.businessType == BusinessType.Manufacturing) {
      selectedItem.value = c;
      selectedSubCategory.value = null;
      return;
    }
    final tagId = c.tagId;
    if (tagId == null) {
      selectedItem.value = c;
      selectedSubCategory.value = null;
      return;
    }
    final picked = await showModalBottomSheet<_SubCategoryPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BusinessSubCategoryBottomSheet(
        authController: authController,
        categorySlugId: tagId,
        categoryName: c.name ?? '',
      ),
    );
    if (picked == null) return; // dismissed
    selectedItem.value = c;
    selectedSubCategory.value = picked.subCategory;
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(SizeConfig.size30),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size30),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : AppColors.greyE5,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(
                Icons.check_circle,
                size: SizeConfig.size16,
                color: AppColors.white,
              ),
              SizedBox(width: SizeConfig.size6),
            ],
            CustomText(
              label,
              fontSize: SizeConfig.medium,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.white : AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNext() {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size12,
          ),
          child: Obx(() {
            final canProceed = selectedItem.value != null;
            return CustomBtn(
              radius: SizeConfig.size30,
              isValidate: canProceed,
              bgColor: canProceed ? AppColors.primaryColor : AppColors.whiteF3,
              textColor: canProceed ? AppColors.white : AppColors.grey9B,
              title: 'Next',
              onTap: canProceed ? _onNext : null,
            );
          }),
        ),
      ),
    );
  }

  void _onNext() {
    final item = selectedItem.value;
    if (item == null) return;
    if (item is CategoryData) {
      final type = item.businessType;
      final tagId = item.tagId;
      final name = item.name;
      if (type == null || tagId == null || name == null) return;
      navigateToGstScreen(
        context,
        businessType: type,
        categorySlugId: tagId,
        categoryName: name,
        subCategory: selectedSubCategory.value,
      );
    } else if (item is ProfessionTypeData) {
      log('---------------- LOG DATA ----------------');
      log('${ApiKeys.argProfileType} : ${item.individualProfileType?.tagId}');
      log('${ApiKeys.argProfessionTagId}    : ${item.tagId}');
      log('${ApiKeys.argProfession}    : ${item.name}');

      Get.toNamed(
        RouteHelper.getPersonalAccountNewScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: AppConstants.individual,
          ApiKeys.argProfileType: item.individualProfileType,
          ApiKeys.argProfessionTagId: item.tagId,
          ApiKeys.argProfession: item.name,
        },
      );
    }
  }

  void navigateToGstScreen(
    BuildContext context, {
    required BusinessType businessType,
    required String categorySlugId,
    required String categoryName,
    SubCategories? subCategory,
  }) {
    Navigator.pushNamed(
      context,
      RouteHelper.getGstNumberScreenRoute(),
      arguments: {
        ApiKeys.argAccountType: AppConstants.business,
        ApiKeys.argBusinessType: businessType,
        ApiKeys.argCategoryId: categorySlugId,
        ApiKeys.argCategoryName: categoryName,
        ApiKeys.argSubCategory: subCategory,
      },
    );
  }
}

class _Section {
  final String title;
  final List<CategoryData> items;
  _Section({required this.title, required this.items});
}

class _IndividualSection {
  final String title;
  final List<ProfessionTypeData> items;
  _IndividualSection({required this.title, required this.items});
}

class _SubCategoryPickResult {
  final SubCategories? subCategory;
  _SubCategoryPickResult(this.subCategory);
}

/// Wraps a scrollable child and fires [onTriggered] once the user has
/// dragged past the bottom edge by [threshold] logical pixels in a single
/// gesture. Accumulates [OverscrollNotification.overscroll] so a tiny flick
/// past the edge doesn't count — the user has to deliberately pull. Resets
/// every time scrolling settles, so each new gesture is fresh.
class _OverscrollAdvancer extends StatefulWidget {
  final Widget child;
  final VoidCallback onTriggered;
  final double threshold;

  const _OverscrollAdvancer({
    required this.child,
    required this.onTriggered,
    this.threshold = 70.0,
  });

  @override
  State<_OverscrollAdvancer> createState() => _OverscrollAdvancerState();
}

class _OverscrollAdvancerState extends State<_OverscrollAdvancer> {
  double _pulledPastEnd = 0;
  bool _firedForGesture = false;

  bool _onNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;

    if (n is OverscrollNotification) {
      // Positive overscroll == forward direction (dragging past the bottom
      // edge of a vertical list). Ignore overscroll at the top.
      if (n.overscroll > 0) {
        _pulledPastEnd += n.overscroll;
        if (!_firedForGesture && _pulledPastEnd >= widget.threshold) {
          _firedForGesture = true;
          widget.onTriggered();
        }
      }
    } else if (n is ScrollUpdateNotification) {
      // If the user reverses direction and scrolls back up, throw away the
      // accumulated pull so they have to start over.
      final delta = n.scrollDelta;
      if (delta != null && delta < 0) {
        _pulledPastEnd = 0;
        _firedForGesture = false;
      }
    } else if (n is ScrollEndNotification) {
      _pulledPastEnd = 0;
      _firedForGesture = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}

class BusinessSubCategoryBottomSheet extends StatefulWidget {
  final AuthController authController;
  final String categorySlugId;
  final String categoryName;

  const BusinessSubCategoryBottomSheet({
    super.key,
    required this.authController,
    required this.categorySlugId,
    required this.categoryName,
  });

  @override
  State<BusinessSubCategoryBottomSheet> createState() =>
      _BusinessSubCategoryBottomSheetState();
}

class _BusinessSubCategoryBottomSheetState
    extends State<BusinessSubCategoryBottomSheet> {
  final LanguageListController langController =
      Get.find<LanguageListController>();
  SubCategories? _selectedSubCat;

  @override
  void initState() {
    super.initState();
    widget.authController
        .fetchBusinessSubCategories(categorySlugId: widget.categorySlugId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SizeConfig.size16),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: SizeConfig.size8),
              Container(
                width: SizeConfig.size40,
                height: SizeConfig.size4,
                decoration: BoxDecoration(
                  color: AppColors.greyE5,
                  borderRadius: BorderRadius.circular(SizeConfig.size4),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.categoryName.replaceAll('\n', ' '),
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.size16,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(SizeConfig.size20),
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.size4),
                        child: Icon(
                          Icons.close,
                          size: SizeConfig.size20,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.greyE5),
              Expanded(
                child: Obx(() {
                  if (widget.authController
                      .isBusinessSubCategoriesLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (widget.authController.subCategoryErrorMessage.value !=
                      null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.size20),
                        child: CustomText(
                          widget.authController.subCategoryErrorMessage.value!,
                          color: AppColors.red,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final subs =
                      widget.authController.businessSubCategoriesList;
                  if (subs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.size20),
                        child: CustomText(
                          langController.tr('No sub-categories found.'),
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                    itemCount: subs.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.greyE5),
                    itemBuilder: (context, index) {
                      final item = subs[index];
                      final isSelected = _selectedSubCat?.sId == item.sId;
                      return ListTile(
                        dense: true,
                        title: CustomText(
                          item.name ?? AppStrings.unknown,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: SizeConfig.size15,
                          color: AppColors.mainTextColor,
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: AppColors.primaryColor,
                                size: SizeConfig.size22)
                            : null,
                        onTap: () => setState(() => _selectedSubCat = item),
                      );
                    },
                  );
                }),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size20,
                    vertical: SizeConfig.size12,
                  ),
                  child: Obx(() {
                    final subs =
                        widget.authController.businessSubCategoriesList;
                    final loading = widget
                        .authController.isBusinessSubCategoriesLoading.value;
                    final canConfirm = !loading &&
                        (subs.isEmpty || _selectedSubCat != null);
                    return CustomBtn(
                      radius: SizeConfig.size30,
                      isValidate: canConfirm,
                      bgColor: canConfirm
                          ? AppColors.primaryColor
                          : AppColors.whiteF3,
                      textColor:
                          canConfirm ? AppColors.white : AppColors.grey9B,
                      title: 'Done',
                      onTap: canConfirm
                          ? () => Navigator.of(context)
                              .pop(_SubCategoryPickResult(_selectedSubCat))
                          : null,
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
