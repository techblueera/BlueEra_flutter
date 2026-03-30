import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/common/store/view/business_store_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ProductsStoreScreen extends StatefulWidget {
  final String? typeOfBusiness;
  final String? selectedStoreCategoryId;
  final String? selectedStoreCategoryName;

  const ProductsStoreScreen({
    super.key,
    this.typeOfBusiness,
    this.selectedStoreCategoryId,
    this.selectedStoreCategoryName,
  });

  @override
  State<ProductsStoreScreen> createState() => _ProductsStoreScreenState();
}

class _ProductsStoreScreenState extends State<ProductsStoreScreen> {
  final controller = getOrPut(() => NewStoreController());
  final ScrollController storesScrollController = ScrollController();
  final List<OnboardingCategoryModel> _categories = businessProductStoreCategories;
  final RxInt _selectedIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    controller.typeOfBusiness = widget.typeOfBusiness;

    if (widget.selectedStoreCategoryId != null) {
      controller.businessCategoryId = widget.selectedStoreCategoryId;
      final idx = _categories.indexWhere((c) => c.slugId == widget.selectedStoreCategoryId);
      if (idx >= 0) _selectedIndex.value = idx;
    } else {
      controller.businessCategoryId = _categories.first.slugId;
    }

    controller.getAllStoreNearBy();
    storesScrollController.addListener(_onLoadMore);
  }

  void _onLoadMore() {
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    storesScrollController.removeListener(_onLoadMore);
    storesScrollController.dispose();
    super.dispose();
  }

  void _onCategoryTap(OnboardingCategoryModel item, int index) {
    _selectedIndex.value = index;
    controller.businessCategoryId = item.slugId;
    controller.getAllStoreNearBy();
  }

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.screenWidth;

    double dynamicSize(double base) => base * (width / 390);

    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final idx = _selectedIndex.value;
          final name = (idx >= 0 && idx < _categories.length)
              ? _categories[idx].name
              : 'Stores';
          return Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        buildCustomActionWidget: () {
          final chat = ChatViewController.inventoryAiChatListSearchModule;
          return IconButton(
            onPressed: () {
              Get.to(() => AiCommonSearchScreen(
                chatType: AppConstants.askInventory_Chat_Type,
                profileImage: chat?.sender?.profileImage,
                name: chat?.sender?.name,
                contactNo: chat?.sender?.contactNo,
                conversationId: '',
                userId: '',
                businessId: '',
                type: chat?.sender?.accountType,
                isInitialMessage: false,
              ));
            },
            icon: Icon(
              Icons.auto_awesome,
              color: AppColors.primaryColor,
              size: SizeConfig.size24,
            ),
          );
        },
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryList(),
            SizedBox(width: SizeConfig.size6),
            Expanded(child: _buildStoreContent(dynamicSize)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: _categories,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        final idx = _categories.indexOf(item);
        return _selectedIndex.value == idx;
      },
      onTap: _onCategoryTap,
    );
  }

  Widget _buildStoreContent(double Function(double) dynamicSize) {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allStore.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message: "No ${_categories[_selectedIndex.value].name} stores found",
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store count chip
          Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.paddingS,
              right: SizeConfig.paddingXS,
              bottom: SizeConfig.size6,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greyE5, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded,
                      size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 6),
                  CustomText(
                    "${controller.allStore.length}${controller.isAllStoreLoadingMore.value ? '+' : ''} Stores",
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
          ),

          // Store list
          Expanded(
            child: ListView.builder(
              controller: storesScrollController,
              padding: EdgeInsets.only(
                right: SizeConfig.paddingXS,
                bottom: SizeConfig.paddingL,
              ),
              itemCount: controller.allStore.length +
                  (controller.isAllStoreLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.allStore.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final storeData = controller.allStore[index];
                final String businessId = storeData.id ?? "";

                return VisibilityDetector(
                  key: Key("business_$businessId"),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction >= 0.5 && businessId.isNotEmpty) {
                      trackBusinessStoreView(businessId);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: dynamicSize(10)),
                    child: BusinessStoreCard(
                      ds: dynamicSize,
                      getAllStoreResData: storeData,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  final Set<String> _viewedBusinessIds = {};

  void trackBusinessStoreView(String storeId) {
    if (kReleaseMode) {
      Future.microtask(() async {
        try {
          if (!_viewedBusinessIds.contains(storeId)) {
            _viewedBusinessIds.add(storeId);
            StoreRepo().businessByViewCountIDApi(businessId: storeId);
          }
        } catch (e) {
          print("Failed to track view: $e");
        }
      });
    }
  }
}
