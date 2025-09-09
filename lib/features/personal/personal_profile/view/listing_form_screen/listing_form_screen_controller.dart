import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_more_details_screen/add_more_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/repo/listing_form_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/model/category_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/model/subcategory_response.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:io' as io;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

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

class ManualListingScreenController extends GetxController {
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
  final TextEditingController microsizeController = TextEditingController();
  final TextEditingController smallsizeController = TextEditingController();
  final TextEditingController mediumsizeController = TextEditingController();
  final TextEditingController largesizeController = TextEditingController();
  final TextEditingController extralargesizeController = TextEditingController();
  
  // Product validity (duration) controls
  final TextEditingController validityValueController = TextEditingController();
  final RxString validityUnit = 'Day'.obs; // Day, Week, Month, Year
  final List<String> validityUnits = const ['Day', 'Week', 'Month', 'Year'];

  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController variantController = TextEditingController();
  
  // Media state
  final RxString videoPublicUrl = ''.obs;
  final RxString videoFileKey = ''.obs;
  final Rxn<String> videoLocalPath = Rxn<String>(); // picked local video file path
  final RxList<String> imageLocalPaths = <String>[].obs; // up to 4

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

  // Source for level-0
  final RxList<TopLevelCategory> topLevelCategories = <TopLevelCategory>[].obs;

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

  // Character count tracking for features
  final RxList<RxInt> featureCharCounts = <RxInt>[
    0.obs,
    0.obs,
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
  final RxBool isCreated = false.obs;
  // Separated custom details for Step 1 and Step 3
  final RxList<Map<String, String>> moreDetailsStep1 = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> moreDetailsStep3 = <Map<String, String>>[].obs;

  // Color selection state
  final Rx<Color> selectedColor = AppColors.primaryColor.obs;
  final RxString selectedColorHex = ''.obs;
  final RxString selectedColorName = ''.obs;

  // Multiple selected colors
  final RxList<SelectedColorInfo> selectedColors = <SelectedColorInfo>[].obs;

  // Tags list to maintain added tags
  final RxList<String> addedTags = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    getTopLevelCategoriesList();
    // Set up listeners for existing feature controllers
    for (int i = 0; i < featureControllers.length; i++) {
      _setupFeatureListener(i);
    }
  }

  void _setupFeatureListener(int index) {
    featureControllers[index].addListener(() {
      featureCharCounts[index].value = featureControllers[index].text.length;
    });
  }

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
    microsizeController.dispose();
    smallsizeController.dispose();
    mediumsizeController.dispose();
    largesizeController.dispose();
    extralargesizeController.dispose();
    validityValueController.dispose();
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

  Future<void> toggleMoreDetails() async {
    showMoreDetails.value = !showMoreDetails.value;
    final result = await Get.dialog(
      const AddMoreDetailsDialog(),
      barrierDismissible: false,
    );
    _addMoreDetailFromResultToList(result, moreDetailsStep1);
  }
  Future<void> openMoreDetailsForStep2() async {
    final result = await Get.dialog(
      const AddMoreDetailsDialogStep2(),
      barrierDismissible: false,
    );
    // _addMoreDetailFromResultToList(result, moreDetailsStep2);
  }

  Future<void> openMoreDetailsForStep3() async {
    final result = await Get.dialog(
      const AddMoreDetailsDialogStep3(),
      barrierDismissible: false,
    );
    _addMoreDetailFromResultToList(result, moreDetailsStep3);
  }

