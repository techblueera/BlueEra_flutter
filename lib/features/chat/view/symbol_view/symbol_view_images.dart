import 'dart:developer';

import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:video_player/video_player.dart';

import '../../auth/controller/add_chat_symbol_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../../auth/model/symbol_details_model.dart';

class SymbolViewImages extends StatefulWidget {
  final List<SymbolDataModel>? data;
  final String? userId;
  final List<SymbolDetailsModel>? mySymbols;

  const SymbolViewImages({super.key, this.data,  this.mySymbols,this.userId});

  @override
  State<SymbolViewImages> createState() => _SymbolViewImagesState();
}

class _SymbolViewImagesState extends State<SymbolViewImages>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int currentIndex = 0;
  List<SymbolDetailsModel>? allImages=[];
  final addSymbolController = Get.isRegistered<AddChatSymbolController>()
      ? Get.find<AddChatSymbolController>()
      : Get.put(AddChatSymbolController());

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  VideoPlayerController? _videoController;
  bool isPlaying = true;
  void getSymbols()async{
    allImages  = await addSymbolController.getSymbolsForOtherUser(widget.userId??'');
 setState(() {

 });
  }
  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    if(widget.mySymbols==null){
      if(widget.userId!=null){
        getSymbols();
      }
      //  allImages= widget.data;
    }else{
      allImages= widget.mySymbols;
    }
    /// Collect all images
    // for (var post in (widget.data??[])) {
    //   if (post.media != null) {
    //     allImages.addAll(post.media!);
    //   }
    //

    // }

    /// Smooth fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 200),(){
      setState(() {

      });
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
    if (currentIndex < (allImages?.length??0) - 1) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            /// Image viewer with fade animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: PageView.builder(
                controller: _pageController,
                itemCount: allImages?.length,
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemBuilder: (_, index) {
                  final url = allImages?[index];
                    if(url?.type=='photo'||url?.type=="video"){
                      final isVideo = url?.content?.toLowerCase().contains('.mp4');
                      if (isVideo??false) {
                        _videoController?.dispose();
                        _videoController =
                        VideoPlayerController.networkUrl(Uri.parse(url?.content??''))
                          ..initialize().then((_) {
                            setState(() {});
                            _videoController!.play();
                            isPlaying = true;
                          })
                          ..setLooping(true);
                      }


                      /// IMAGE (unchanged)
                      return Stack(
                        children: [
                          if(isVideo??false)
                            Center(
                              child: AspectRatio(
                                aspectRatio: _videoController!.value.isInitialized
                                    ? _videoController!.value.aspectRatio
                                    : 16 / 9,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                          else
                            Positioned(
                              top: 0,
                              right: 0,
                              left: 0,
                              bottom: 20,
                              child: InteractiveViewer(
                                child: Center(
                                  child: Image.network(
                                    url?.content??"",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          if(isVideo??false)
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_videoController!.value.isPlaying) {
                                      _videoController!.pause();
                                      isPlaying = false;
                                    } else {
                                      _videoController!.play();
                                      isPlaying = true;
                                    }
                                  });
                                },
                                child: AnimatedOpacity(
                                  opacity: isPlaying ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: (url?.caption?.isNotEmpty??false)?Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(26, 20, 26, 44),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black12,
                                    Colors.black87,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  // IconButton(
                                  //   icon: const Icon(Icons.favorite_border,
                                  //       color: Colors.white,size: 22,),
                                  //   onPressed: () {},
                                  // ),
                                  Expanded(
                                    child: CustomText(
                                      "${url?.caption}",

                                      color: Colors.white,
                                      fontSize: 16,

                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ):SizedBox(),
                          ),
                        ],
                      );
                    }else if(url?.type=="text"){
                      Color hexToColor(String? hex) {
                        if (hex == null) return Colors.transparent;

                        hex = hex.trim();

                        if (hex.startsWith('#')) {
                          hex = hex.substring(1);
                        }

                        // Support shorthand hex like #FFF
                        if (hex.length == 3) {
                          hex = hex.split('').map((c) => '$c$c').join();
                        }

                        // Add alpha if missing
                        if (hex.length == 6) {
                          hex = 'FF$hex';
                        }

                        // Final safety check
                        if (hex.length != 8) return Colors.transparent;

                        return Color(int.parse(hex, radix: 16));
                      }
                      return Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 50,

                        ),
                        color:hexToColor(url?.backgroundColor),
                        child: Center(
                          child: CustomText(
                            textAlign: TextAlign.center,
                            "${url?.content}",
                            fontWeight: addSymbolController.getFontWeight(url?.fontWeight??''),
                            fontSize: url?.fontSize,
                            fontFamily: url?.fontFamily,
                          ),
                        ),
                      );
                    }

                },
              ),
            ),

            /// LEFT TAP REGION → go previous
            Positioned.fill(
              child: Row(
                children: [
                  /// LEFT invisible tap area
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: goPrev,
                    ),
                  ),

                  /// RIGHT invisible tap area
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: goNext,
                    ),
                  ),
                ],
              ),
            ),

            /// Back button - modern glass effect
            Positioned(
              top: 14,
              left: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  color: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            /// Modern page indicator (dots)
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allImages?.length??0,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: currentIndex == i ? 22 : 8,
                    decoration: BoxDecoration(
                      color: currentIndex == i
                          ? Colors.white
                          : Colors.white54,
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
}
