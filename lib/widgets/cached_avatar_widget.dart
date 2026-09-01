import 'package:BlueEra/core/constants/image_decode_size.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double? borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final bool showProfileOnFullScreen;

  const CachedAvatarWidget(
      {super.key,
      required this.imageUrl,
      this.size = 40.0,
      this.borderRadius,
      this.borderColor,
      this.boxShadow,
      this.showProfileOnFullScreen = true,
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius ?? 5.0),
          border: (borderColor != null)
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
          boxShadow: boxShadow),
      child: (imageUrl != null)
          ? InkWell(
              onTap: showProfileOnFullScreen
                  ? () {
                      navigatePushTo(
                        context,
                        ImageViewScreen(
                          appBarTitle: '',
                          imageUrls: [imageUrl!],
                          initialIndex: 0,
                        ),
                      );
                    }
                  : null,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular((borderRadius ?? 5.0) - 1.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  // Decode at avatar size, not at whatever the user uploaded.
                  // This widget draws every author, commenter and suggestion
                  // face in the app — a feed screen holds dozens at once — and
                  // without this each one was a full-resolution bitmap in the
                  // image cache to be painted into a 40px circle. See
                  // [decodeWidthFor].
                  memCacheWidth: decodeWidthFor(context, size),
                  placeholder: (context, url) => Container(
                    width: size,
                    height: size,
                    color: Colors.grey[300],
                    // child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.person, size: size / 2),
                ),
              ),
            )
          : Icon(Icons.person, size: size / 2),
    );
  }
}
