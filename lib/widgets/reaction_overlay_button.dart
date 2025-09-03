import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ReactionOverlayButton extends StatefulWidget {
  final void Function(int index, bool isLiked)? onReactionTap;
  final int? totals;
  final bool isLiked;
  final int emojiIndex;

  const ReactionOverlayButton({
    this.onReactionTap,
    this.totals,
    this.isLiked = false,
    required this.emojiIndex,
  });

  @override
  _ReactionOverlayButtonState createState() => _ReactionOverlayButtonState();
}

class _ReactionOverlayButtonState extends State<ReactionOverlayButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  // late List<EmojiReaction> _reactions;

  // void _showOverlay() {
  //   final overlay = Overlay.of(context);
  //
  //   _overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       width: MediaQuery.of(context).size.width,
  //       child: CompositedTransformFollower(
  //         link: _layerLink,
  //         showWhenUnlinked: false,
  //         offset: Offset(-20, -50), // adjust Y offset to position above button
  //         child: Material(
  //           color: Colors.transparent,
  //           child: Padding(
  //             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
  //             child: SingleChildScrollView(
  //               scrollDirection: Axis.horizontal,
  //               child: Container(
  //                 padding: EdgeInsets.all(8.0),
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(8.0),
  //                   color: AppColors.black28,
  //                 ),
  //                 child: Row(
  //                   children: List.generate(
  //                     _reactions.length,
  //                         (index) => InkWell(
  //                       onTap: () {
  //                         _hideOverlay();
  //                         widget.onReactionTap?.call(index, widget.isLiked);
  //                       },
  //                       child: Padding(
  //                         padding: const EdgeInsets.symmetric(horizontal: 8.0),
  //                         child: _reactions[index].emoji,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   overlay.insert(_overlayEntry!);
  // }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void initState() {

    super.initState();
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: () {
          // if(!widget.isLiked){
          //   if (_overlayEntry == null) {
          //     _showOverlay();
          //   } else {
          //     _hideOverlay();
          //   }
          // }else{
          //   _hideOverlay();
          //   widget.onReactionTap?.call(-1, widget.isLiked);
          // }
        },
        child: Row(
          children: [
            if (widget.totals != null) ...[
              CustomText(
                "${widget.totals}",
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
              ),
              SizedBox(width: SizeConfig.size5),
            ],

            // (widget.emojiIndex != -1) ? _reactions[widget.emojiIndex].emoji : LocalAssets(imagePath: AppIconAssets.likeIcon),
          ],
        ),
      ),
    );
  }
}
