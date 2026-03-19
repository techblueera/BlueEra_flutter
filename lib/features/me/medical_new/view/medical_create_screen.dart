import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_level2_category_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Static 6 categories shown on the Create tab
const List<Map<String, String>> _staticMedicalCategories = [
  {
    'title': 'Ayurveda & Nutrition',
    'key': 'AYURVEDA___NUTRITION',
    'image': 'assets/category/medical/AyurvedaNutrition.png',
  },
  {
    'title': 'Home & Patient Care',
    'key': 'HOME___PATIENT_CARE',
    'image': 'assets/category/medical/Home_Patient_Care.png',
  },
  {
    'title': 'Medical Devices',
    'key': 'MEDICAL_DEVICES',
    'image': 'assets/category/medical/Medical_Devices.png',
  },
  {
    'title': 'OTC Medicines',
    'key': 'OTC_MEDICINES',
    'image': 'assets/category/medical/OTC_Medicines.png',
  },
  {
    'title': 'Personal & Baby Care',
    'key': 'PERSONAL___BABY_CARE',
    'image': 'assets/category/medical/Personal_Baby_Care.png',
  },
  {
    'title': 'Wound Care & First Aid',
    'key': 'WOUND_CARE___FIRST_AID',
    'image': 'assets/category/medical/Wound_Care_First_Aid.png',
  },
];

class MedicalCreateScreen extends StatefulWidget {
  const MedicalCreateScreen({super.key});

  @override
  State<MedicalCreateScreen> createState() => _MedicalCreateScreenState();
}

class _MedicalCreateScreenState extends State<MedicalCreateScreen> {
  final _medicalController = getOrPut(() => MedicalController());
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _medicalController.fetchGroceryNestedCategory();
  }

  Future<void> _pickAndSnapSearch({required ImageSource source}) async {
    try {
      final List<XFile> images;
      if (source == ImageSource.gallery) {
        images = await _picker.pickMultiImage(limit: 5);
      } else {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        images = photo != null ? [photo] : [];
      }
      if (images.isEmpty) return;
      await _medicalController.snapSearch(
        imagePaths: images.map((e) => e.path).toList(),
      );
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  /// Find matching API category by key for a static category
  MedicalNestedCategoryModel? _findApiCategory(String staticKey) {
    for (final level0 in _medicalController.medicalNestedCategoryList) {
      // Check level 0
      if (_keysMatch(level0.key, staticKey)) return level0;
      // Check level 1 children
      for (final level1 in (level0.children ?? <MedicalNestedCategoryModel>[])) {
        if (_keysMatch(level1.key, staticKey)) return level1;
      }
    }
    return null;
  }

  bool _keysMatch(String? apiKey, String staticKey) {
    if (apiKey == null) return false;
    return apiKey.toUpperCase().replaceAll(' ', '_') ==
        staticKey.toUpperCase().replaceAll(' ', '_');
  }

  void _onCategoryTap(Map<String, String> category) {
    final apiCategory = _findApiCategory(category['key']!);
    if (apiCategory == null) {
      commonSnackBar(message: 'Category not available yet',
       );
      return;
    }

    final level2Children = apiCategory.children ?? [];
    if (level2Children.isNotEmpty) {
      Get.to(() => MedicalLevel2CategoryScreen(
            title: category['title']!,
            level2Categories: level2Children,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: SizeConfig.size30),
        child: Column(
          children: [
            _buildBulkUploadSection(),
            _buildCategoryGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkUploadSection() {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "Bulk Upload Shop Product Photos",
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 10),
          Obx(() => _medicalController.isSnapSearchLoading.value
              ? SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Row(
                  children: [
                    _uploadMediaWidget(
                      imagePath:
                          'assets/category/medical/medical_upload_photo_med.png',
                      title: 'Upload Photo',
                      onTap: () =>
                          _pickAndSnapSearch(source: ImageSource.camera),
                    ),
                    SizedBox(width: 7),
                    _uploadMediaWidget(
                      imagePath:
                          'assets/category/medical/medical_upload_photo.png',
                      title: 'Upload List',
                      onTap: () =>
                          _pickAndSnapSearch(source: ImageSource.gallery),
                    ),
                  ],
                )),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _staticMedicalCategories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: SizeConfig.size6,
          mainAxisSpacing: SizeConfig.size6,
          childAspectRatio: 1.3,
        ),
        itemBuilder: (context, index) {
          return _buildCategoryCard(_staticMedicalCategories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category) {
    return InkWell(
      onTap: () => _onCategoryTap(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.whiteE5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  category['image']!,
                  fit: BoxFit.contain,
                  width: 60,
                  height: 60,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5),
              child: CustomText(
                category['title'],
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
                maxLines: 2,
                color: Colors.blueGrey.shade800,
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _uploadMediaWidget({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(imagePath, fit: BoxFit.contain),
              SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5),
                child: CustomText(
                  title,
                  fontSize: SizeConfig.small,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
