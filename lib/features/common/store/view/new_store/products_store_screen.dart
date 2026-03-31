import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/business_store_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ProductsStoreScreen extends StatefulWidget {
  final String? productCategoryName;
  final String? productCategory;

  const ProductsStoreScreen({
    super.key,
    this.productCategoryName,
    this.productCategory,
  });

  @override
  State<ProductsStoreScreen> createState() => _ProductsStoreScreenState();
}

class _ProductsStoreScreenState extends State<ProductsStoreScreen> {
  final controller = getOrPut(() => NewStoreController());
  final ScrollController storesScrollController = ScrollController();
  final Rxn<SubCategories> _selectedSubCategory = Rxn<SubCategories>();
  late final List<SubCategories> _subCategories;

  @override
  void initState() {
    super.initState();
    controller.typeOfBusiness = BusinessType.Product.name;

    // Find the parent category and extract its subcategories
    final categories = Get.find<AuthController>().businessOnboardingProductsCategories;
    final parent = categories.firstWhereOrNull((c) => c.tagId == widget.productCategory);
    _subCategories = parent?.subCategories ?? [];

    if (_subCategories.isNotEmpty) {
      _selectedSubCategory.value = _subCategories.first;
      controller.businessCategoryId = _subCategories.first.sId;
    } else {
      controller.businessCategoryId = widget.productCategory;
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

  void _onSubCategoryTap(SubCategories item, int index) {
    _selectedSubCategory.value = item;
    controller.businessCategoryId = item.sId;
    controller.getAllStoreNearBy();
  }

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.screenWidth;
    double dynamicSize(double base) => base * (width / 390);

    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final name = _selectedSubCategory.value?.name ??
              widget.productCategoryName ?? 'Stores';
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
            if (_subCategories.isNotEmpty) _buildSubCategoryList(),
            SizedBox(width: SizeConfig.size6),
            Expanded(child: _buildStoreContent(dynamicSize)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryList() {
    return CommonGenericLeftSideCategoryList<SubCategories>(
      items: _subCategories,
      getLabel: (item) => item.name ?? '',
      getIcon: (item) => '',
      isSelected: (item) =>
          _selectedSubCategory.value?.sId == item.sId,
      onTap: _onSubCategoryTap,
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
            message: "No ${_selectedSubCategory.value?.name ?? ''} stores found",
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
                      controller.trackStoreListView(businessId);
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
}
