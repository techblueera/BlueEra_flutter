import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/chat/view/personal_chat/personal_chat_profile_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/reel/view/sections/shorts_channel_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/testimonial_listing_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';

class ChatProfileOverview extends StatefulWidget {
  final String userId;
  const ChatProfileOverview({super.key, required this.userId});

  @override
  State<ChatProfileOverview> createState() => _ChatProfileOverviewState();
}

class _ChatProfileOverviewState extends State<ChatProfileOverview> {
  double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isExpanded = true;

  final visitController = Get.put(PersonalChatProfileController());

  @override
  void initState() {
    apiCalling();
    super.initState();
  }

  apiCalling() async {
    await visitController.getTestimonialController(userID: widget.userId);
  }

  /// 👉 Popup dialog for Rate & Review
  void _showRateAndReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Rate And Review",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ⭐ Rating Bar
              RatingBar.builder(
                initialRating: _userRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 36,
                unratedColor: Colors.grey.shade400,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _userRating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),

              /// 📝 Review Field
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'E.g. "Great service, quick response, highly recommended!"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reviewController.clear();
                setState(() => _userRating = 0);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_userRating > 0) {
              
                  print(
                      "Rating: $_userRating, Review: ${_reviewController.text}");

                  /// Example: If you have API to post testimonial, call it here
                  // visitController.postTestimonial(
                  //   userID: widget.userId,
                  //   rating: _userRating,
                  //   review: _reviewController.text,
                  // );

                  Navigator.pop(context);
                } else {
                  Get.snackbar(
                      "Rating required", "Please select at least 1 star");
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ⭐ Rating Summary
          Card(
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Rating Summary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        /// ⭐ Average + Count (always visible)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: const Text("4.0",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star_border, color: Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("5,455 Reviews",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ],
        ),

        if (_isExpanded) const SizedBox(height: 16),

        /// Expanded → Show detailed breakdown + Rate & Review UI
        if (_isExpanded) ...[
          /// Rating distribution bars
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRatingRow(5, 0.9),
              _buildRatingRow(4, 0.7),
              _buildRatingRow(3, 0.5),
              _buildRatingRow(2, 0.3),
              _buildRatingRow(1, 0.1),
            ],
          ),
          const SizedBox(height: 20),

          /// Rate & Review form
          const Text("Rate And Review",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Center(
            child: RatingBar.builder(
              initialRating: _userRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 36,
              unratedColor: Colors.grey.shade400,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _userRating = rating;
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Write Your Review (Optional)",
              hintText:
                  'E.g. "Great service, quick response, highly recommended!"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  _reviewController.clear();
                  setState(() => _userRating = 0);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_userRating > 0) {
                    print("Rating: $_userRating, Review: ${_reviewController.text}");
                    // TODO: Call API here
                  } else {
                    Get.snackbar("Rating required", "Please select at least 1 star");
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          )
        ],
      ],
    ),
  ),
),


          const SizedBox(height: 16),

          /// 🧑‍ Testimonials
          const Text(
            'Testimonials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          TestimonialListingWidget(userId: widget.userId),

          const SizedBox(height: 16),

          /// 📄 Post
          const Text('Post',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          SizedBox(
            height: 500,
            child: FeedScreen(
              key: ValueKey('feedScreen_user_posts_${widget.userId}'),
              postFilterType: PostType.otherPosts,
              isInParentScroll: true,
              id: widget.userId,
            ),
          ),

          const SizedBox(height: 16),

          /// 🎬 Shorts
          const Text("Shorts",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ShortsChannelSection(
            isOwnChannel: false,
            channelId: '',
            authorId: widget.userId,
            showShortsInGrid: false,
          ),

          const SizedBox(height: 16),

          /// 📹 Videos (demo static)
          const Text("Videos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Image.network(
                  "https://img.freepik.com/free-photo/famous-vlogger-filming-smart-speaker-review-his-followers-influencer-recording-new-vlog_482257-25221.jpg?semt=ais_hybrid&w=740&q=80",
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                ListTile(
                  leading: const CircleAvatar(
                      backgroundImage:
                          NetworkImage("https://via.placeholder.com/150")),
                  title: const Text("Trying MC’s Burger for the first time!"),
                  subtitle:
                      const Text("TeckSavvy • 3.8k Views • 12 days ago"),
                  trailing: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRatingRow(int stars, double percentage) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text("$stars ★", style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade300,
            color: Colors.blue,
            minHeight: 6,
          ),
        ),
      ],
    ),
  );
}
}
