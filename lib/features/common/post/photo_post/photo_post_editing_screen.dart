import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/post/photo_post/single_photo_post_editing_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPostEditingScreen extends StatefulWidget {
  List<String> images;

  PhotoPostEditingScreen({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  State<PhotoPostEditingScreen> createState() => _PhotoPostEditingScreenState();
}

class _PhotoPostEditingScreenState extends State<PhotoPostEditingScreen> {
  int _selectedFilterIndex = 0;
  String _selectedAspect = 'Portrait';
  int maxPhotos = 5;

  // Sample filter data
  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'color': Colors.transparent},

    // Classic
    {'name': 'B&W', 'color': Colors.grey},
    {'name': 'Sepia', 'color': const Color(0xFF704214)}, // warm brown
    {'name': 'Vintage', 'color': Colors.brown},

    // Warm tones
    {'name': 'Warm', 'color': Colors.orange},
    {'name': 'Sunset', 'color': Colors.deepOrangeAccent},
    {'name': 'Golden', 'color': Colors.amber},

    // Cool tones
    {'name': 'Cool', 'color': Colors.blue},
    {'name': 'Ocean', 'color': Colors.teal},
    {'name': 'Frost', 'color': Colors.cyanAccent},

    // Bright & vibrant
    {'name': 'Bright', 'color': Colors.yellow},
    {'name': 'Neon', 'color': Colors.pinkAccent},
    {'name': 'Lively', 'color': Colors.greenAccent},

    // Moody
    {'name': 'Dark', 'color': Colors.black54},
    {'name': 'Matte', 'color': const Color(0xFF2E2E2E)},
    {'name': 'Drama', 'color': Colors.indigo},

    // Artistic
    {'name': 'Pastel', 'color': Colors.purpleAccent},
    {'name': 'Dreamy', 'color': Colors.lightBlueAccent},
    {'name': 'Cinematic', 'color': Colors.deepPurple},
  ];


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: 'Edit Photo'
      ),
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
                // Image Carousel Section
                _buildImageCarousel(),

                // Add More Button
                if (widget.images.isNotEmpty &&
                    widget.images.length < maxPhotos)
                _buildAddMoreButton()
                else
                  SizedBox(
                    height: SizeConfig.size25,
                  ),

                // Filter Thumbnails
                _buildFilterThumbnails(),

                // Action Buttons
                // _buildActionButtons(),

                SizedBox(height: SizeConfig.size10),

                // Continue Button
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

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: widget.images.length,
          options: CarouselOptions(
            viewportFraction: viewportFraction,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            aspectRatio: 1.1
          ),
          itemBuilder: (context, index, realIdx) {
            final double aspectRatio = _selectedAspect == 'Square' ? 1.0 : 3/4; // 1:1 or 3:4


            return Center(
              child: Stack(
                children: [
                  InkWell(
                    onTap:() async {
                      String? editedImages = await Get.to(()=> SinglePhotoPostEditingScreen(photo: File(widget.images[index])));
                      if(editedImages!=null) {
                        setState(() {
                          widget.images[index] = editedImages;
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppColors.whiteFE,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppColors.mainTextColor.withValues(alpha: 0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 2.0,
                                offset: Offset(0, 1),
                                color: Color(0x14000000)
                            )
                          ]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(_filters[_selectedFilterIndex]['color'], BlendMode.overlay),
                          child: Image.file(
                            File(widget.images[index]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Close button --------------------------
                  Positioned(
                    top: 12,
                    right: 12,
                    child: InkWell(
                      onTap: (){
                        widget.images.removeAt(index);
                        if(widget.images.length == 0){
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
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),

                  // --- Crop button ---------------------------
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: _photoPhotoPopUpMenu(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              // Handle add more images
              HapticFeedback.lightImpact();
              addPhotos();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.blue[600],
                  size: 18,
                ),
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
              padding:  const EdgeInsets.only(right: 12),
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
                      // margin: const EdgeInsets.only(right: 12),
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
                              File(widget.images[0]), // Use first image for preview
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


  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size30, horizontal: SizeConfig.size15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.auto_awesome_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              // Handle enhance
            },
          ),
          SizedBox(width: SizeConfig.size10),
          _buildActionButton(
            icon: Icons.music_note_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              // Handle music
            },
          ),
          SizedBox(width: SizeConfig.size10),
          _buildActionButton(
            icon: Icons.file_download_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              // Handle download
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: SizeConfig.size40,
          decoration: BoxDecoration(
            color: AppColors.whiteFE,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: AppColors.greyE5, width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 2.0,
                offset: Offset(0, 1),
                color: Color(0x14000000)
              )
            ]
          ),
          child: Icon(
            icon,
            color: Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
      child: PositiveCustomBtn(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, widget.images);
          },
          title: "Continue"),
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
          _selectedAspect = value; // update carousel viewportFraction
        });
      },
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.mainTextColor.withValues(alpha: 0.8),
          shape: BoxShape.circle
        ),
        alignment: Alignment.center,
        child: const Icon(
            Icons.crop,
            color: Colors.white,
            size: 18
        ),
      ),
      itemBuilder: (context) => photoPostMenuItems(),
    );
  }

  void addPhotos() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? images = await _picker.pickMultiImage();

    if (images == null || images.isEmpty) return;

    int totalImage = widget.images.length + images.length;
    // print('total images')
    if (totalImage > maxPhotos) {
      commonSnackBar(
        message: 'You can only upload up to $maxPhotos photos',
      );

      return;
    }

    for (final image in images) {

      final compressedFile = await SelectProfilePictureDialog.compressImage(File(image.path));

      if (compressedFile != null) widget.images.add(compressedFile.path);

    }

    setState(() {});
  }

}
