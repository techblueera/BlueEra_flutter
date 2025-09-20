import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory_screen/model/detail_item.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/model/create_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/model/sub_category_root_category_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/repo/listing_form_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/model/category_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/model/subcategory_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/widgets/category_bottom_sheet.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:io' as io;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Represents one level in the category hierarchy
class CategoryLevel {
  final List<CategoryNode> items;
  final String selectedId;
  final String selectedName;

  CategoryLevel({
    required this.items,
    this.selectedId = '',
    this.selectedName = '',
  });

  CategoryLevel copyWith({List<CategoryNode>? items, String? selectedId, String? selectedName}) =>
      CategoryLevel(
        items: items ?? this.items,
        selectedId: selectedId ?? this.selectedId,
        selectedName: selectedName ?? this.selectedName,
      );
}

class SelectedColor {
  final Color color;
  final String name;

  SelectedColor(this.color, this.name);
}


class ManualListingScreenController extends GetxController {
  Rx<ApiResponse> getSubChildORRootCategroyResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createProductResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> updateProductFeatureResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> updatePriceAndWarrantyResponse = ApiResponse.initial('Initial').obs;

  // Pickers
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController shortDescriptionController = TextEditingController();
  final TextEditingController warrantyController = TextEditingController();
  final TextEditingController guidelineController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController availableStockController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController materialController = TextEditingController();

  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController variantController = TextEditingController();
  // Media state
  final RxString videoPublicUrl = ''.obs;
  final RxString videoFileKey = ''.obs;
  final Rxn<String> videoLocalPath = Rxn<String>(); // picked local video file path
  final RxList<String> imageLocalPaths = <String>[].obs; // up to 5

  // Create a unique GlobalKey for each instance
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Reactive Variables
  RxBool isLoading = false.obs;
  RxString selectedListingType = 'Listing Type'.obs;
  RxBool isNonReturnable = true.obs;
  RxBool showMoreDetails = false.obs;

  // Final selected leaf
  final selectedCategory = ''.obs;
  final RxString selectedCategoryId = ''.obs;

  // Dynamic multi-level state
  final RxList<CategoryLevel> categoryLevels = <CategoryLevel>[].obs;
  
  // Date Selection
  RxInt selectedDay = 0.obs;
  RxInt selectedMonth = 0.obs;
  RxInt selectedYear = 0.obs;

  // Wizard step management (1..3)
  final RxInt currentStep = 1.obs; // TEMP: start at Step 2 (Media) to update uploads faster
  static const int totalSteps = 4;

