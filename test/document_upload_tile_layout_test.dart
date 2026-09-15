import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// How a picked document is framed in [CommonImageUploadTile].
///
/// The tile used to be a fixed `SizedBox(height: 150)` wrapped around a LOOSE
/// Stack. A loose Stack gives its children unbounded height, so
/// `Image.file(width: double.infinity)` laid itself out at the photo's own
/// ratio and `BoxFit.cover` had no box to cover — an Aadhaar card in a
/// half-width tile rendered ~96pt tall inside a 150pt box, leaving a band of
/// empty white beneath it and making the Front slot tower over an empty Back
/// slot next to it.
///
/// [CommonImageUploadTile.previewAspectRatio] fixes that by shaping the tile
/// to the ratio the caller crops to. It is opt-in: 35 call sites share this
/// widget and most upload ordinary photos (school notices, portfolios), which
/// have no single shape and must not be cropped into an ID card.
void main() {
  /// A real 1x1 PNG. `Image.file` needs a decodable file — a fake path raises
  /// during paint and the layout assertions never get to run.
  late File imageFile;

  setUpAll(() {
    const onePixelPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    imageFile = File(
      '${Directory.systemTemp.createTempSync('tile_test').path}/pixel.png',
    )..writeAsBytesSync(
        Uint8List.fromList(base64Decode(onePixelPngBase64)),
      );
  });

  const tileWidth = 160.0;
  final cardRatio = CommonImageUploadTile.documentCropAspectRatio.ratio;

  Future<void> pumpTile(
    WidgetTester tester, {
    required Rxn<File> file,
    double? previewAspectRatio,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) {
          SizeConfig.init(context);
          return Scaffold(
            body: Center(
              child: SizedBox(
                width: tileWidth,
                child: CommonImageUploadTile(
                  title: 'Front',
                  imageFile: file,
                  context: context,
                  previewAspectRatio: previewAspectRatio,
                ),
              ),
            ),
          );
        }),
      ),
    );
    await tester.pump();
  }

  group('with a document ratio', () {
    testWidgets('the picked card fills the tile with no dead space',
        (tester) async {
      await pumpTile(
        tester,
        file: Rxn<File>(imageFile),
        previewAspectRatio: cardRatio,
      );

      final size = tester.getSize(find.byType(AspectRatio).first);
      expect(size.width, tileWidth);
      expect(
        size.width / size.height,
        closeTo(cardRatio, 0.01),
        reason: 'the tile must be the shape of the crop, or the preview '
            'letterboxes inside it again',
      );
    });

    testWidgets('an empty tile is the same size as a filled one',
        (tester) async {
      await pumpTile(
        tester,
        file: Rxn<File>(imageFile),
        previewAspectRatio: cardRatio,
      );
      final filled = tester.getSize(find.byType(AspectRatio).first);

      await pumpTile(
        tester,
        file: Rxn<File>(),
        previewAspectRatio: cardRatio,
      );
      final empty = tester.getSize(find.byType(AspectRatio).first);

      expect(
        empty,
        filled,
        reason: 'Front holding a card must not tower over an empty Back',
      );
    });

    testWidgets('the image is told to cover its box', (tester) async {
      await pumpTile(
        tester,
        file: Rxn<File>(imageFile),
        previewAspectRatio: cardRatio,
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect(
        image.width,
        isNull,
        reason: 'an explicit width would re-impose the old natural-ratio '
            'layout inside the shaped box',
      );
    });
  });

  group('without a document ratio', () {
    /// The other 34 call sites. Their photos have no single shape, so the
    /// tile must not force one on them.
    testWidgets('no shape is imposed on an ordinary photo', (tester) async {
      await pumpTile(tester, file: Rxn<File>(imageFile));

      expect(find.byType(AspectRatio), findsNothing);
    });

    testWidgets('the preview still spans the tile width', (tester) async {
      await pumpTile(tester, file: Rxn<File>(imageFile));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect(image.width, double.infinity);
    });
  });
}
