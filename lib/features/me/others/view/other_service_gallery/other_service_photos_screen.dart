import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/features/me/others/controller/other_service_photo_controller.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/other_service_category_details_screen.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/upload_other_service_photos_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OtherServicePhotosPhotoScreen extends StatelessWidget {
  final controller = Get.put(OtherServicePhotoPhotoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherServicePhotos.tr,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20,right: 20,bottom: 30,top: 10),
          child: PositiveCustomBtn(
              onTap: () => _startUpload(context),
              title: AppStrings.otherUploadServicePhoto.tr),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const _PhotosShimmer();

        // `albumsWithPhotos`, not the raw list: an album with no images has no
        // thumbnail and reads as a broken card. The controller deliberately
        // KEEPS those albums so their category survives in the upload form —
        // see `fetchPhotos`.
        final albums = controller.albumsWithPhotos;

        // Reachable by deleting the last photo out of the last album while
        // standing here — the Overview tab routes an already-empty gallery
        // straight to the upload form, so this is the only way in. Without it
        // the body went blank white and the sole working control was the
        // button pinned at the very bottom of the screen.
        if (albums.isEmpty) {
          return EmptyStateWidget(
            message: AppStrings.noGalleryPhotosYet.tr,
            actionText: AppStrings.otherUploadServicePhoto.tr,
            actionCallback: () => _startUpload(context),
            actionHighlight: true,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            var item = albums[index];
            List images = item.imageUrls ?? [];
            String firstImage = images.isNotEmpty ? images[0] : "";

            return InkWell(
              onTap: () {
                Get.to(()=> OtherServiceCategoryDetailsScreen(
                  categoryData: item,
                ));
              },
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Thumbnail with Image Count Overlay
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              firstImage,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      color: Colors.grey,
                                      width: 100,
                                      height: 100,
                                      child: Icon(Icons.image)),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CustomText(
                                "+${images.length} ${AppStrings.hotelImagesSuffix.tr}",
                                textAlign: TextAlign.center,

                                    color: Colors.white, fontSize: 10),

                            ),
                          )
                        ],
                      ),
                      SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(item.title??"",
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                              ],
                            ),
                            SizedBox(height: 4),
                            CustomText("${AppStrings.hotelLastUpdate.tr} ${formatIsoDate(item.updatedAt??"")}",

                                    color: Colors.grey, fontSize: 12),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
  /// Opens the upload form. It does NOT open a picker.
  ///
  /// Tapping "Upload" used to fire the camera/gallery chooser immediately, from
  /// the gallery list, before the merchant had seen the upload screen at all —
  /// a button labelled "upload service photo" that answered with a camera. The
  /// form is where photos belong: it already has an add tile that opens the
  /// same picker, so the merchant lands on the screen, sees the empty box, and
  /// asks for the picker when they are ready.
  ///
  /// The form starts blank because [resetUploadForm] runs here and this
  /// controller outlives the screen — whatever a cancelled attempt left behind
  /// must not leak into this one.
  void _startUpload(BuildContext context) {
    controller.resetUploadForm();
    Get.to(() => const UploadOtherServicePhotosScreen());
  }

  static String formatIsoDate(String isoString) {
    if (isoString.isEmpty) return "";
    DateTime dateTime = DateTime.parse(isoString);
    return DateFormat('dd MMM, yyyy').format(dateTime);
  }
}

/// Placeholder while the gallery loads.
///
/// Deliberately the SHAPE of the real list rather than a spinner: same card
/// margin and radius, the same 100x100 thumbnail, the same title and
/// "last update" lines at the same sizes. The swap to real content then reads
/// as the page finishing rather than as a different screen replacing it, and
/// the scroll extent doesn't jump.
///
/// This is also why the fetch no longer raises the global progress dialog
/// (`showProgress: false` on `getOtherServicePhotosRepo`) — that dialog would
/// sit on top of this and give the merchant two loaders at once.
class _PhotosShimmer extends StatelessWidget {
  const _PhotosShimmer();

  /// Four rows: enough to fill a phone screen, so the shimmer never stops
  /// short of the fold and read as a half-loaded list.
  static const int _rowCount = 4;

  @override
  Widget build(BuildContext context) {
    return buildLoadingShimmer(
      child: ListView.builder(
        // The list underneath can't be scrolled yet, and letting a skeleton
        // bounce invites a pull-to-refresh gesture that has nothing to refresh.
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _rowCount,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                shimmerContainer(width: 100, height: 100, radius: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title — 16px bold in the real card.
                      shimmerContainer(height: 16, width: 140),
                      const SizedBox(height: 10),
                      // "Last update <date>" — 12px grey.
                      shimmerContainer(height: 12, width: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
