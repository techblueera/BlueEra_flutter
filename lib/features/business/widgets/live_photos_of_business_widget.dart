import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BusinessLivePhotos extends StatelessWidget {
  final List<String> livePhotos;

  const BusinessLivePhotos({
    super.key,
    required this.livePhotos,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      child: Column(mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                  "Live Photos",
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                color: AppColors.grayText,
              ),
            ],
          ),

          Container(
            color: AppColors.white0D,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                child: Row(
                  children: livePhotos.isNotEmpty
                      ? livePhotos.asMap().entries.map((photoUrl) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: (){
                          navigatePushTo(
                            context,
                            ImageViewScreen(
                              subTitle: '',
                              appBarTitle: 'Store Image',
                              imageUrls: livePhotos,
                              initialIndex: photoUrl.key,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            photoUrl.value,
                            width: 100,
                            height: 130,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 100,
                                height: 130,
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 130,
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList()
                      : [
                    Container(
                      width: 100,
                      height: 130,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text(
                        'No Photos\nAvailable',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}