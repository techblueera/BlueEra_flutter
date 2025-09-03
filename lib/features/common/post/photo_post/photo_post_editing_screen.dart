import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhotoPostEditingScreen extends StatefulWidget {
  final List<String> images;

  const PhotoPostEditingScreen({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  State<PhotoPostEditingScreen> createState() => _PhotoPostEditingScreenState();
}

class _PhotoPostEditingScreenState extends State<PhotoPostEditingScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  int _selectedFilterIndex = 0;

  // Sample filter data
  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'color': null},
    {'name': 'B&W', 'color': Colors.grey},
    {'name': 'Warm', 'color': Colors.orange},
    {'name': 'Cool', 'color': Colors.blue},
    {'name': 'Vintage', 'color': Colors.brown},
    {'name': 'Bright', 'color': Colors.yellow},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            top: SizeConfig.size16,
            bottom: kToolbarHeight,
          ),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Image Carousel Section
                _buildImageCarousel(),

                // Add More Button
                _buildAddMoreButton(),

                // Filter Thumbnails
                _buildFilterThumbnails(),

                // Action Buttons
                _buildActionButtons(),

                const SizedBox(height: 20),

                // Continue Button
                _buildContinueButton(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: MediaQuery.of(context).padding.top,
      color: Colors.white,
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF007AFF),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Edit Photo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '9:41',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const Icon(Icons.signal_cellular_4_bar, size: 18),
          const SizedBox(width: 4),
          const Icon(Icons.wifi, size: 18),
          const SizedBox(width: 4),
          const Icon(Icons.battery_full, size: 24),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return AspectRatio(
      aspectRatio: 1 / 1.2,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          const pageFactor = 0.8;
          final itemWidth = viewportWidth * pageFactor;
          const itemPadding = 8.0;

          return Stack(
            children: [
              // --- bounded carousel ---------------------------------------
              Positioned.fill(               // <-- fills the Stack’s size
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _pageController,
                  itemCount: widget.images.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding:
                      EdgeInsets.only(left: index == 0 ? 0 : itemPadding),
                      child: SizedBox(
                        width: itemWidth,
                        child: _buildImageItem(widget.images[index]),
                      ),
                    );
                  },
                ),
              ),

              // --- Close button -------------------------------------------
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),

              // --- Crop button --------------------------------------------
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.crop_free, color: Colors.white, size: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageItem(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            // loadingBuilder: (context, child, loadingProgress) {
            //   if (loadingProgress == null) return child;
            //   return Container(
            //     color: Colors.grey[200],
            //     child: Center(
            //       child: CircularProgressIndicator(
            //         value: loadingProgress.expectedTotalBytes != null
            //             ? loadingProgress.cumulativeBytesLoaded /
            //             loadingProgress.expectedTotalBytes!
            //             : null,
            //         color: const Color(0xFF007AFF),
            //       ),
            //     ),
            //   );
            // },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              );
            },
          ),

          // Apply selected filter
          if (_selectedFilterIndex > 0)
            Container(
              decoration: BoxDecoration(
                color: _filters[_selectedFilterIndex]['color']?.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Handle add more images
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add more images functionality'),
                  duration: Duration(seconds: 1),
                ),
              );
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
      height: 80,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 12),
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
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.auto_fix_high,
            onTap: () {
              HapticFeedback.lightImpact();
              // Handle enhance
            },
          ),
          _buildActionButton(
            icon: Icons.music_note,
            onTap: () {
              HapticFeedback.lightImpact();
              // Handle music
            },
          ),
          _buildActionButton(
            icon: Icons.download,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Icon(
          icon,
          color: Colors.black87,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return PositiveCustomBtn(
        onTap: () {
          HapticFeedback.lightImpact();
          // Handle continue
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Continue to next step'),
              backgroundColor: Color(0xFF007AFF),
            ),
          );
        },
        title: "Continue");

  }
}
