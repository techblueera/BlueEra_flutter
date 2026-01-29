import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
class PickedImageRow extends StatelessWidget {
  final List<String> images; // picked image paths or urls
  final VoidCallback onAddTap;
  final  Function(String path) onRemove;

  const PickedImageRow({
    super.key,
    required this.images,
    required this.onAddTap, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (int i = 0; i < images.length && i < 4; i++)
          _ImageCard(imagePath: images[i], onRemove: onRemove,),

        /// Add card (always visible)
        if(images.length<5)
        _AddImageCard(onTap: onAddTap),
      ],
    );
  }
}
class _ImageCard extends StatelessWidget {
  final String imagePath;
  final  Function(String path) onRemove;
  const _ImageCard({required this.imagePath, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8, bottom: 11),
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.whiteE5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imagePath.startsWith('http')
                ? Image.network(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            )
                : Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -1,
            right: 10,
            child: InkWell(
                onTap: (){
                  onRemove(imagePath);
                },
                child: Icon(Icons.cancel,color: AppColors.red,)))
      ],
    );
  }
}
class _AddImageCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 72,
        width: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.whiteE5),
        ),
        child:  Center(
          child: Icon(Icons.add, size: 28, color: AppColors.grayText),
        ),
      ),
    );
  }
}
