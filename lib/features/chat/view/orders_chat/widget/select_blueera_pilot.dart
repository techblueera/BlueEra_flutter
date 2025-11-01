import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DeliveryPilotScreen extends StatefulWidget {
  const DeliveryPilotScreen({super.key});

  @override
  State<DeliveryPilotScreen> createState() => _DeliveryPilotScreenState();
}

class _DeliveryPilotScreenState extends State<DeliveryPilotScreen> {
  List<Map<String, dynamic>> pilots = [
    {
      "name": "Sanjib Sarkar",
      "distance": "1.2 km",
      "rating": 4.8,
      "reviews": 48,
      "orders": "2.5K Orders",
      "image":
      "https://images.unsplash.com/photo-1607746882042-944635dfe10e?auto=format&fit=crop&w=600&q=60",
    },
    {
      "name": "Sanjib Sarkar",
      "distance": "1.2 km",
      "rating": 4.8,
      "reviews": 48,
      "orders": "2.5K Orders",
      "image":
      "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=600&q=60",
    },
    {
      "name": "Sanjib Sarkar",
      "distance": "1.2 km",
      "rating": 4.8,
      "reviews": 48,
      "orders": "2.5K Orders",
      "image":
      "https://images.unsplash.com/photo-1595152772835-219674b2a8a6?auto=format&fit=crop&w=600&q=60",
    },
    {
      "name": "Sanjib Sarkar",
      "distance": "1.2 km",
      "rating": 4.8,
      "reviews": 48,
      "orders": "2.5K Orders",
      "image":
      "https://images.unsplash.com/photo-1603415526960-f7e0328c63b1?auto=format&fit=crop&w=600&q=60",
    },
  ];

  Set<int> selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: "Delivery Pilot Near to Gupta General Store",
      ),
      body: Column(
        children: [
          // Map section
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(10),
          //   child: Image.asset(
          //     "assets/map_sample.png", // replace with your map image
          //     height: 200,
          //     width: double.infinity,
          //     fit: BoxFit.cover,
          //   ),
          // ),
          Container(
            height: 200,
            color: Colors.green,
          ),
           SizedBox(height: SizeConfig.size20),

          // Grid of pilots
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                itemCount: pilots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final pilot = pilots[index];
                  final isSelected = selectedIndexes.contains(index);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIndexes.remove(index);
                        } else {
                          selectedIndexes.add(index);
                        }
                      });
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.network(
                                  pilot["image"],
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      pilot["name"],

                                          fontSize: 14,
                                          fontWeight: FontWeight.w600
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(CupertinoIcons.location,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        CustomText(
                                          pilot["distance"],

                                              color: Colors.grey,
                                              fontSize: 12),
                                      ],
                                    ),
                                    SizedBox(height: SizeConfig.size4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.orange, size: 14),
                                        CustomText(
                                          " ${pilot["rating"]} (${pilot["reviews"]} reviews)",

                                              color: Colors.grey, fontSize: 12

                                        ),
                                      ],
                                    ),
                                    SizedBox(height: SizeConfig.size4),
                                    CustomText(
                                      pilot["orders"],
                                      // style: const TextStyle(
                                          fontSize: 12, color: Colors.grey
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.check,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Book button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
              child: const Text(
                "Book Delivery Pilot NOW",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
