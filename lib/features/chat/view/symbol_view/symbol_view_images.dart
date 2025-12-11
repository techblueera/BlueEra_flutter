import 'package:flutter/material.dart';

import '../../auth/model/GetChatListModel.dart';

class SymbolViewImages extends StatefulWidget {
  final List<SymbolDataModel> data;

  const SymbolViewImages({super.key, required this.data});

  @override
  State<SymbolViewImages> createState() => _SymbolViewImagesState();
}

class _SymbolViewImagesState extends State<SymbolViewImages>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int currentIndex = 0;

  List<String> allImages = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    /// Collect all images
    for (var post in widget.data) {
      if (post.media != null) {
        allImages.addAll(post.media!);
      }
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void goNext() {
    if (currentIndex < allImages.length - 1) {
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
                itemCount: allImages.length,
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemBuilder: (_, index) {
                  return InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        allImages[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
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
                  allImages.length,
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
