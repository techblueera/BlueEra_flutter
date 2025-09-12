import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/post/photo_post/single_photo_post_editing_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PhotoPostEditingScreen extends StatefulWidget {
  PhotoPostEditingScreen({Key? key}) : super(key: key);

  @override
  State<PhotoPostEditingScreen> createState() => _PhotoPostEditingScreenState();
}

class _PhotoPostEditingScreenState extends State<PhotoPostEditingScreen> {
  final PhotoPostController photoPostController = Get.find<PhotoPostController>();
  final CarouselSliderController _carouselController = CarouselSliderController();

  int _selectedFilterIndex = 0;
  String _selectedAspect = 'Portrait';
  int maxPhotos = 5;

  List<String> selectedPhotos = [];
  List<GlobalKey> _imageKeys = [];

  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'color': Colors.transparent},
    {'name': 'B&W', 'color': Colors.grey},
    {'name': 'Sepia', 'color': const Color(0xFF704214)},
    {'name': 'Vintage', 'color': Colors.brown},
    {'name': 'Warm', 'color': Colors.orange},
    {'name': 'Sunset', 'color': Colors.deepOrangeAccent},
    {'name': 'Golden', 'color': Colors.amber},
    {'name': 'Cool', 'color': Colors.blue},
    {'name': 'Ocean', 'color': Colors.teal},
    {'name': 'Frost', 'color': Colors.cyanAccent},
    {'name': 'Bright', 'color': Colors.yellow},
    {'name': 'Neon', 'color': Colors.pinkAccent},
    {'name': 'Lively', 'color': Colors.greenAccent},
    {'name': 'Dark', 'color': Colors.black54},
    {'name': 'Matte', 'color': const Color(0xFF2E2E2E)},
    {'name': 'Drama', 'color': Colors.indigo},
    {'name': 'Pastel', 'color': Colors.purpleAccent},
    {'name': 'Dreamy', 'color': Colors.lightBlueAccent},
    {'name': 'Cinematic', 'color': Colors.deepPurple},
  ];

  @override
  void initState() {
    selectedPhotos = List.from(photoPostController.selectedPhotos);
    _imageKeys = List.generate(selectedPhotos.length, (_) => GlobalKey());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: 'Edit Photo',
          isLeading: true,
          onBackTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, selectedPhotos);
          }),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: SizeConfig.size15,
            left: SizeConfig.size15,
            right: SizeConfig.size15,
            bottom: kToolbarHeight,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildImageCarousel(),
                if (selectedPhotos.isNotEmpty && selectedPhotos.length < maxPhotos)
                  _buildAddMoreButton()
                else
                  SizedBox(height: SizeConfig.size25),
                _buildFilterThumbnails(),
                SizedBox(height: SizeConfig.size10),
                _buildContinueButton(),
                SizedBox(height: SizeConfig.size10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final double viewportFraction = _selectedAspect == 'Square' ? 0.8 : 0.6;

    return CarouselSlider.builder(
      carouselController: _carouselController,
      itemCount: selectedPhotos.length,
      options: CarouselOptions(
        viewportFraction: viewportFraction,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        aspectRatio: 1.1,
      ),
      itemBuilder: (context, index, realIdx) {
        return Center(
          child: Stack(
            children: [
              InkWell(
                onTap: () async {
                  String? editedImage = await Get.to(() =>
                      SinglePhotoPostEditingScreen(photo: File(selectedPhotos[index]), isPortrait: _selectedAspect == 'Portrait'));
                  if (editedImage != null) {
                    setState(() {
                      selectedPhotos[index] = editedImage;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteFE,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                        color: AppColors.mainTextColor.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 2.0, offset: Offset(0, 1), color: Color(0x14000000))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child:
                    // (_selectedFilterIndex == 0) ?
                    // Image.file(
                    //   File(photoPostController.originalPhotos[index]),
                    //   fit: BoxFit.cover,
                    //   width: double.infinity,
                    // ) :
                    RepaintBoundary(
                      key: _imageKeys[index],
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          _filters[_selectedFilterIndex]['color'],
                          BlendMode.overlay,
                        ),
                        child: Image.file(
                          File(selectedPhotos[index]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () {
                    selectedPhotos.removeAt(index);
                    photoPostController.originalPhotos.removeAt(index);
                    _imageKeys.removeAt(index);
                    if (selectedPhotos.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.mainTextColor.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: _photoPhotoPopUpMenu(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              addPhotos();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.blue[600], size: 18),
                const SizedBox(width: 6),
                Text(
                  'Add More',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterThumbnails() {
    return Container(
      height: SizeConfig.size80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        padding: EdgeInsets.only(left: SizeConfig.size15, right: SizeConfig.size15),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      width: SizeConfig.size50,
                      height: SizeConfig.size50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF007AFF), width: 2)
                            : Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(selectedPhotos[0]),
                              fit: BoxFit.cover,
                            ),
                            if (index > 0)
                              Container(
                                color: _filters[index]['color']?.withOpacity(0.4),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Center(
                    child: Container(
                      width: SizeConfig.size50,
                      alignment: Alignment.center,
                      child: CustomText(
                        _filters[index]['name'],
                        fontSize: SizeConfig.small,
                        textAlign: TextAlign.center,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: PositiveCustomBtn(
        onTap: () async {
          HapticFeedback.lightImpact();
          final filteredFiles = await exportAllFilteredPhotos();
          Navigator.pop(context, filteredFiles.map((f) => f.path).toList());
        },
        title: "Continue",
      ),
    );
  }

  PopupMenuButton _photoPhotoPopUpMenu() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        setState(() {
          _selectedAspect = value;
        });
      },
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: AppColors.mainTextColor.withValues(alpha: 0.8),
            shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.crop, color: Colors.white, size: 18),
      ),
      itemBuilder: (context) => photoPostMenuItems(),
    );
  }

  void addPhotos() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images == null || images.isEmpty) return;

    int totalImage = selectedPhotos.length + images.length;
    if (totalImage > maxPhotos) {
      commonSnackBar(message: 'You can only upload up to $maxPhotos photos');
      return;
    }

    for (final image in images) {
      final compressedFile = await SelectProfilePictureDialog.compressImage(File(image.path));
      if (compressedFile != null) {
        selectedPhotos.add(compressedFile.path);
        photoPostController.originalPhotos.add(compressedFile.path);
        _imageKeys.add(GlobalKey());
      }
    }
    setState(() {});
  }

  Future<List<File>> exportAllFilteredPhotos() async {
    List<File> exported = [];
    log('image lengt--- ${_imageKeys.length}');

    for (int i = 0; i < _imageKeys.length; i++) {
      // Animate carousel to ensure RepaintBoundary is mounted
      _carouselController.animateToPage(i,
          duration: const Duration(milliseconds: 220), curve: Curves.easeInOut);

      await Future.delayed(const Duration(milliseconds: 300));
      final file = await _exportFilteredPhoto(_imageKeys[i], i);
      if (file != null) exported.add(file);
    }

    log('exported--- ${exported.length}');
    return exported;
  }

  Future<File?> _exportFilteredPhoto(GlobalKey key, int index) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      print('boundary--$boundary');
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file =
      File('${dir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}_$index.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      print("Error exporting image $index: $e");
      return null;
    }
  }
}
