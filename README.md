# Anitomy Dart

A Dart port of [anitomy](https://github.com/erengy/anitomy/tree/master), a C++ library for parsing anime video filenames.

## Disclaimer

This project is heavily vibe coded. Porting a C++ library to Dart is a task AI should handle well, since both languages are C style and the transition is from a lower level language to a higher level one. The model used for this port was Claude Sonnet 4.5.

## Usage

```dart
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
```

## Tests

The project achieves and surpasses test parity with the original C++ library, with an 87.5% success rate compared to the original’s 80.22%. A detailed test report can be found [here](https://github.com/senzmaki/anitomy_dart/blob/main/test/REPORT.md).

## License

Anitomy Dart is licensed under the MIT License. See the [LICENSE](https://github.com/senzmaki/anitomy_dart/blob/main/LICENSE) file for more information.

## Contributing

Contributions are welcome. Please open an issue or submit a pull request if you have suggestions or improvements.
