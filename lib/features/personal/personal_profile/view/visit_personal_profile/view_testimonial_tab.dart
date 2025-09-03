import 'package:flutter/material.dart';

class TestimonialPage extends StatelessWidget {
  const TestimonialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0,vertical: 12),
      child: Column(
        children: [
          _buildTestimonialInputCard(),
          const SizedBox(height: 20),
          _buildTestimonialCard(),
          const SizedBox(height: 12),
          _buildTestimonialCard(),
          const SizedBox(height: 12),
          _buildTestimonialCard(),
        ],
      ),
    );
  }

  Widget _buildTestimonialInputCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text.rich(
              TextSpan(
                text: 'Write a Testimonial for ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: 'Alex John ✨✍️',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(hintStyle:TextStyle(fontFamily: "Arial",color: Color.fromRGBO(122, 139, 154, 1)) ,
                hintText: 'Testimonial Title (e.g., Supportive Teammate, Calm Leader)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: const Color(0xfff0f2f5),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintStyle: TextStyle(fontFamily: "Arial",color: Color.fromRGBO(122, 139, 154, 1)),
                hintText:
                'Write a few words about their personality, behavior, or how it was working with them...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: const Color(0xfff0f2f5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff1DA1F2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Add Testimonial',
                  style: TextStyle(fontSize: 16,color: Colors.white,fontFamily: "Arial"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "✨ Professional Yet Warm",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '"Working with Alex has been an absolute pleasure. Their positive attitude, calm demeanor, and willingness to help others make them a standout team member. Always respectful and solution-oriented — a true asset to any environment."',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avatar.png'),
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("TechSavvy", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Content Creator", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                Row(
                  children: const [
                    Text("❤️ 😍 😂", style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Text(
                      '5k+',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Spacer(),
                _buildIconText(Icons.chat_bubble_outline, '310'),
                const SizedBox(width: 16),
                _buildIconText(Icons.bookmark_border, 'Save'),
                const SizedBox(width: 16),
                _buildIconText(Icons.share_outlined, '50'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
