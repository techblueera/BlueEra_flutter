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
import 'package:flutter/rendering.dart';
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

  /// Single scroll view holding ALL tabs' content stacked vertically, so a
  /// scroll flows continuously from one tab straight into the next.
  final ScrollController _scrollController = ScrollController();

  /// One key per tab block — used to measure each block's scroll offset so the
  /// active tab can follow the scroll position (and a tab tap can scroll to it).
  late final List<GlobalKey> _tabKeys;

  /// The tab whose block is currently aligned to the top of the viewport.
  /// Tracked so we only react when scrolling actually crosses into a new tab.
  int _activeTab = 0;

  /// True while we animate the scroll in response to a TAB TAP, so the scroll
  /// listener doesn't fight the animation.
  bool _isAnimatingToTab = false;

  @override
  void initState() {
    super.initState();
    authController.loadCategoriesCacheFirstThenRefresh();

    _tabs = _buildTabs();
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
    _activeTab = _initialTabIndex();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _activeTab,
    );
    // Scroll position drives the active tab (scroll-spy).
    _scrollController.addListener(_onContentScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onTabChanged(_tabs[_activeTab]);
      // Land on the requested initial tab's section (no animation on entry).
      if (_activeTab != 0) _scrollToTab(_activeTab, animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  /// Scroll-spy: as the single scroll view moves, pick the tab whose block is
  /// currently at the top of the viewport and select it (so the indicator
  /// follows the scroll). Ignored while a tab-tap animation is driving the
  /// scroll, so the two don't fight.
  void _onContentScroll() {
    if (_isAnimatingToTab || !_scrollController.hasClients) return;
    final active = _computeActiveTab();
    if (active != _activeTab) _setActiveTab(active);
  }

  /// The tab whose block top has scrolled nearest to (but not past) the top of
  /// the viewport. Reaching the very bottom always selects the last tab, so a
  /// short final section still activates its tab.
  int _computeActiveTab() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 4) {
      return _tabKeys.length - 1;
    }
    int active = 0;
    for (int i = 0; i < _tabKeys.length; i++) {
      final off = _tabScrollOffset(_tabKeys[i]);
      if (off == null) continue;
      if (position.pixels >= off - SizeConfig.size48) active = i;
    }
    return active;
  }

  /// The scroll offset at which [key]'s block reaches the top of the viewport,
  /// or null when it can't be measured yet.
  double? _tabScrollOffset(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box == null || !box.attached) return null;
    try {
      final viewport = RenderAbstractViewport.of(box);
      return viewport.getOffsetToReveal(box, 0.0).offset;
    } catch (_) {
      return null;
    }
  }

  /// Make [index] the active tab: slide the indicator and run the tab-change
  /// side effects (reset selection, switch the parent slug).
  void _setActiveTab(int index) {
    _activeTab = index;
    if (_tabController.index != index) _tabController.animateTo(index);
    _onTabChanged(_tabs[index]);
  }

  /// Scrolls the content so [index]'s block sits at the top — used when a tab
  /// is tapped. Clamps to the scroll range so the last/short tab still lands.
  Future<void> _scrollToTab(int index, {bool animate = true}) async {
    if (!_scrollController.hasClients) return;
    final off = _tabScrollOffset(_tabKeys[index]);
    if (off == null) return;
    final position = _scrollController.position;
    final target =
        off.clamp(position.minScrollExtent, position.maxScrollExtent);
    _isAnimatingToTab = true;
    _setActiveTab(index);
    try {
      if (animate) {
        await _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    } finally {
      _isAnimatingToTab = false;
    }
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
                    // All tabs' content in ONE scroll view, each block keyed so
                    // the scroll-spy can track / scroll to it. Scrolling flows
                    // continuously from one tab straight into the next.
                    return SingleChildScrollView(
                      controller: _scrollController,
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
                          for (int i = 0; i < _tabs.length; i++)
                            KeyedSubtree(
                              key: _tabKeys[i],
                              child: _buildBodyForTab(_tabs[i]),
                            ),
                        ],
                      ),
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
        onTap: (index) => _scrollToTab(index),
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
    // Content-only — the single parent scroll view (in build) owns the scroll
    // so all tabs flow together.
    return body;
  }

  Widget _sectionedBusinessBody(List<_Section> sections) {
    final nonEmpty = sections.where((s) => s.items.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return EmptyStateWidget(message: langController.tr('No category found'));
    }
    return Column(
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
      ],
    );
  }

  Widget _sectionedIndividualBody(List<_IndividualSection> sections) {
    final nonEmpty = sections.where((s) => s.items.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return EmptyStateWidget(message: langController.tr('No profession found'));
    }
    return Column(
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
      ],
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
