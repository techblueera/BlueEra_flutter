import 'package:BlueEra/features/common/feed/controller/status_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatusViewer extends StatefulWidget {
final List<Post> posts;
final int currentViewIndex;
  StatusViewer({super.key,  required this.posts, required this.currentViewIndex});

  @override
  State<StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<StatusViewer> {
  final controller = Get.put(StatusViewerController());
@override
  void initState() {
    // TODO: implement initState
  controller.currentIndex.value=widget.currentViewIndex;
  controller.setPosts(widget.posts);

  super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.posts.isEmpty)
          return const Center(child: Text("No posts"));

        final post = controller.posts[controller.currentIndex.value];

        return GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.localPosition.dx < width / 2) {
              controller.previous();
            } else {
              controller.next();
            }
          },
          child: Stack(
            children: [
              // ✅ Media (image/video)
              Positioned.fill(
                child: PageView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: PageController(
                      initialPage: controller.currentIndex.value),
                  itemCount: post.media?.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      post.media?[index] ?? "",
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),

              // ✅ Header (User info)
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(post.user?.profileImage ?? ""),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(post.user?.name ?? "",
                              color: Colors.white, fontWeight: FontWeight.bold),
                          CustomText(
                            "@${post.user?.username}",
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Bottom Description
              if ((post.subTitle?.isNotEmpty ?? false) ||
                  (post.title?.isNotEmpty ?? false))
                Positioned(
                  bottom: 40,
                  left: 16,
                  right: 16,
                  child: CustomText(
                    (post.subTitle?.isNotEmpty ?? false)
                        ? (post.subTitle ?? "")
                        : (post.title ?? ""),
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
