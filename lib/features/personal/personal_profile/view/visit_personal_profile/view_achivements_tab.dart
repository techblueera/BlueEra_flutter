import 'package:BlueEra/core/api/dummy_model/media_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_enum.dart';

class ViewAchivementsTab extends StatefulWidget {
  const ViewAchivementsTab({super.key});

  @override
  State<ViewAchivementsTab> createState() => _ViewAchivementsTabState();
}

class _ViewAchivementsTabState extends State<ViewAchivementsTab> {

  final messagePost = PostData(
    id: 1,
    title: "Community Update",
    message: "We're launching a new feature today. Stay tuned!",
    type: FeedType.messagePost,
    authorId: 101,
    media: [
      Media(
        id: 1,
        url: 'https://picsum.photos/seed/pic1/400/200',
        companyId: 101,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        createdBy: 1,
        updatedBy: 1,
      ),
      Media(
        id: 1,
        url: 'https://picsum.photos/seed/pic2/400/200',
        companyId: 101,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        createdBy: 1,
        updatedBy: 1,
      ),
      Media(
        id: 1,
        url: 'https://picsum.photos/seed/pic3/400/200',
        companyId: 101,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        createdBy: 1,
        updatedBy: 1,
      )
    ],
    createdAt: DateTime.now().subtract(Duration(hours: 2)),
    updatedAt: DateTime.now(),
    totalLikes: 23,
    totalComments: 5,
    totalReposts: 2,
    totalViews: "250",
    isLike: true,
    // likeType: LikeType(
    //   id: 1,
    //   userId: 101,
    //   postId: 1001,
    //   type: "Code1",
    //   createdAt: DateTime.now().subtract(Duration(days: 1)),
    //   updatedAt: DateTime.now(),
    //   deletedAt: null,
    //   createdBy: 101,
    //   updatedBy: 101,
    // ),
  );

  final qaPost = PostData(
    id: 2,
    title: "What is the best way to learn Flutter?",
    message: "I’m starting mobile development and curious about resources.",
    type: FeedType.qaPost,
    authorId: 102,
    createdAt: DateTime.now().subtract(Duration(days: 1)),
    updatedAt: DateTime.now(),
    totalLikes: 50,
    totalComments: 10,
    totalReposts: 3,
    totalViews: "13k",
    isLike: true,
    // likeType: LikeType(
    //   id: 2,
    //   userId: 102,
    //   postId: 1002,
    //   type: "Code2", // ❤️
    //   createdAt: DateTime.now().subtract(Duration(days: 1)),
    //   updatedAt: DateTime.now(),
    //   deletedAt: null,
    //   createdBy: 102,
    //   updatedBy: 102,
    // ),
    // quesOptions: {
    //   'Dart': true,
    //   'JavaScript': false,
    //   'Python': true,
    //   'C++': false,
    // },
    // quesPostResponses: [
    //   QuestResponse(
    //     id: 1,
    //     postId: 2,
    //     userId: 201,
    //     question: "Best way to learn Flutter?",
    //     answer: "Official Docs",
    //     likesCount: 7,
    //     createdAt: DateTime.now().subtract(Duration(hours: 6)),
    //     updatedAt: DateTime.now(),
    //     updatedBy: 201,
    //   ),
    // ],
  );
  List<PostData> posts = [];
  @override
  void initState() {
    // TODO: implement initState
    posts = [
      messagePost,
      messagePost,
      messagePost,
      messagePost,
    ];
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12,),
        Expanded(
          child: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              // return FeedCard(post: posts[index],  index: index);
              return SizedBox();
            },
          ),
        )
      ],
    );
  }
}

class ImageScrollList extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    final List<String> trending = [
      'https://i.ytimg.com/vi/1Ne1hqOXKKI/maxresdefault.jpg', // Viral Shorts - working
      'https://i.ytimg.com/vi/ktvTqknDobU/maxresdefault.jpg', // Imagine Dragons - Radioactive
      'https://i.ytimg.com/vi/hTWKbfoikeg/maxresdefault.jpg', // Nirvana - Smells Like Teen Spirit
      'https://i.ytimg.com/vi/LXb3EKWsInQ/maxresdefault.jpg', // Maldives Drone Shots
      'https://i.ytimg.com/vi/LXb3EKWsInQ/maxresdefault.jpg', // Maldives Drone Shots
      'https://i.ytimg.com/vi/LXb3EKWsInQ/maxresdefault.jpg', // Maldives Drone Shots
    ];
    return SizedBox(
      height: 160, // adjust based on your image size
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 8),
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: trending.length,
        itemBuilder: (context, index) {
          return SingleShortStructure(withBackground: true, shorts: Shorts.trending);
        },
      ),
    );
  }
}