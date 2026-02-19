import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final String? tag; // e.g., "25 Beds" or "Child Specialist"

  const CategoryCard({
    required this.title,
    required this.subtitle,
    required this.description,
    this.imageUrl,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl ?? 'https://via.placeholder.com/150'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Favorite Heart Icon
          Positioned(
            top: 12, right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 15,
              child: Icon(Icons.favorite, color: Colors.red, size: 18),
            ),
          ),
          // Bottom Content Overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  if (tag != null)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text(tag!, style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}