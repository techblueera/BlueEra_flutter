import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Example: Render a feed where most items are single full-width cards,
// but consecutive image_post / short_video items are shown together
// in a 4-column grid inside the list.


// A block is either a single-feed item (normal card) or a grid block containing
// multiple image/video items that should render as a 4-column grid.
class FeedBlock {
  final bool isGrid;
  final List<Post> items;

  FeedBlock({required this.isGrid, required this.items});
}
/*
class MixedFeedView extends StatelessWidget {
  final List<Map<String, dynamic>> rawData;

  MixedFeedView({Key? key, required this.rawData}) : super(key: key);

  List<FeedItem> _parseRaw() {
    return rawData.map((m) => FeedItem.fromMap(m)).toList();
  }

  List<FeedBlock> _buildBlocks(List<FeedItem> items) {
    final List<FeedBlock> blocks = [];
    final Set<String> gridTypes = {'image_post', 'short_video'};

    List<FeedItem> buffer = [];

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        // If only 1 item in buffer we still show it as a single full-width card
        if (buffer.length == 1) {
          blocks.add(FeedBlock(isGrid: false, items: [buffer.first]));
        } else {
          blocks.add(FeedBlock(isGrid: true, items: List.from(buffer)));
        }
        buffer.clear();
      }
    }

    for (final item in items) {
      if (gridTypes.contains(item.type)) {
        buffer.add(item);
        // keep buffering consecutive grid-type items
      } else {
        // encountered a normal item -> flush any grid buffer first
        flushBuffer();
        blocks.add(FeedBlock(isGrid: false, items: [item]));
      }
    }

    // end: flush remaining buffer
    flushBuffer();
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final items = _parseRaw();
    final blocks = _buildBlocks(items);

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding:
          EdgeInsets.only(top: SizeConfig.size2, bottom: SizeConfig.size80),
      itemCount: blocks.length,
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final block = blocks[index];
        if (block.isGrid) {
          // Render a 4-column grid of thumbnails inside the list
          // We use shrinkWrap + NeverScrollableScrollPhysics so ListView handles scrolling
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: block.items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (c, i) {
                final it = block.items[i];
                final thumb = (it.media.isNotEmpty) ? it.media.first : null;
                return GestureDetector(
                  onTap: () {
                    // TODO: open image viewer or play short video
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Open ${it.type}')),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.grey.shade200,
                      child: thumb != null
                          ? CachedNetworkImage(
                              imageUrl: thumb,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, err) =>
                                  Icon(Icons.broken_image),
                            )
                          : Center(child: Icon(Icons.image)),
                    ),
                  ),
                );
              },
            ),
          );
        }

        // Single full-width item
        final item = block.items.first;
        final thumbnail = (item.media.isNotEmpty) ? item.media.first : null;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.title.isNotEmpty)
                  Text(
                    item.title,
                  ),
                if (item.subTitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                    child: Text(item.subTitle,
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                if (thumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: thumbnail,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, err) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('By ${item.raw['user']?['name'] ?? 'Unknown'}'),
                    Row(children: [
                      Icon(Icons.favorite_border),
                      SizedBox(width: 6),
                      Text('${item.raw['likes_count'] ?? 0}')
                    ])
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}*/
