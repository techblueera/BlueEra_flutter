import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageGridView extends StatelessWidget {
  final List<String> images;
  final double imageHeight;
  final int maxVisible;
  final String appBarTitle;
  final void Function(BuildContext context, int index)? onTap;

  const ImageGridView({
    Key? key,
    required this.images,
    this.imageHeight = 85,
    required this.maxVisible,
    required this.appBarTitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasMoreImages = images.length > maxVisible;

    // One image → full width
    if (images.length == 1) {
      return _buildRoundedImage(context, imageUrl: images[0], index: 0, height: imageHeight, fullWidth: true);
    }

    // Three images → custom layout
    if (images.length == 3) {
      return Column(
        children: [
          _buildRoundedImage(context, imageUrl: images[0], index: 0, height: imageHeight, fullWidth: true),
          SizedBox(height: SizeConfig.size4),
          Row(
            children: [
              Expanded(
                child: _buildRoundedImage(context, imageUrl: images[1], index: 1, height: imageHeight),
              ),
              SizedBox(width: SizeConfig.size4),
              Expanded(
                child: _buildRoundedImage(context, imageUrl: images[2], index: 2, height: imageHeight),
              ),
            ],
          ),
        ],
      );
    }

    // Default grid layout
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      itemCount: hasMoreImages ? maxVisible : images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: SizeConfig.size4,
        crossAxisSpacing: SizeConfig.size4,
        mainAxisExtent: imageHeight, // 👈 ensures consistent height in grid
      ),
      itemBuilder: (context, index) {
        final isLast = index == maxVisible - 1 && hasMoreImages;

        return GestureDetector(
          onTap: () => onTap != null
              ? onTap!(context, index)
              : Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageViewScreen(
                appBarTitle: appBarTitle,
                imageUrls: images,
                initialIndex: index,
              ),
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: imageHeight,
                  placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              if (isLast)
                Container(
                  height: imageHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${images.length - maxVisible} Images',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoundedImage(BuildContext context,
      {required String imageUrl, required int index, required double height, bool fullWidth = false}) {
    return GestureDetector(
      onTap: () => onTap != null
          ? onTap!(context, index)
          : Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewScreen(
            appBarTitle: appBarTitle,
            imageUrls: images,
            initialIndex: index,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: fullWidth ? double.infinity : null,
          height: height,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}

