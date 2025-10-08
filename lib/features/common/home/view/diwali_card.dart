import 'package:flutter/material.dart';



class DiwaliOfferCardScreen extends StatelessWidget {
  const DiwaliOfferCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: width * 0.9,
            height: height * 0.7,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/diwali_card/cardbg1.png'),
                fit: BoxFit.fill, // Ensures background covers the container properly
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [

                /// 🔹 Product Title
                Positioned(
                  top: height * 0.18,
                  left: 20,
                  right: 20,
                  child: Text(
                    "iPhone 16 128 GB: 5G\nMobile Phone with Camera Control",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: width * 0.04,
                      height: 1.3,
                    ),
                  ),
                ),

                /// 🔹 MRP + Discount Row
                Positioned(
                  top: height * 0.3,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "MRP: ₹2,40,000",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.035,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              "50%",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.04,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "Off",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: width * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 Our Price Box
                Positioned(
                  top: height * 0.38,
                  left: width * 0.15,
                  right: width * 0.15,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Our Price: ₹1,20,000",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.045,
                      ),
                    ),
                  ),
                ),

                /// 🔹 BlueEra Super App (text only)
                Positioned(
                  top: height * 0.47,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Only On - ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.035,
                        ),
                      ),
                      Text(
                        "BlueEra Super App 🛍️",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 Shop Info
                Positioned(
                  top: height * 0.54,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        "Pervez Mobile Shop",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Ramesh Kumar (Owner)",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.033,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 Visit My Store Button
                Positioned(
                  bottom: height * 0.1,
                  left: width * 0.2,
                  right: width * 0.2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text(
                      "Visit My Store\nVia Link Below",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.04,
                      ),
                    ),
                  ),
                ),

                /// 🔹 Location
                Positioned(
                  bottom: height * 0.04,
                  left: 0,
                  right: 0,
                  child: Text(
                    "📍 Durgapur, West Bengal - Industrial Area",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}
