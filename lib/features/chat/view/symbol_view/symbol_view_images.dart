import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:any_link_preview/any_link_preview.dart';
import '../../auth/controller/add_chat_symbol_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../../auth/model/symbol_details_model.dart';
import '../widget/custom_video_player.dart';

class SymbolViewImages extends StatefulWidget {
  final List<SymbolDataModel>? data;
  final String? userId;
  final List<SymbolDetailsModel>? mySymbols;

  const SymbolViewImages({super.key, this.data, this.mySymbols, this.userId});

  @override
  State<SymbolViewImages> createState() => _SymbolViewImagesState();
}

class _SymbolViewImagesState extends State<SymbolViewImages> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int currentIndex = 0;
  List<SymbolDetailsModel>? allImages = [];
  final addSymbolController = Get.isRegistered<AddChatSymbolController>() ? Get.find<AddChatSymbolController>() : Get.put(AddChatSymbolController());

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  VideoPlayerController? _videoController;
  bool isPlaying = true;

  void getSymbols() async {
    allImages = await addSymbolController.getSymbolsForOtherUser(widget.userId ?? '');
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    if (widget.mySymbols == null) {
      if (widget.userId != null) {
        getSymbols();
      }
    } else {
      allImages = widget.mySymbols;
    }

    /// Smooth fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void goNext() {
    if (currentIndex < (allImages?.length ?? 0) - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void goPrev() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Color hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    hex = hex.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return Colors.black;
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            /// Content Viewer
            FadeTransition(
              opacity: _fadeAnimation,
              child: PageView.builder(
                controller: _pageController,
                itemCount: allImages?.length,
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemBuilder: (_, index) {
                  final url = allImages?[index];

                  if (url?.type == 'photo' || url?.type == "video") {
                    final isVideo = url?.content?.toLowerCase().contains('.mp4');
                    return Stack(
                      children: [
                        if (isVideo ?? false)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ChatCustomVideoPlayer(
                                videoUrl: url?.content ?? "",
                              ),
                            ),
                          )
                        else
                          Positioned.fill(
                            child: InteractiveViewer(
                              child: Center(
                                child: Image.network(
                                  url?.content ?? "",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: (url?.caption?.isNotEmpty ?? false)
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(26, 60, 26, 60),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black87,
                                      ],
                                    ),
                                  ),
                                  child: CustomText(
                                    "${url?.caption}",
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    );
                  } else if (url?.type == "text" || url?.type == "embeddedUrl") {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: hexToColor(url?.backgroundColor),
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: buildLinkPreview(url?.content ?? ''),
                              ),
                              if (url?.content != null && url!.content!.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: url.content!.contains('http')
                                      ? _buildUrlChip(url.content!)
                                      : CustomText(
                                          textAlign: TextAlign.center,
                                          "${url.content}",
                                          fontWeight: addSymbolController.getFontWeight(url.fontWeight ?? 'normal'),
                                          fontSize: (url.fontSize ?? 18) * 1.1,
                                          fontFamily: url.fontFamily,
                                          color: Colors.white,
                                          height: 1.4,
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ),

            /// LEFT/RIGHT TAP REGIONS
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: goPrev,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: goNext,
                    ),
                  ),
                ],
              ),
            ),

            /// Controls
            Positioned(
              top: 14,
              left: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  color: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            if (widget.mySymbols?.isNotEmpty ?? false) deleteWidget(allImages![currentIndex]),

            /// Page indicator
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allImages?.length ?? 0,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: currentIndex == i ? 22 : 8,
                    decoration: BoxDecoration(
                      color: currentIndex == i ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUrlChip(String url) {
    String domain = url;
    try {
      domain = Uri.parse(url).host;
      if (domain.startsWith('www.')) domain = domain.substring(4);
    } catch (_) {}

    final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            faviconUrl,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const Icon(Icons.language, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            domain,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget buildLinkPreview(String message) {
    final hasLink = message.contains("http");
    if (!hasLink) return const SizedBox.shrink();

    String link = message;
    final regExp = RegExp(r'(https?:\/\/[^\s]+)');
    final match = regExp.firstMatch(message);
    if (match != null) {
      link = match.group(0)!;
    }

    final double squareSize = MediaQuery.of(context).size.width - 40;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: -10,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnyLinkPreview.builder(
          link: link,
          cache: const Duration(days: 7),
          placeholderWidget: Container(
            height: squareSize,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
          ),
          errorWidget: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link_rounded, color: AppColors.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    link,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          itemBuilder: (context, metadata, imageProvider, svgImage) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageProvider != null)
                  SizedBox(
                    height: squareSize,
                    width: double.infinity,
                    child: Image(image: imageProvider, fit: BoxFit.cover),
                  )
                else if (svgImage != null)
                  SizedBox(height: squareSize, width: double.infinity, child: svgImage),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (metadata.title != null && metadata.title!.isNotEmpty)
                        Text(
                          metadata.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                        ),
                      if (metadata.desc != null && metadata.desc!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          metadata.desc!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget deleteWidget(SymbolDetailsModel symbol) {
    return Positioned(
      top: 14,
      right: 14,
      child: InkWell(
        onTap: () async {
          final deletedIndex = currentIndex;
          allImages = await addSymbolController.deleteSymbol(symbolData: symbol);

          if (allImages == null || allImages!.isEmpty) {
            Get.back();
            return;
          }

          if (deletedIndex >= allImages!.length) {
            currentIndex = allImages!.length - 1;
          } else {
            currentIndex = deletedIndex;
          }

          setState(() {});
          _pageController.jumpToPage(currentIndex);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            color: Colors.black26,
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