  // Add Tag
  void addTag() {
    if (tagsController.text.isNotEmpty) {
      final tagText = tagsController.text.trim();
      // Check if tag already exists to avoid duplicates
      if (!addedTags.contains(tagText)) {
        addedTags.add(tagText);
        // Get.snackbar(
        //   'Tag Added',
        //   'Tag "$tagText" added successfully',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        // );
      } else {
        Get.snackbar(
          'Duplicate Tag',
          'Tag "$tagText" already exists',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      tagsController.clear();
    }
  }

  void removeTag(int index) {
    if (index >= 0 && index < addedTags.length) {
      addedTags.removeAt(index);
    }
  }

  // Mark product as created (controls bottom bar visibility)
  Future<void> markCreated() async {
    if (!isCreated.value) {
      isCreated.value = true;
       if (currentStep.value < totalSteps) {
      currentStep.value += 1;
    } else {
      await submitFinal();
    }
      // Get.snackbar(
      //   'Product',
      //   'Product is created',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      // );
    }
  }

  // Validation Methods
  String? validateProductName(String? value) {
    if (value == null || value.isEmpty) return 'Product name is required';
    if (value.length < 3) return 'Product name must be at least 3 characters';
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.isEmpty) return 'Category is required';
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
  
  String? validateValidityValue(String? value) {
    if (value == null || value.isEmpty) return 'Validity duration is required';
    final n = int.tryParse(value);
    if (n == null) return 'Please enter a valid number';
    if (n <= 0) return 'Duration must be greater than 0';
    return null;
  }

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
    final nameErr = validateProductName(productNameController.text);
    if (nameErr != null) { _showError(nameErr); return false; }

    // Validate that at least level-0 is selected
    if (categoryLevels.isEmpty || categoryLevels.first.selectedName.isEmpty) {
      _showError('Please select a category');
      return false;
    }

    final brandErr = validateBrand(brandController.text);
    if (brandErr != null) { _showError(brandErr); return false; }

    final mrpErr = validateMRP(mrpController.text);
    if (mrpErr != null) { _showError(mrpErr); return false; }

    final spErr = validateSellingPrice(sellingPriceController.text);
    if (spErr != null) { _showError(spErr); return false; }

    final stockErr = validateAvailableStock(availableStockController.text);
    if (stockErr != null) { _showError(stockErr); return false; }

    return true;
  }

  bool _validateStep2() { return true; }
  bool _validateStep3() { return true; }
  bool _validateStep4() { return true; }
  bool validateCurrentStep() {
    switch (currentStep.value) {
      case 1: return _validateStep1();
      case 2: return _validateStep2();
      case 3: return _validateStep3();
      case 4: return _validateStep4();
      default: return false;
    }
  }

  void onNext() async {
    // if (!validateCurrentStep()) return;
    if (currentStep.value < totalSteps) {
      currentStep.value += 1;
    } else {
      await submitFinal();
    }
  }

  void onBack() { if (currentStep.value > 1) currentStep.value -= 1; }

  Future<void> submitFinal() async {
    if (!_validateStep1() || !_validateStep2() || !_validateStep3() || !_validateStep4()) return;
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
        'tags': addedTags.join(', '),

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
        'addMoreDetails': jsonEncode([
          ...moreDetailsStep1,
          ...moreDetailsStep3,
        ]),
        'validity_duration': validityValueController.text.trim(),
        'validity_unit': validityUnit.value,

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
    Get.snackbar('Validation', msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Data loading
  Future<void> getTopLevelCategoriesList() async {
    try {
      isLoading.value = true;
      final response = await ListingFormRepo().getToplevelCategories();
      if (response.statusCode == 200) {
        final list = topLevelCategoryListFromJson(response.response!.data);
        topLevelCategories.value = list;
        _resetToLevel0();
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Convert top-level categories to CategoryNode for level-0 dropdown
  List<CategoryNode> _topAsNodes(List<TopLevelCategory> cats) =>
      cats.map((c) => CategoryNode(id: c.id, name: c.name, parent: null, subcategories: const []))
          .toList();

  void _resetToLevel0() {
    selectedCategory.value = '';
    selectedCategoryId.value = '';
    final level0 = CategoryLevel(items: _topAsNodes(topLevelCategories));
    categoryLevels.value = [level0];
  }

  // Centralized fetcher
  Future<List<CategoryNode>> _fetchChildren(String parentId) async {
    try {
      isLoading.value = true;
      final response = await ListingFormRepo().getSubcategories(parentId);
      if (response.statusCode == 200) {
        return childrenFromApi(response.response!.data);
      }
      print("Subcategories API failed with status: ${response.statusCode}");
      return <CategoryNode>[];
    } catch (e) {
      print("Error fetching subcategories: $e");
      return <CategoryNode>[];
    } finally {
      isLoading.value = false;
    }
  }

  // Handle change at any level i; create/remove deeper levels accordingly
  Future<void> onLevelChanged(int levelIndex, String? name) async {
    if (name == null || name.isEmpty) return;
    if (levelIndex < 0 || levelIndex >= categoryLevels.length) return;

    final level = categoryLevels[levelIndex];
    final node = level.items.firstWhereOrNull((e) => e.name == name);
    if (node == null) return;

    // Update selection for this level
    final updatedLevel = level.copyWith(selectedId: node.id, selectedName: node.name);
    final newLevels = categoryLevels.toList();
    newLevels[levelIndex] = updatedLevel;

    // Drop deeper levels
    if (newLevels.length > levelIndex + 1) {
      newLevels.removeRange(levelIndex + 1, newLevels.length);
    }

    // Fetch children for the selected node; if present, add a new level
    final children = await _fetchChildren(node.id);
    if (children.isNotEmpty) {
      newLevels.add(CategoryLevel(items: children));
      // Not a leaf yet
      selectedCategory.value = node.name; // optional preview
      selectedCategoryId.value = node.id;
    } else {
      // Leaf reached -> finalize
      selectedCategory.value = node.name;
      selectedCategoryId.value = node.id;
    }

    categoryLevels.value = newLevels;
  }

  // Features management
  void addFeature() {
    featureControllers.add(TextEditingController());
    featureCharCounts.add(0.obs);
    _setupFeatureListener(featureControllers.length - 1);
  }

  void removeFeature(int index) {
    if (index >= 0 && index < featureControllers.length) {
      final ctrl = featureControllers.removeAt(index);
      ctrl.dispose();
    }
    if (index >= 0 && index < featureCharCounts.length) {
      featureCharCounts.removeAt(index);
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

  Future<void> pickImages() async {
    try {
      // Allow multiple selection; cap total images to 5 (UI handles warnings/min checks)
      final remaining = 5 - imageLocalPaths.length;
      if (remaining <= 0) return; // already at max

      final List<XFile> files = await _picker.pickMultiImage();
      if (files.isEmpty) return;

      // Truncate to allowed remaining quota
      final addList = files.take(remaining).map((f) => f.path).toList();
      if (addList.isEmpty) return;
      imageLocalPaths.addAll(addList);
    } catch (e) {
      _showError('Image pick failed: $e');
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < imageLocalPaths.length) {
      imageLocalPaths.removeAt(index);
    }
  }

  // Update color selection and derive name and hex
  void updateSelectedColor(Color color) {
    selectedColor.value = color;
    selectedColorHex.value = ColorTools.colorCode(color);
    selectedColorName.value = ColorTools.nameThatColor(color);
  }

  // Add picked color to the list (avoids duplicates by hex code)
  void addOrUpdateSelectedColor(Color color) {
    updateSelectedColor(color);
    final hex = ColorTools.colorCode(color);
    final name = ColorTools.nameThatColor(color);
    final exists = selectedColors.indexWhere((e) => e.hex == hex);
    if (exists == -1) {
      selectedColors.add(SelectedColorInfo(color: color, name: name, hex: hex));
    } else {
      // Update existing entry in case name differs
      selectedColors[exists] = SelectedColorInfo(color: color, name: name, hex: hex);
    }
  }

  void removeSelectedColorAt(int index) {
    if (index >= 0 && index < selectedColors.length) {
      selectedColors.removeAt(index);
    }
  }

  void onValidityUnitChanged(String? unit) {
    if (unit == null) return;
    validityUnit.value = unit;
  }

  void _addMoreDetailFromResultToList(dynamic result, RxList<Map<String, String>> target) {
    if (result is Map) {
      final title = (result['title'] ?? '').toString().trim();
      final variant = (result['variant'] ?? '').toString().trim();
      if (title.isNotEmpty && variant.isNotEmpty) {
        target.add({'title': title, 'details': variant});
      }
    }
  }

  void removeMoreDetailAtStep1(int index) {
    if (index >= 0 && index < moreDetailsStep1.length) {
      moreDetailsStep1.removeAt(index);
    }
  }

  void removeMoreDetailAtStep3(int index) {
    if (index >= 0 && index < moreDetailsStep3.length) {
      moreDetailsStep3.removeAt(index);
    }
  }
}

class SelectedColorInfo {
  final Color color;
  final String name;
  final String hex; // e.g. #FF5722

  const SelectedColorInfo({required this.color, required this.name, required this.hex});
}