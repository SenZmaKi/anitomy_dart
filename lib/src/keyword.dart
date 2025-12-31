import 'element.dart';
import 'string_utils.dart';
import 'token.dart';

class KeywordOptions {
  bool identifiable;
  bool searchable;
  bool valid;

  KeywordOptions({
    this.identifiable = true,
    this.searchable = true,
    this.valid = true,
  });
}

class Keyword {
  ElementCategory category;
  KeywordOptions options;

  Keyword(this.category, this.options);
}

class KeywordManager {
  final Map<String, Keyword> _fileExtensions = {};
  final Map<String, Keyword> _keys = {};

  KeywordManager() {
    _initialize();
  }

  void _initialize() {
    final optionsDefault = KeywordOptions();
    final optionsInvalid = KeywordOptions(valid: false);
    final optionsUnidentifiable = KeywordOptions(identifiable: false);
    final optionsUnidentifiableInvalid = KeywordOptions(
      identifiable: false,
      valid: false,
    );
    final optionsUnidentifiableUnsearchable = KeywordOptions(
      identifiable: false,
      searchable: false,
    );

    add(ElementCategory.animeSeasonPrefix, optionsUnidentifiable, [
      'SAISON',
      'SEASON',
    ]);

    add(ElementCategory.animeType, optionsUnidentifiable, [
      'GEKIJOUBAN',
      'MOVIE',
      'OAD',
      'OAV',
      'ONA',
      'OVA',
      'SPECIAL',
      'SPECIALS',
      'TV',
    ]);
    add(ElementCategory.animeType, optionsUnidentifiableUnsearchable, [
      'SP', // e.g. "Yumeiro Patissiere SP Professional"
    ]);
    add(ElementCategory.animeType, optionsUnidentifiableInvalid, [
      'ED',
      'ENDING',
      'NCED',
      'NCOP',
      'OP',
      'OPENING',
      'PREVIEW',
      'PV',
    ]);

    add(ElementCategory.audioTerm, optionsDefault, [
      // Audio channels
      '2.0CH',
      '2CH',
      '5.1',
      '5.1CH',
      '7.1',
      '7.1CH',
      'DD2.0',
      'DD5.1',
      'DD',
      'DTS',
      'DTS-ES',
      'DTS5.1',
      'DOLBY TRUEHD',
      'TRUEHD',
      'TRUEHD5.1',
      // Audio codec
      'AAC',
      'AACX2',
      'AACX3',
      'AACX4',
      'AC3',
      'EAC3',
      'E-AC-3',
      'FLAC',
      'FLACX2',
      'FLACX3',
      'FLACX4',
      'LOSSLESS',
      'MP3',
      'OGG',
      'VORBIS',
      'ATMOS',
      'DOLBY ATMOS',
      // Audio language
      'DUALAUDIO',
      'DUAL AUDIO',
    ]);
    add(ElementCategory.audioTerm, optionsUnidentifiable, [
      'OPUS', // e.g. "Opus.COLORs"
    ]);

    add(ElementCategory.deviceCompatibility, optionsDefault, [
      'IPAD3',
      'IPHONE5',
      'IPOD',
      'PS3',
      'XBOX',
      'XBOX360',
    ]);
    add(ElementCategory.deviceCompatibility, optionsUnidentifiable, [
      'ANDROID',
    ]);

    add(ElementCategory.episodePrefix, optionsDefault, [
      'EP',
      'EP.',
      'EPS',
      'EPS.',
      'EPISODE',
      'EPISODE.',
      'EPISODES',
      'CAPITULO',
      'EPISODIO',
      'EPISÓDIO',
      'FOLGE',
    ]);
    add(ElementCategory.episodePrefix, optionsInvalid, [
      'E',
      '\u7B2C', // Japanese counter
    ]);

    add(ElementCategory.fileExtension, optionsDefault, [
      '3GP',
      'AVI',
      'DIVX',
      'FLV',
      'M2TS',
      'MKV',
      'MOV',
      'MP4',
      'MPG',
      'OGM',
      'RM',
      'RMVB',
      'TS',
      'WEBM',
      'WMV',
    ]);
    add(ElementCategory.fileExtension, optionsInvalid, [
      'AAC',
      'AIFF',
      'FLAC',
      'M4A',
      'MP3',
      'MKA',
      'OGG',
      'WAV',
      'WMA',
      '7Z',
      'RAR',
      'ZIP',
      'ASS',
      'SRT',
    ]);

    add(ElementCategory.language, optionsDefault, [
      'ENG',
      'ENGLISH',
      'ESPANOL',
      'JAP',
      'PT-BR',
      'SPANISH',
      'VOSTFR',
    ]);
    add(ElementCategory.language, optionsUnidentifiable, [
      'ESP', // e.g. "Tokyo ESP"
      'ITA', // e.g. "Bokura ga Ita"
    ]);

    add(ElementCategory.other, optionsDefault, [
      'REMASTER',
      'REMASTERED',
      'UNCENSORED',
      'UNCUT',
      'TS',
      'VFR',
      'WIDESCREEN',
      'WS',
    ]);

    add(ElementCategory.releaseGroup, optionsDefault, ['THORA']);

    add(ElementCategory.releaseInformation, optionsDefault, [
      'BATCH',
      'COMPLETE',
      'PATCH',
      'REMUX',
    ]);
    add(ElementCategory.releaseInformation, optionsUnidentifiable, [
      'END', // e.g. "The End of Evangelion"
      'FINAL', // e.g. "Final Approach"
    ]);

    add(ElementCategory.releaseVersion, optionsDefault, [
      'V0',
      'V1',
      'V2',
      'V3',
      'V4',
    ]);

    add(ElementCategory.source, optionsDefault, [
      'BD',
      'BDRIP',
      'BLURAY',
      'BLU-RAY',
      'DVD',
      'DVD5',
      'DVD9',
      'DVD-R2J',
      'DVDRIP',
      'DVD-RIP',
      'R2DVD',
      'R2J',
      'R2JDVD',
      'R2JDVDRIP',
      'HDTV',
      'HDTVRIP',
      'TVRIP',
      'TV-RIP',
      'WEBCAST',
      'WEBRIP',
    ]);

    add(ElementCategory.subtitles, optionsDefault, [
      'ASS',
      'BIG5',
      'DUB',
      'DUBBED',
      'HARDSUB',
      'HARDSUBS',
      'RAW',
      'SOFTSUB',
      'SOFTSUBS',
      'SUB',
      'SUBBED',
      'SUBTITLED',
      'MULTISUB',
      'MULTI SUB',
    ]);

    add(ElementCategory.videoTerm, optionsDefault, [
      // Frame rate
      '23.976FPS',
      '24FPS',
      '29.97FPS',
      '30FPS',
      '60FPS',
      '120FPS',
      // Video codec
      '8BIT',
      '8-BIT',
      '10BIT',
      '10BITS',
      '10-BIT',
      '10-BITS',
      'HI10',
      'HI10P',
      'HI444',
      'HI444P',
      'HI444PP',
      'HDR',
      'DV',
      'DOLBY VISION',
      'H264',
      'H265',
      'H.264',
      'H.265',
      'X264',
      'X265',
      'X.264',
      'AVC',
      'HEVC',
      'HEVC2',
      'DIVX',
      'DIVX5',
      'DIVX6',
      'XVID',
      'AV1',
      // Video format
      'AVI',
      'RMVB',
      'WMV',
      'WMV3',
      'WMV9',
      // Video quality
      'HQ',
      'LQ',
      // Video resolution
      '4K',
      'HD',
      'SD',
    ]);

    add(ElementCategory.volumePrefix, optionsDefault, [
      'VOL',
      'VOL.',
      'VOLUME',
    ]);
  }

