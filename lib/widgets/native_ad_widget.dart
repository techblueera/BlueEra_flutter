import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  final String adUnitId;

  const NativeAdWidget({super.key, required this.adUnitId});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    print('lod==== ${widget.adUnitId}');
    try {
      _nativeAd = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: 'listTile', // must match your registered factory
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            print('Native Ad failed: $ad   $error');

            ad.dispose();
          },
        ),

        // nativeTemplateStyle: NativeTemplateStyle(
        //   templateType: TemplateType.medium,
        //   mainBackgroundColor: Colors.white,
        //   cornerRadius: 12.0,
        //   callToActionTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.white,
        //     backgroundColor: Colors.brown,
        //     style: NativeTemplateFontStyle.monospace,
        //     size: 16.0,
        //   ),
        //   primaryTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.black,
        //     backgroundColor: Colors.transparent,
        //     style: NativeTemplateFontStyle.bold,
        //     size: 16.0,
        //   ),
        //   secondaryTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.grey[600],
        //     backgroundColor: Colors.transparent,
        //     style: NativeTemplateFontStyle.normal,
        //     size: 14.0,
        //   ),
        //   tertiaryTextStyle: NativeTemplateTextStyle(
        //     textColor: Colors.red,
        //     backgroundColor: Colors.transparent,
        //     style: NativeTemplateFontStyle.bold,
        //     size: 12.0,
        //   ),
        // ),
      )..load();
    } on Exception catch (e) {
      print('Native Ad failed: $e');

      // TODO
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();
    return Container(
      height: 120, // make similar height as FeedCard
      padding: const EdgeInsets.all(8),
      child: AdWidget(ad: _nativeAd!),
    );
  }


}


