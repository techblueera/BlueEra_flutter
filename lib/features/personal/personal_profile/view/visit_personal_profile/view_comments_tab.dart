import 'package:flutter/material.dart';

class ViewCommentsTab extends StatelessWidget {
  final bool showComment;

  const ViewCommentsTab({super.key, this.showComment = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4,),
        for(int i=0;i<2;i++)
          Card(color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red post background
              Container(
                color: const Color(0xFF801C1C), // Deep red
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Finally Graduated! 🎓',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hard Work + Late Nights = This!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Thanks to everyone who backed\nme through it all.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Optional comment section
              if (showComment)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: '@Alex John ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: 'commented on this post',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const TextSpan(
                              text: '    2 days ago',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Congratulations🎉🥳',
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
