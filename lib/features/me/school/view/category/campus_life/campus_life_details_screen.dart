import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/campus_life_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/get_all_campus_life_res_model.dart';

class CampusLifeDetailsScreen extends StatefulWidget {
  final Subcategories subcategories;

  const CampusLifeDetailsScreen({super.key, required this.subcategories});

  @override
  State<CampusLifeDetailsScreen> createState() =>
      _CampusLifeDetailsScreenState();
}

class _CampusLifeDetailsScreenState extends State<CampusLifeDetailsScreen> {
  List<Images> allImages = [];

  @override
  void initState() {
    // TODO: implement initState
    // Assuming 'subCategory' is the object you provided
    allImages = widget.subcategories.entries
            ?.expand((entry) => entry.images ?? <Images>[])
            .toList() ??
        [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.subcategories.name ?? "Gallery",
      ),
      body: CommonCardWidget(
          child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          final imageData = allImages[index];

          // Move this list generation outside the builder or use it like this:
          List<String> imageUrls = allImages
              .map((image) => image.url ?? "")
              .where((url) => url.isNotEmpty)
              .toList();

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // 1. The Image (Clickable for viewing)
                      InkWell(
                        onTap: () {
                          navigatePushTo(
                            context,
                            ImageViewScreen(
                              subTitle: widget.subcategories.name,
                              appBarTitle: AppStrings.imageViewer,
                              imageUrls: imageUrls,
                              initialIndex: index,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            imageData.url ?? "",
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),

                      // 2. Edit/Delete Overlay (Popup Menu)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: InkWell(
                          onTap: () async {
                            final controller = Get.find<CampusLifeController>();

                            await showCommonDialog(
                            context: context,
                            text:
                            'Are you sure you want to delete this photo?',
                            confirmCallback: () async {
                              Get.back();
                              await controller.deleteCampusLifeController(
                                  entriesID: widget.subcategories.entries?.first.id??"", imageID: imageData.id??"");

                            },
                            cancelCallback: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            confirmText: AppStrings.yes,
                            cancelText: AppStrings.no);
                          },
                          child: Container(
                              width: 35,
                              height: 35,
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.delete,
                                  color: Colors.red, size: 20)),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. The Caption
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomText(
                    imageData.caption ?? "Campus Life",
                    fontSize: 12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      )),
    );
  }
}
