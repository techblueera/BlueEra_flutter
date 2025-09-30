import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ProductSlider extends StatelessWidget {
  final List<Map<String, dynamic>> products = [
    {
      'title': 'Nike Fashion Shoe',
      'price': '₹61,499',
      'oldPrice': '₹98,000',
      'discount': '50% Off',
      'colors': [Colors.black, Colors.white, Colors.red, Colors.blue, Colors.yellow, Colors.green],
      'sizes': ['7UK', '8UK', '9UK', '+2'],
      'image': 'assets/shoe.jpg',
    },
    {
      'title': 'Adidas Stylish Running Shoe',
      'price': '₹12,999',
      'oldPrice': '₹20,000',
      'discount': '35% Off',
      'colors': [Colors.black, Colors.grey, Colors.red],
      'sizes': ['6UK', '7UK', '8UK'],
      'image': 'assets/shoe.jpg',
    }, {
      'title': 'Nike Fashion Shoe',
      'price': '₹61,499',
      'oldPrice': '₹98,000',
      'discount': '50% Off',
      'colors': [Colors.black, Colors.white, Colors.red, Colors.blue, Colors.yellow, Colors.green],
      'sizes': ['7UK', '8UK', '9UK', '+2'],
      'image': 'assets/shoe.jpg',
    },
    {
      'title': 'Adidas Stylish Running Shoe',
      'price': '₹12,999',
      'oldPrice': '₹20,000',
      'discount': '35% Off',
      'colors': [Colors.black, Colors.grey, Colors.red],
      'sizes': ['6UK', '7UK', '8UK'],
      'image': 'assets/shoe.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: 210,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            height: 280,
            width: MediaQuery.of(context).size.width * 0.45, // responsive width
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: DecorationImage(
                      image: NetworkImage("https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/9808e857-576f-4ab3-8125-8f6d70bff1ef/NIKE+AIR+WINFLO+11+WIDE.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Title & price
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          product['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 4),

                        Flexible(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product['price'],
                                  maxLines: 1,

                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                 " product['oldPrice']",
                                  maxLines: 1,

                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  product['discount'],
                                  maxLines: 1,

                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
