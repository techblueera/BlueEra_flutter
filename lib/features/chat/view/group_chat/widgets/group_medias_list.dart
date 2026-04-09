import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/model/group_details_model.dart';
import '../../../auth/model/messageMediaUrl.dart';
import '../../widget/media_message_full_view.dart';

class GroupMediasList extends StatefulWidget {
  const GroupMediasList({super.key, required this.mediaList});
  final List<GroupMediaModel> mediaList;
  @override
  State<GroupMediasList> createState() => _GroupMediasListState();
}

class _GroupMediasListState extends State<GroupMediasList> {
  @override
  Widget build(BuildContext context) {
    // Flatten the media list to get all individual URLs
    List<MessageMediaUrl> allMediaUrls = [];
    for (var media in widget.mediaList) {
      if (media.url != null) {
        allMediaUrls.addAll(media.url!);
      }
    }

    // Sort to show images first
    allMediaUrls.sort((a, b) {
      bool isAImage = a.type?.startsWith('image') ?? false;
      bool isBImage = b.type?.startsWith('image') ?? false;
      if (isAImage && !isBImage) return -1;
      if (!isAImage && isBImage) return 1;
      return 0;
    });

    if (allMediaUrls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CustomText(AppStrings.noMediaFoundLabel.tr),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: allMediaUrls.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing:2,
        mainAxisSpacing: 2,
        mainAxisExtent: 160,
      ),
      itemBuilder: (context, index) {
        final mediaUrl = allMediaUrls[index];
        final isImage = mediaUrl.type?.startsWith('image') ?? false;

        return InkWell(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FullImagePreviewPage(
                      images: allMediaUrls,
                      initialIndex: index,
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.whiteE5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: isImage && mediaUrl.url != null
                  ? CachedNetworkImage(
                      imageUrl: mediaUrl.url!,
                      fit: BoxFit.cover,
                      // placeholder: (context, url) => Container(
                      //   color: Colors.grey.shade200,
                      //   child: const Center(
                      //     child: CircularProgressIndicator(strokeWidth: 2),
                      //   ),
                      // ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIconForType(mediaUrl.type),
                            color: Colors.grey,
                          ),
                          if (mediaUrl.name != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                              child: Text(
                                mediaUrl.name!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.insert_drive_file_outlined;
    if (type.startsWith('video')) return Icons.videocam_outlined;
    if (type.startsWith('audio')) return Icons.audiotrack_outlined;
    if (type.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }
}
