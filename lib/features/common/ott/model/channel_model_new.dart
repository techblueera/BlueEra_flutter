import 'dart:ui';

class ChannelModelNew {
  final String name;
  final String imageUrl;
  final Color color;

  ChannelModelNew(this.name, this.imageUrl, this.color);
}


class VideoModel {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String channelIcon;
  final String views;
  final bool isLive;

  VideoModel({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.channelIcon,
    this.views = "27K views • 1 day ago",
    this.isLive = false,
  });
}