import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/auth/views/screens/visiting_card_page.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/sharing_business_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VisitingCardHelper {

  /// Builds the card off-screen, captures it, then shares the PNG.
  static Future<void> buildAndShareVisitingCard(BuildContext context) async {
    GlobalKey cardKey = GlobalKey();

    // 1. Create an overlay that is **not** visible
    final overlay = OverlayEntry(
      builder: (_) => Transform.translate(
        offset: const Offset(0, -9999), // move completely off-screen
        child: VisitingCard(cardKey: cardKey),
      ),
    );

    Overlay.of(context).insert(overlay);

    // Wait until the frame is actually painted
    await WidgetsBinding.instance.endOfFrame;

    // One extra pump to be safe on slow devices
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      await VisitingCardHelper().shareVisitingCard(cardKey, shareProfile: false);
    } finally {
      overlay.remove();
    }
  }

  static bool _isProductSharing = false;

  /// Builds the card off-screen, captures it, then shares the PNG.
  static Future<void> buildAndShareProductCard(
      BuildContext context,
      GetProductData ownProductData,
      {required int index}
      ) async {
    if (_isProductSharing) return;
    _isProductSharing = true;

    GlobalKey cardKey = GlobalKey();

    final int randomIndex = Random().nextInt(bgAssetsForProductSharing.length);
    final String bgAsset = bgAssetsForProductSharing[randomIndex];

    await Future.wait([
      precacheImage(AssetImage(bgAsset), context),
      if (ownProductData.product.details?.media[index] != null &&
          ownProductData.product.details!.media[index].isNotEmpty)
        precacheImage(
          NetworkImage(ownProductData.product.details!.media[index]),
          context,
        ),
      precacheImage(
        NetworkImage(userProfileGlobal),
        context,
      ),
    ]);

    // 1. Create an overlay that is not visible
    final overlay = OverlayEntry(
      builder: (_) => Transform.translate(
        offset: const Offset(0, -9999), // move completely off-screen
        child: SharingBusinessProductCard(
          cardKey: cardKey,
          ownProductData: ownProductData,
          backgroundAsset: bgAsset,
          // index: index
        ),
      ),
    );

    Overlay.of(context).insert(overlay);

    // Wait until the frame is actually painted
    await WidgetsBinding.instance.endOfFrame;

    // One extra pump to be safe on slow devices
    // await Future.delayed(const Duration(milliseconds: 50));

    try {
      await VisitingCardHelper().shareVisitingCard(cardKey, productId: ownProductData.product.details?.id);
    } finally {
      overlay.remove();

      // await NetworkImage(userProfileGlobal).evict();
      await AssetImage(bgAsset).evict();
      if (ownProductData.product.details!.media[index].isNotEmpty) {
        await NetworkImage(ownProductData.product.details!.media[index]).evict();
      }

      _isProductSharing = false;

    }
  }


  bool _isSharing = false;

  Future<void> shareVisitingCard(
      GlobalKey cardKey,
      {bool shareProfile = true,
        String? productId,
        String? serviceId,
        String? foodServiceId
      }) async {
    print('sharing');
    if (_isSharing) return;

    try {
      _isSharing = true; // Set flag to prevent multiple calls
      print('sharing start');
      // Capture with RepaintBoundary (keeps your background image)
      RenderRepaintBoundary boundary =
      cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save captured image
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/visiting_card.png').create();
      await file.writeAsBytes(pngBytes);

      final String message;
      if(productId!=null){
        final link = productDeepLink(productId: productId);
        message = "Link to visit my store at BlueEra app:\n$link\n";
      } else if(serviceId!=null){
        final link = serviceDeepLink(serviceId: serviceId);
        message = "Link to visit my store at BlueEra app:\n$link\n";
      } else if(foodServiceId!=null){
        final link = foodServiceDeepLink(foodServiceId: foodServiceId);
        message = "Link to visit my store at BlueEra app:\n$link\n";
      } else if(shareProfile){
        final link = profileDeepLink(userId: userId);
        message = "See my profile on BlueEra:\n$link\n";
      }else{
        message = """
Download our app now:
👉 Play Store: ${AppConstants.androidPlayStoreUrl}
👉 App Store: ${AppConstants.iosAppStoreUrl}
""";
      }

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: message,
        subject: message,
      ));

      // Clean up the temporary file
      if (await file.exists()) {
        await file.delete();
        debugPrint("🗑️ Visiting card image deleted from cache.");
      }

    } catch (e) {
      debugPrint("❌ Error sharing card: $e");
    } finally {
      _isSharing = false;
    }
  }
}