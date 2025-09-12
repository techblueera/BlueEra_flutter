import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/reel/models/song.dart';

class PhotoPost {
  List<String> photoUrls;
  String description;
  List<String> taggedPeople;
  String natureOfPost;
  SongModel? song;
  SymbolDuration symbol;

  PhotoPost({
    required this.photoUrls,
    this.description = '',
    this.taggedPeople = const [],
    this.natureOfPost = '',
    this.song,
    this.symbol = SymbolDuration.hours24,
  });
}