  // Dynamic product features (details-only fields; title generated as "Feature n")
  final RxList<TextEditingController> featureControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ].obs;

  // Dynamic options (attribute/value pairs)
  final RxList<TextEditingController> optionAttributeControllers = <TextEditingController>[
    TextEditingController(),
  ].obs;
  final RxList<TextEditingController> optionValueControllers = <TextEditingController>[
    TextEditingController(),
  ].obs;

  // UI state
  final RxBool showLinkField = false.obs;

  /// Breadcrumb path: [{id, name}]
  var breadcrumb = <CategoryData>[].obs;

  Rxn<List<CategoryData>> selectedBreadcrumb = Rxn<List<CategoryData>>();

  /// Cache categories per parentId
  final Map<String?, List<CategoryData>> _cache = {};

  /// Currently displayed categories
  var categories = <CategoryData>[].obs;
  var loading = false.obs;

  final RxList<String> tags = <String>[].obs;

  final List<String> durationTypes = ['Day', 'Week', 'Month', 'Year', 'Life Time'];

  /// product warranty variables
  RxString selectedProductDuration = 'Day'.obs;
  Rx<num> selectedProductValue = Rx<num>(1);

  // Get range based on selected duration
  List<num> get productValueRange {
    switch (selectedProductDuration.value) {
      case 'Day':
        return List.generate(30, (index) => index + 1);
      case 'Week':
        return List.generate(6, (index) => index + 1);
      case 'Month':
        return List.generate(12, (index) => index + 1);
      case 'Year':
        return List.generate(20, (index) => (index + 1)  * 0.5);
      default:
        return [1];
    }
  }

  Map<String, dynamic> get productWarrantyTime {
    switch (selectedProductDuration.value) {
      case 'Day':
        return {"day": selectedProductValue.value};
      case 'Week':
        return {"week": selectedProductValue.value};
      case 'Month':
        return {"month": selectedProductValue.value};
      case 'Year':
        return {"year": selectedProductValue.value};
      default:
        return {};
    }
  }


  /// product expiry variables
  RxString selectedExpiryDuration = 'Day'.obs;
  Rx<num> selectedExpiryValue = Rx<num>(1);

  // Get range based on selected duration
  List<num> get expiryValueRange {
    switch (selectedExpiryDuration.value) {
      case 'Day':
        return List.generate(30, (index) => index + 1);
      case 'Week':
        return List.generate(6, (index) => index + 1);
      case 'Month':
        return List.generate(12, (index) => index + 1);
      case 'Year':
        return List.generate(20, (index) => (index + 1)  * 0.5);
      case 'Life Time':
        return [1]; // Life time doesn't need a number range
      default:
        return [1];
    }
  }

  Map<String, dynamic> get expiryTime {
    switch (selectedExpiryDuration.value) {
      case 'Day':
        return {"day": selectedExpiryValue.value};
      case 'Week':
        return {"week": selectedExpiryValue.value};
      case 'Month':
        return {"month": selectedExpiryValue.value};
      case 'Year':
        return {"year": selectedExpiryValue.value};
      case 'Life Time':
        return {"lifetime": true};
      default:
        return {};
    }
  }


  RxList<SelectedColor> selectedColors = <SelectedColor>[].obs;

  RxString material = ''.obs;
  RxMap<String, String> variantSizes = <String, String>{
    'Micro': '',
    'Small': '',
    'Medium': '',
    'Large': '',
    'Extra Large': '',
  }.obs;
  final Map<String, TextEditingController> variantNameControllers = {};
  RxMap<String, bool> isEditingMap = <String, bool>{}.obs;

  final RxList<String> materials = <String>[].obs;

  final formKeyStep1 = GlobalKey<FormState>();
  final formKeyStep2 = GlobalKey<FormState>();
  final formKeyStep3 = GlobalKey<FormState>();
  // final formKeyStep4 = GlobalKey<FormState>();

  var detailsList = <DetailItem>[].obs;

  // @override
  // void onInit() {
  //   super.onInit();
  //   variantSizes.keys.forEach((key) {
  //     variantNameControllers[key] = TextEditingController(text: key);
  //     isEditingMap[key] = false;
  //   });
  // }

  String? productId;

  @override
  void onClose() {
    productNameController.dispose();
    skuController.dispose();
    shortDescriptionController.dispose();
    warrantyController.dispose();
    guidelineController.dispose();
    brandController.dispose();
    mrpController.dispose();
    sellingPriceController.dispose();
    availableStockController.dispose();
    tagsController.dispose();
    linkController.dispose();
    for (final c in featureControllers) {
      c.dispose();
    }
    for (final c in optionAttributeControllers) {
      c.dispose();
    }
    for (final c in optionValueControllers) {
      c.dispose();
    }
 titleController.dispose();
    variantController.dispose();
    materialController.dispose();
    super.onClose();
  }

  // Date Selection Methods
  void onDayChanged(int? day) { selectedDay.value = day ?? 0; }
  void onMonthChanged(int? month) { selectedMonth.value = month ?? 0; }
  void onYearChanged(int? year) { selectedYear.value = year ?? 0; }

  // Listing Type Selection
  void changeListingType(String type) { selectedListingType.value = type; }

  // Toggle Methods
  void toggleNonReturnable() { isNonReturnable.value = !isNonReturnable.value; }

  // Add Tag
  // void addTag() {
  //   if (tagsController.text.isNotEmpty) {
  //     Get.snackbar(
  //       'Tag Added',
  //       'Tag "${tagsController.text}" added successfully',
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.green,
  //       colorText: Colors.white,
  //     );
  //     tagsController.clear();
  //   }
  // }

  // Validation Methods
  String? validateProductName(String? value) {
    if (value == null || value.isEmpty) return 'Product name is required';
    if (value.length < 3) return 'Product name must be at least 3 characters';
    return null;
  }

  String? validateBrandName(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 3) return 'Brand name must be at least 3 characters';
    return null;
  }

  String? validateProductDescription(String? value) {
    if (value == null || value.isEmpty) return 'Product description is required';
    if (value.length < 50) return 'Product description name must be at least 50 characters';
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.isEmpty) return 'Category is required';
    return null;
  }

  String? validateFeatures(String? value, int i) {
    if (value == null || value.trim().isEmpty) {
      return "Validation Error, Feature ${i + 1} cannot be empty";
    }
    if (value.length < 20) {
      return "Validation Error, Feature ${i + 1} must be at least 20 characters";
    }
    return null;
  }

  String? validateBrand(String? value) {
    if (value == null || value.isEmpty) return 'Brand is required';
    return null;
  }

  String? validateMRP(String? value) {
    if (value == null || value.isEmpty) return 'MRP is required';
    if (double.tryParse(value) == null) return 'Please enter a valid price';
    if (double.parse(value) <= 0) return 'MRP must be greater than 0';
    return null;
  }

  String? validateUserGuidance(String? value) {
    if (value == null || value.isEmpty) return 'User guidance is required';
    if (value.length < 20) return 'Product description name must be at least 20 characters';
    return null;
  }

  String? validateSellingPrice(String? value) {
    if (value == null || value.isEmpty) return 'Selling price is required';
    if (double.tryParse(value) == null) return 'Please enter a valid price';
    if (double.parse(value) <= 0) return 'Selling price must be greater than 0';
    if (mrpController.text.isNotEmpty) {
      double mrp = double.tryParse(mrpController.text) ?? 0;
      double sellingPrice = double.parse(value);
      if (sellingPrice > mrp) return 'Selling price cannot be greater than MRP';
    }
    return null;
  }

  String? validateAvailableStock(String? value) {
    if (value == null || value.isEmpty) return 'Available stock is required';
    if (int.tryParse(value) == null) return 'Please enter a valid number';
    if (int.parse(value) < 0) return 'Stock cannot be negative';
    return null;
  }
   // Validation Methods
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length < 2) {
      return 'Title must be at least 2 characters';
    }
    return null;
  }

  String? validateVariant(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Variant is required';
    }
    if (value.trim().length < 2) {
      return 'Variant must be at least 2 characters';
    }
    return null;
  }

  // Cancel Action
  void cancel() {
    Get.back();
  }

  // Clear Form
  void clearForm() {
    titleController.clear();
    variantController.clear();
  }

  // Step-wise validation
  bool _validateStep1() {
    if(imageLocalPaths.length < 2  || imageLocalPaths.length > 5) {
      _showError((imageLocalPaths.length < 2) ? 'Please take minimum two product images' : 'You can\'t add more than five images');
      return false;
    }

    if(!formKeyStep1.currentState!.validate()) return false;

     if(selectedBreadcrumb.value == null){
      _showError('Please select a category');
      return false;
    }

     if(tags.isEmpty){
      _showError('Please add a tag/keyword');
      return false;
    }


    //
    // final nameErr = validateProductName(productNameController.text);
    // if (nameErr != null) { _showError(nameErr); return false; }
    //
    // // Validate that at least level-0 is selected
    // if (categoryLevels.isEmpty || categoryLevels.first.selectedName.isEmpty) {
    //   _showError('Please select a category');
    //   return false;
    // }
    //
    // final brandErr = validateBrand(brandController.text);
    // if (brandErr != null) { _showError(brandErr); return false; }
    //
    // final mrpErr = validateMRP(mrpController.text);
    // if (mrpErr != null) { _showError(mrpErr); return false; }
    //
    // final spErr = validateSellingPrice(sellingPriceController.text);
    // if (spErr != null) { _showError(spErr); return false; }
    //
    // final stockErr = validateAvailableStock(availableStockController.text);
    // if (stockErr != null) { _showError(stockErr); return false; }

    return true;
  }

  bool _validateStep2() {
    if(!formKeyStep2.currentState!.validate()) return false;
    return true;
  }

  bool _validateStep3() {
    if(!formKeyStep3.currentState!.validate()) return false;
    return true;
  }

  bool validateCurrentStep() {
    switch (currentStep.value) {
      case 1: return _validateStep1();
      case 2: return _validateStep2();
      case 3: return _validateStep3();
      default: return true;
    }
  }

  void onNext() async {
    if (!validateCurrentStep()) return;
    if (currentStep.value < totalSteps){
      if(currentStep.value == 1){
        createProductApi();
      }else if(currentStep.value == 2){
        updateProductFeatureApi();
      } else if(currentStep.value == 3){
        updatePriceAndWarrantyApi();
      }
    }else{
      commonSnackBar(message: 'Product add successfully');
      Get.back();
      // await submitFinal();
    }

    // if (currentStep.value < totalSteps) {
    //   currentStep.value += 1;
    // } else {
    //   await submitFinal();
    // }
  }

  void onBack() { if (currentStep.value > 1) currentStep.value -= 1; }

  Future<void> submitFinal() async {
    // if (!_validateStep1() || !_validateStep2() || !_validateStep3()) return;
    isLoading.value = true;
    try {
      // Resolve final category id: prefer deepest selected level
      String categoryId = selectedCategoryId.value;
      if (categoryLevels.isNotEmpty) {
        final last = categoryLevels.last;
        if (last.selectedId.isNotEmpty) categoryId = last.selectedId;
      }

      // Build params map for multipart; omit empty/null values
      final params = <String, dynamic>{
        // Step 1 (top to bottom)
        'name': productNameController.text.trim(),
        'sku': skuController.text.trim(),
        'category_id': categoryId,
        'category_folder': '',
        'brand': brandController.text.trim(),
        'mrp_per_unit': mrpController.text.trim(),
        'our_price': sellingPriceController.text.trim(),
        'in_stock': availableStockController.text.trim(),
        'expiry_time[Date]': selectedDay.value == 0 ? null : selectedDay.value,
        'expiry_time[month]': selectedMonth.value == 0 ? null : selectedMonth.value,
        'expiry_time[year]': selectedYear.value == 0 ? null : selectedYear.value,
        'tags': tagsController.text.trim(),

        // Step 2
        'media': <dio.MultipartFile>[],
        'description': shortDescriptionController.text.trim(),
        'is_returnable': !isNonReturnable.value,
        'productWarrenty': warrantyController.text.trim(),
        'video_url': videoPublicUrl.value,

        // Step 3
        'addProductFeatures': jsonEncode(buildFeaturesPayload()),
        'options': jsonEncode(buildOptionsPayload()),
        'linkOrReferealWebsite': linkController.text.trim(),
        'addMoreDetails': '[{"title":"Material","details":"100% Genuine Leather"}]',

        // Meta
        'type': 'Product',
        'is_published': true,
      };
      params.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

      final response = await ListingFormRepo().addProduct(params);
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        Get.snackbar(
          'Success',
          'Product submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // TODO: Navigate to success/details screen
      } else {
        _showError('Submit failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Submit error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String msg) {
    commonSnackBar(message: msg);

    // Get.snackbar('Validation', msg,
    //   snackPosition: SnackPosition.BOTTOM,
    //   backgroundColor: Colors.red,
    //   colorText: Colors.white,
    // );
  }


  // Features management
  void addFeature() {
    featureControllers.add(TextEditingController());
  }

  void removeFeature(int index) {
    if (index >= 0 && index < featureControllers.length) {
      final ctrl = featureControllers.removeAt(index);
      ctrl.dispose();
    }
  }

  List<Map<String, String>> buildFeaturesPayload() {
    final List<Map<String, String>> list = [];
    for (int i = 0; i < featureControllers.length; i++) {
      final details = featureControllers[i].text.trim();
      if (details.isNotEmpty) {
        list.add({
          'title': 'Feature ${i + 1}',
          'details': details,
        });
      }
    }
    return list;
  }

  // Options management
  void addOption() {
    optionAttributeControllers.add(TextEditingController());
    optionValueControllers.add(TextEditingController());
  }

  void removeOption(int index) {
    if (index >= 0 && index < optionAttributeControllers.length &&
        index < optionValueControllers.length) {
      final a = optionAttributeControllers.removeAt(index);
      final v = optionValueControllers.removeAt(index);
      a.dispose();
      v.dispose();
    }
  }

  List<Map<String, String>> buildOptionsPayload() {
    final List<Map<String, String>> list = [];
    final len = optionAttributeControllers.length;
    for (int i = 0; i < len; i++) {
      final attr = optionAttributeControllers[i].text.trim();
      final val = optionValueControllers[i].text.trim();
      if (attr.isNotEmpty && val.isNotEmpty) {
        list.add({'attribute': attr, 'value': val});
      }
    }
    return list;
  }

  // Form Submission (restored)
  Future<void> saveAsDraft() async {
    isLoading.value = true;
    try {
      // TODO: Wire to actual draft persistence when available
      Get.snackbar(
        'Draft Saved',
        'Your draft has been saved (mock).',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Initialize and upload video to S3 using presigned URL
  Future<bool> uploadVideoFromPath({
    required String filePath,
    required String fileType, // e.g., "video/mp4"
  }) async {
    try {
      isLoading.value = true;
      // Derive a safe fileName (without extension)
      String base = filePath.replaceAll('\\\\', '/').split('/').last;
      if (base.contains('.')) base = base.substring(0, base.lastIndexOf('.'));
      String safeName = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      if (safeName.isEmpty) safeName = 'profile-video';

      final initRes = await ListingFormRepo().initMediaUpload(
        fileName: safeName,
        fileType: Uri.encodeComponent(fileType),
      );
      if (initRes.statusCode != 200 || initRes.response?.data == null) {
        _showError('Init upload failed: ${initRes.statusCode}');
        return false;
      }

      final data = initRes.response!.data as Map;
      final String uploadUrl = data['uploadUrl'] ?? '';
      final String publicUrl = data['publicUrl'] ?? '';
      final String fileKey = data['fileKey'] ?? '';
      if (uploadUrl.isEmpty || publicUrl.isEmpty) {
        _showError('Invalid init upload response');
        return false;
      }

      final file = io.File(filePath);
      if (!await file.exists()) {
        _showError('Selected video file not found');
        return false;
      }
      final bytes = await file.readAsBytes();

      final client = dio.Dio();
      final putResp = await client.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: dio.Options(
          headers: {
            'Content-Type': fileType,
            'Content-Length': bytes.length,
          },
          responseType: dio.ResponseType.plain,
        ),
      );

      if (putResp.statusCode != null && putResp.statusCode! >= 200 && putResp.statusCode! < 300) {
        videoPublicUrl.value = publicUrl;
        videoFileKey.value = fileKey;
        return true;
      } else {
        _showError('Video upload failed: ${putResp.statusCode}');
        return false;
      }
    } catch (e) {
      _showError('Video upload error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Media pickers
  Future<void> pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        videoLocalPath.value = file.path;
      }
    } catch (e) {
      _showError('Video pick failed: $e');
    }
  }

  Future<void> pickImages(BuildContext context) async {
    try {

      final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
        context,
        'Product Image',
      );

      if (selected != null) {
        if (selected.isEmpty) return;
        final remaining = 5 - imageLocalPaths.length;
        if (remaining <= 0) return;
        final addList = selected.take(remaining).map((i) => i).toList();
        imageLocalPaths.addAll(addList);
      }


    } catch (e) {
      _showError('Image pick failed: $e');
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < imageLocalPaths.length) {
      imageLocalPaths.removeAt(index);
    }
  }


  Future<void> loadCategories({String? parentId, bool fromCache = true}) async {
    if (fromCache && _cache.containsKey(parentId)) {
      categories.assignAll(_cache[parentId]!);
      return;
    }

    loading.value = true;
    try {
      Map<String, dynamic> params = {};

      if(parentId!=null){
        params = {
          ApiKeys.id: parentId
        };
      }

      final responseModel = await ListingFormRepo().getSubchildORRootCategroy(queryParams: params);
      if (responseModel.isSuccess) {
        getSubChildORRootCategroyResponse.value = ApiResponse.complete(responseModel);
        final subChildORRootCategoryResponse = SubChildORRootCategoryResponse.fromJson(responseModel.response!.data);
        List<CategoryData> categoryData = subChildORRootCategoryResponse.data??[];

        categories.assignAll(categoryData);

        // Save in cache
        _cache[parentId] = categoryData;
      } else {
        getSubChildORRootCategroyResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getSubChildORRootCategroyResponse.value = ApiResponse.error('error');
    } finally {
      loading.value = false;
    }
  }

  void selectCategory(CategoryData cat) {
    breadcrumb.add(cat);
    loadCategories(parentId: cat.sId??'');
  }

  void goToBreadcrumb(int index) {
    breadcrumb.removeRange(index + 1, breadcrumb.length);
    final parentId = breadcrumb.isNotEmpty ? breadcrumb.last.sId : null;
    loadCategories(parentId: parentId);
  }

  void reset() {
    breadcrumb.clear();
    loadCategories(parentId: null);
  }

  Future<void> openCategoryBottomSheet(BuildContext context) async {
    if(selectedBreadcrumb.value == null){
      selectedBreadcrumb.value = await showCategoryBottomSheet(context);

      if (selectedBreadcrumb.value != null) {
        print("User selected: $selectedBreadcrumb");
      } else {
        print("User closed without selecting");
      }
    }
  }

  void addTag() {
    if(tags.length == 10){
      commonSnackBar(message: 'You can\'t add more than 10 tags/Keywords');
      return;
    }

    final text = tagsController.text.trim();
    if (text.isNotEmpty) {
      tags.add(text);
      tagsController.clear();
    }
  }

  void removeTag(String tag) {
    tags.remove(tag);
  }

  void addMaterial() {
    if(materials.length == 5){
      commonSnackBar(message: 'You can\'t add more than 5 materials');
      return;
    }

    final text = materialController.text.trim();
    if (text.isNotEmpty) {
      materials.add(text);
      materialController.clear();
    }
  }

  void removeMaterial(String tag) {
    materials.remove(tag);
  }

  // Reset value when duration type changes
  void onProductDurationChanged(String newDuration) {
    selectedProductDuration.value = newDuration;
    selectedProductValue.value = 1; // Reset to 1 when duration changes
  }

  void onProductValueChanged(num newValue) {
    selectedProductValue.value = newValue;
  }

  // Reset value when duration type changes
  void onDurationChanged(String newDuration) {
    selectedExpiryDuration.value = newDuration;
    selectedExpiryValue.value = 1; // Reset to 1 when duration changes
  }

  void onValueChanged(num newValue) {
    log('selected value-- $newValue');
    selectedExpiryValue.value = newValue;

  }

  void addColor(Color color, String name) {
    if (selectedColors.length == 5) {
      commonSnackBar(message: 'You can\'t add more than 5 colors');
      return;
    }

    if (!selectedColors.any((c) => c.color == color)) {
      selectedColors.add(SelectedColor(color, name));
    }
  }

  void removeColor(SelectedColor selectedColor) {
    selectedColors.remove(selectedColor);
  }

  void addDetail(DetailItem detail) {
    detailsList.add(detail);
  }

  void removeDetail(int index) {
    detailsList.removeAt(index);
  }

  void updateVariantName(String oldKey, String newKey) {
    if (oldKey == newKey || newKey.trim().isEmpty) return;

    // Keep the value
    final value = variantSizes[oldKey] ?? '';

    // Rebuild variantSizes map with the new key at the same position
    final newMap = <String, String>{};
    variantSizes.forEach((key, val) {
      if (key == oldKey) {
        newMap[newKey] = value; // insert new key
      } else {
        newMap[key] = val;
      }
    });
    variantSizes.value = newMap;

    // Update the text in the existing controller
    final controller = variantNameControllers[oldKey];
    if (controller != null) {
      controller.text = newKey;
      variantNameControllers.remove(oldKey);
      variantNameControllers[newKey] = controller;
    }

    // Preserve editing state
    final editing = isEditingMap[oldKey] ?? false;
    isEditingMap.remove(oldKey);
    isEditingMap[newKey] = editing;

    // Refresh
    variantSizes.refresh();
    isEditingMap.refresh();
  }

  void toggleEditing(String key) {
    isEditingMap[key] = !(isEditingMap[key] ?? false);
    isEditingMap.refresh();
  }

  void updateVariantSize(String variant, String size) {
    variantSizes[variant] = size;
  }


  Future<void> createProductApi() async {

    // loading.value = true;
    try {
      Map<String, dynamic> params = {
        ApiKeys.name: productNameController.text.trim(),
        ApiKeys.categoryId: selectedBreadcrumb.value?.last.sId??'',
        ApiKeys.tags: tags
      };

      if(brandController.text.trim().isNotEmpty){
        params[ApiKeys.brand] = brandController.text.trim();
      }

      List<dio.MultipartFile> imageByPart = [];

      for (final path in imageLocalPaths) {
        final fileName = path.split('/').last;
        imageByPart.add(await dio.MultipartFile.fromFile(path, filename: fileName));
      }
      params[ApiKeys.media] = imageByPart;


      final responseModel = await ListingFormRepo().createProductApi(params: params);
      commonSnackBar(message: responseModel.message);
      if (responseModel.isSuccess) {
        createProductResponse.value = ApiResponse.complete(responseModel);
        final createProductModel = CreateProductModel.fromJson(responseModel.response!.data);
        productId = createProductModel.data?.sId;
        currentStep.value += 1;
      } else {
        createProductResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      createProductResponse.value = ApiResponse.error('error');
      commonSnackBar(message: 'something went wrong.');
    } finally {
      // loading.value = false;
    }
  }

  Future<void> updateProductFeatureApi() async {

    // loading.value = true;
    try {
      Map<String, dynamic> params = {
      ApiKeys.addProductFeatures: featureControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => {ApiKeys.title: c.text.trim()})
          .toList(),
      };

      if(detailsList.isNotEmpty) params[ApiKeys.addMoreDetails] = detailsList.map((e) => e.toJson()).toList();
      if(linkController.text.trim().isNotEmpty) params[ApiKeys.linkOrReferealWebsite] = {ApiKeys.title: linkController.text.trim()};


      final responseModel = await ListingFormRepo().updateProductFeatureApi(params: params, productId: productId??'');
      // commonSnackBar(message: responseModel.message);
      if (responseModel.isSuccess) {
        updateProductFeatureResponse.value = ApiResponse.complete(responseModel);
        currentStep.value += 1;
      } else {
        updateProductFeatureResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print('stack -- $s');
      updateProductFeatureResponse.value = ApiResponse.error('error');
      commonSnackBar(message: 'something went wrong.');
    } finally {
      // loading.value = false;
    }
  }

  Future<void> updatePriceAndWarrantyApi() async {

    // loading.value = true;
    try {
      Map<String, dynamic> params = {
        ApiKeys.mrpPerUnit: mrpController.text.trim(),
        // ApiKeys.productWarranty: productWarrantyTime,
        ApiKeys.expiryTime: productWarrantyTime,
        ApiKeys.expiryTime: expiryTime,
        ApiKeys.description: guidelineController.text.trim()
      };

      final responseModel = await ListingFormRepo().updatePriceAndWarrantyApi(params: params, productId: productId??'');
      // commonSnackBar(message: responseModel.message);
      if (responseModel.isSuccess) {
        updatePriceAndWarrantyResponse.value = ApiResponse.complete(responseModel);
        currentStep.value += 1;
      } else {
        updatePriceAndWarrantyResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      updatePriceAndWarrantyResponse.value = ApiResponse.error('error');
      commonSnackBar(message: 'something went wrong.');
    } finally {
      // loading.value = false;
    }
  }

}