  void add(
    ElementCategory category,
    KeywordOptions options,
    List<String> keywords,
  ) {
    final keys = _getKeywordContainer(category);
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (keys.containsKey(keyword)) continue;
      keys[keyword] = Keyword(category, options);
    }
  }

  bool findCategory(ElementCategory category, String str) {
    final keys = _getKeywordContainer(category);
    final keyword = keys[str];
    return keyword != null && keyword.category == category;
  }

  // Find keyword and return found category and options
  // Returns null if not found, otherwise returns the ElementCategory
  ElementCategory? find(
    String str,
    ElementCategory category,
    KeywordOptions options,
  ) {
    final keys = _getKeywordContainer(category);
    final keyword = keys[str];
    if (keyword != null) {
      ElementCategory foundCategory = keyword.category;
      if (category == ElementCategory.unknown) {
        category = foundCategory;
      } else if (foundCategory != category) {
        return null;
      }
      // Copy options
      options.identifiable = keyword.options.identifiable;
      options.searchable = keyword.options.searchable;
      options.valid = keyword.options.valid;
      return foundCategory;
    }
    return null;
  }

  void peek(
    String filename,
    TokenRange range,
    Elements elements,
    List<TokenRange> preidentifiedTokens,
  ) {
    final entries = <MapEntry<ElementCategory, List<String>>>[
      MapEntry(ElementCategory.audioTerm, ['Dual Audio', 'DualAudio']),
      MapEntry(ElementCategory.videoTerm, ['H264', 'H.264', 'h264', 'h.264']),
      MapEntry(ElementCategory.videoResolution, [
        '480p',
        '720p',
        '1080p',
        '1080i',
        '2160p',
      ]),
      MapEntry(ElementCategory.source, ['Blu-Ray']),
    ];

    final substring = filename.substring(
      range.offset,
      range.offset + range.size,
    );

    for (final entry in entries) {
      for (final keyword in entry.value) {
        final index = substring.indexOf(keyword);
        if (index != -1) {
          final offset = range.offset + index;
          elements.insert(entry.key, keyword);
          preidentifiedTokens.add(
            TokenRange(offset: offset, size: keyword.length),
          );
        }
      }
    }
  }

  String normalize(String str) {
    return stringToUpperCopy(str);
  }

  Map<String, Keyword> _getKeywordContainer(ElementCategory category) {
    return category == ElementCategory.fileExtension ? _fileExtensions : _keys;
  }
}

final keywordManager = KeywordManager();
