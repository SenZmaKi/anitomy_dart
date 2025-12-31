import 'package:anitomy_dart/anitomy.dart';

void main() {
  final anitomy = Anitomy();

  final filename =
      '[TaigaSubs]_Toradora!_(2008)_-_01v2_-_Tiger_and_Dragon_[1280x720_H.264_FLAC][1234ABCD].mkv';

  if (anitomy.parse(filename)) {
    print('Parsed successfully!');
    print('Anime title: ${anitomy.elements.get(ElementCategory.animeTitle)}');
    print(
      'Episode number: ${anitomy.elements.get(ElementCategory.episodeNumber)}',
    );
    print(
      'Release group: ${anitomy.elements.get(ElementCategory.releaseGroup)}',
    );
    print(
      'Video resolution: ${anitomy.elements.get(ElementCategory.videoResolution)}',
    );
  } else {
    print('Failed to parse');
  }
}
