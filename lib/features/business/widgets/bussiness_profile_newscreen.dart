import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BussinessProfileNewscreen extends StatelessWidget {
  const BussinessProfileNewscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Column(
        children: [
          widget_profileHeader(),
        ],
      ),
    );
  }

  widget_profileHeader() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(SizeConfig.size3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.red,
                    child: Image.asset("assets/images/brand_logo.png"),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "McDonalds....",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildTag("Restaurant"),
                          const SizedBox(width: 6),
                          _buildTag("Closed",
                              color: Colors.red.shade200,
                              textColor: Colors.red),
                          const SizedBox(width: 6),
                          _buildTag("14.2 KM Far"),
                        ],
                      )
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {},
                  child: const Text("Follow"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.location_on, size: 16, color: Colors.black54),
                SizedBox(width: 4),
                Text(
                  "Gomti Nagar, Lucknow",
                  style: TextStyle(color: Colors.black87),
                )
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Korem ipsum dolor sit amet, consectetur adipiscing elit. Nunc "
              "vulputate libero et velit interdum, ac...",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "Read More",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfo("Rating", "★ 4.8"),
                  _buildInfo("Inquiries", "25"),
                  _buildInfo("Views", "75"),
                  _buildInfo("Followers", "50k"),
                  _buildInfo("Joined", "1/1/2024"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  Widget _buildTag(String text,
      {Color color = const Color(0xfff1f1f1),
      Color textColor = Colors.black87}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: textColor),
      ),
    );
  }
}
