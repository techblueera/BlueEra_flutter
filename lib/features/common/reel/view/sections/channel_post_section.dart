// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/reel/view/sections/video_channel_section.dart';
// import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
//
// class ChannelPostSection extends StatefulWidget {
//   final bool isOwnProfile;
//   const ChannelPostSection({super.key, this.isOwnProfile = false});
//
//   @override
//   State<ChannelPostSection> createState() => _ChannelPostSectionState();
// }
//
// class _ChannelPostSectionState extends State<ChannelPostSection> {
//   final List<String> shortsVideos = [
//     'https://i.ytimg.com/vi/1Ne1hqOXKKI/maxresdefault.jpg', // Viral Shorts - working
//     'https://i.ytimg.com/vi/ktvTqknDobU/maxresdefault.jpg', // Imagine Dragons - Radioactive
//     'https://i.ytimg.com/vi/hTWKbfoikeg/maxresdefault.jpg', // Nirvana - Smells Like Teen Spirit
//     'https://i.ytimg.com/vi/LXb3EKWsInQ/maxresdefault.jpg', // Maldives Drone Shots
//   ];
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [_buildShortsVideos(), _buildVideos()],
//     );
//   }
//
//   Widget _buildShortsVideos() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Padding(
//         //   padding: EdgeInsets.all(SizeConfig.size15),
//         //   child: CustomText(
//         //     "Shorts",
//         //     fontSize: SizeConfig.small,
//         //     fontWeight: FontWeight.w700,
//         //   ),
//         // ),
//         SizedBox(height: SizeConfig.size8),
//         SizedBox(
//           height: SizeConfig.size190,
//           child: ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             shrinkWrap: true,
//             scrollDirection: Axis.horizontal,
//             physics: const AlwaysScrollableScrollPhysics(),
//             itemCount: shortsVideos.length,
//             itemBuilder: (context, index) {
//               String shortsVideosItem = shortsVideos[index];
//               return ShortsGrid(
//                 imageItem: shortsVideosItem,
//                 isOwnProfile: widget.isOwnProfile,
//                 padding: SizeConfig.size2,
//                 imageHeight: SizeConfig.size190,
//                 imageWidth: SizeConfig.size110,
//                 shortsFeedType: ShortsFeedType.trending,
//               );
//             },
//           ),
//         ),
//         SizedBox()
//         // FeedCard(post: qaPost, index: 0),
//       ],
//     );
//   }
//
//   Widget _buildVideos() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.only(left: SizeConfig.size15, top: SizeConfig.size15),
//           child: CustomText(
//             "Videos",
//             fontSize: SizeConfig.small,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         VideoFeedSection(isOwnProfile: widget.isOwnProfile, isScroll: false)
//       ],
//     );
//   }
// }
