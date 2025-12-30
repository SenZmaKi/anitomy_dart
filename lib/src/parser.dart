import 'element.dart';
import 'keyword.dart';
import 'options.dart';
import 'string_utils.dart';
import 'token.dart';

class Parser {
  final Elements _elements;
  final Options _options;
  final List<Token> _tokens;

  bool _foundEpisodeKeywords = false;

  static const int kAnimeYearMin = 1900;
  static const int kAnimeYearMax = 2050;
  static const int kEpisodeNumberMax = kAnimeYearMin - 1;
  static const int kVolumeNumberMax = 20;

  static const String kDashes = '-\u2010\u2011\u2012\u2013\u2014\u2015';
  static const String kDashesWithSpace =
      ' -\u2010\u2011\u2012\u2013\u2014\u2015';

  Parser(this._elements, this._options, this._tokens);

  bool parse() {
    _searchForKeywords();

    _searchForIsolatedNumbers();

    if (_options.parseEpisodeNumber) {
      _searchForEpisodeNumber();
    }

    _searchForAnimeTitle();

    if (_options.parseReleaseGroup &&
        _elements.emptyCategory(ElementCategory.releaseGroup)) {
      _searchForReleaseGroup();
    }

    if (_options.parseEpisodeTitle &&
        !_elements.emptyCategory(ElementCategory.episodeNumber)) {
      _searchForEpisodeTitle();
    }

    _validateElements();

    return !_elements.emptyCategory(ElementCategory.animeTitle);
  }

  // ============================================================================
  // Keyword Search
  // ============================================================================

  void _searchForKeywords() {
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];

      if (token.category != TokenCategory.unknown) continue;

      var word = token.content;
      word = trimString(word, ' -');

      if (word.isEmpty) continue;
      // Don't bother if the word is a number that cannot be CRC
      if (word.length != 8 && isNumericString(word)) continue;

      // Performs better than making a case-insensitive Find
      final keyword = keywordManager.normalize(word);
      var category = ElementCategory.unknown;
      final options = KeywordOptions();

      final foundCategory = keywordManager.find(keyword, category, options);
      if (foundCategory != null) {
        category = foundCategory;
        if (!_options.parseReleaseGroup &&
            category == ElementCategory.releaseGroup) {
          continue;
        }
        if (!_isElementCategorySearchable(category) || !options.searchable) {
          continue;
        }
        if (_isElementCategorySingular(category) &&
            !_elements.emptyCategory(category)) {
          continue;
        }
        if (category == ElementCategory.animeSeasonPrefix) {
          _checkAnimeSeasonKeyword(i);
          continue;
        } else if (category == ElementCategory.episodePrefix) {
          if (options.valid) {
            _checkExtentKeyword(ElementCategory.episodeNumber, i);
          }
          continue;
        } else if (category == ElementCategory.releaseVersion) {
          word = word.substring(1); // number without "v"
        } else if (category == ElementCategory.volumePrefix) {
          _checkExtentKeyword(ElementCategory.volumeNumber, i);
          continue;
        }
      } else {
        if (_elements.emptyCategory(ElementCategory.fileChecksum) &&
            _isCrc32(word)) {
          category = ElementCategory.fileChecksum;
        } else if (_elements.emptyCategory(ElementCategory.videoResolution) &&
            _isResolution(word)) {
          category = ElementCategory.videoResolution;
        }
      }

      if (category != ElementCategory.unknown) {
        _elements.insert(category, word);
        if (options.identifiable) {
          _tokens[i].category = TokenCategory.identifier;
        }
      }
    }
  }

  // ============================================================================
  // Episode Number Search
  // ============================================================================

  void _searchForEpisodeNumber() {
    // List all unknown tokens that contain a number
    final tokens = <int>[];
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (token.category == TokenCategory.unknown) {
        if (_findNumberInString(token.content) != -1) {
          tokens.add(i);
        }
      }
    }
    if (tokens.isEmpty) return;

    _foundEpisodeKeywords = !_elements.emptyCategory(
      ElementCategory.episodeNumber,
    );

    // If a token matches a known episode pattern, it has to be the episode number
    if (_searchForEpisodePatterns(tokens)) return;

    if (!_elements.emptyCategory(ElementCategory.episodeNumber)) {
      return; // We have previously found an episode number via keywords
    }

    // From now on, we're only interested in numeric tokens
    tokens.removeWhere((index) => !isNumericString(_tokens[index].content));

    if (tokens.isEmpty) return;

    // e.g. "01 (176)", "29 (04)"
    if (_searchForEquivalentNumbers(tokens)) return;

    // e.g. " - 08"
    if (_searchForSeparatedNumbers(tokens)) return;

    // e.g. "[12]", "(2006)"
    if (_searchForIsolatedNumbersInTokens(tokens)) return;

    // Consider using the last number as a last resort
    _searchForLastNumber(tokens);
  }

  // ============================================================================
  // Anime Title Search
  // ============================================================================

  void _searchForAnimeTitle() {
    bool enclosedTitle = false;

    // Find the first non-enclosed unknown token
    var tokenBegin = findToken(
      _tokens,
      0,
      TokenFlags.flagNotEnclosed | TokenFlags.flagUnknown,
    );

    // If that doesn't work, find the first unknown token in the second enclosed
    // group, assuming that the first one is the release group
    if (tokenBegin == -1) {
      enclosedTitle = true;
      tokenBegin = 0;
      bool skippedPreviousGroup = false;

      while (tokenBegin < _tokens.length) {
        tokenBegin = findToken(_tokens, tokenBegin, TokenFlags.flagUnknown);
        if (tokenBegin == -1) break;

        // Ignore groups that are composed of non-Latin characters
        if (isMostlyLatinString(_tokens[tokenBegin].content)) {
          if (skippedPreviousGroup) break; // Found it
        }

        // Get the first unknown token of the next group
        tokenBegin = findToken(_tokens, tokenBegin, TokenFlags.flagBracket);
        if (tokenBegin == -1) break;
        tokenBegin = findToken(_tokens, tokenBegin + 1, TokenFlags.flagUnknown);
        skippedPreviousGroup = true;
      }
    }
    if (tokenBegin == -1) return;

    // Continue until an identifier (or a bracket, if the title is enclosed)
    // is found
    var tokenEnd = findToken(
      _tokens,
      tokenBegin,
      TokenFlags.flagIdentifier | (enclosedTitle ? TokenFlags.flagBracket : 0),
    );
    if (tokenEnd == -1) {
      tokenEnd = _tokens.length;
    }

    // If within the interval there's an open bracket without its matching pair,
    // move the upper endpoint back to the bracket
    if (!enclosedTitle) {
      var lastBracket = tokenEnd;
      bool bracketOpen = false;
      for (var i = tokenBegin; i < tokenEnd; i++) {
        if (_tokens[i].category == TokenCategory.bracket) {
          lastBracket = i;
          bracketOpen = !bracketOpen;
        }
      }
      if (bracketOpen) {
        tokenEnd = lastBracket;
      }
    }

    // If the interval ends with an enclosed group (e.g. "Anime Title [Fansub]"),
    // move the upper endpoint back to the beginning of the group. We ignore
    // parentheses in order to keep certain groups (e.g. "(TV)") intact.
    if (!enclosedTitle) {
      var token = findPreviousToken(
        _tokens,
        tokenEnd,
        TokenFlags.flagNotDelimiter,
      );
      while (token != -1 &&
          _checkTokenCategory(token, TokenCategory.bracket) &&
          _tokens[token].content[0] != ')') {
        token = findPreviousToken(_tokens, token, TokenFlags.flagBracket);
        if (token != -1) {
          tokenEnd = token;
          token = findPreviousToken(
            _tokens,
            tokenEnd,
            TokenFlags.flagNotDelimiter,
          );
        }
      }
    }

    // Build anime title
    _buildElement(ElementCategory.animeTitle, false, tokenBegin, tokenEnd);
  }

  // ============================================================================
  // Release Group Search
  // ============================================================================

  void _searchForReleaseGroup() {
    var tokenBegin = 0;
    var tokenEnd = 0;

    while (tokenBegin < _tokens.length) {
      // Find the first enclosed unknown token
      tokenBegin = findToken(
        _tokens,
        tokenEnd,
        TokenFlags.flagEnclosed | TokenFlags.flagUnknown,
      );
      if (tokenBegin == -1) return;

      // Continue until a bracket or identifier is found
      tokenEnd = findToken(
        _tokens,
        tokenBegin,
        TokenFlags.flagBracket | TokenFlags.flagIdentifier,
      );
      if (tokenEnd == -1) tokenEnd = _tokens.length;

      if (tokenEnd < _tokens.length &&
          _tokens[tokenEnd].category != TokenCategory.bracket) {
        continue;
      }

      // Ignore if it's not the first non-delimiter token in group
      final previousToken = findPreviousToken(
        _tokens,
        tokenBegin,
        TokenFlags.flagNotDelimiter,
      );
      if (previousToken != -1 &&
          _tokens[previousToken].category != TokenCategory.bracket) {
        continue;
      }

      // Build release group
      _buildElement(ElementCategory.releaseGroup, true, tokenBegin, tokenEnd);
      return;
    }
  }

  // ============================================================================
  // Episode Title Search
  // ============================================================================

  void _searchForEpisodeTitle() {
    var tokenBegin = 0;
    var tokenEnd = 0;

    while (tokenBegin < _tokens.length) {
      // Find the first non-enclosed unknown token
      tokenBegin = findToken(
        _tokens,
        tokenEnd,
        TokenFlags.flagNotEnclosed | TokenFlags.flagUnknown,
      );
      if (tokenBegin == -1) return;

      // Continue until a bracket or identifier is found
      tokenEnd = findToken(
        _tokens,
        tokenBegin,
        TokenFlags.flagBracket | TokenFlags.flagIdentifier,
      );
      if (tokenEnd == -1) tokenEnd = _tokens.length;

      // Ignore if it's only a dash
      if (tokenEnd - tokenBegin <= 2 &&
          _isDashCharacter(_tokens[tokenBegin].content)) {
        continue;
      }

      // Build episode title
      _buildElement(ElementCategory.episodeTitle, false, tokenBegin, tokenEnd);
      return;
    }
  }

  // ============================================================================
  // Isolated Numbers Search
  // ============================================================================

  void _searchForIsolatedNumbers() {
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (token.category != TokenCategory.unknown ||
          !isNumericString(token.content) ||
          !_isTokenIsolated(i)) {
        continue;
      }

      final number = stringToInt(token.content);

      // Anime year
      if (number >= kAnimeYearMin && number <= kAnimeYearMax) {
        if (_elements.emptyCategory(ElementCategory.animeYear)) {
          _elements.insert(ElementCategory.animeYear, token.content);
          _tokens[i].category = TokenCategory.identifier;
          continue;
        }
      }

      // Video resolution
      if (number == 480 || number == 720 || number == 1080) {
        // If these numbers are isolated, it's more likely for them to be the
        // video resolution rather than the episode number. Some fansub groups
        // use these without the "p" suffix.
        if (_elements.emptyCategory(ElementCategory.videoResolution)) {
          _elements.insert(ElementCategory.videoResolution, token.content);
          _tokens[i].category = TokenCategory.identifier;
          continue;
        }
      }
    }
  }

  bool _searchForIsolatedNumbersInTokens(List<int> tokens) {
    for (final tokenIndex in tokens) {
      final token = _tokens[tokenIndex];

      if (!token.enclosed || !_isTokenIsolated(tokenIndex)) {
        continue;
      }

      if (_setEpisodeNumber(token.content, tokenIndex, true)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================================
  // Validation
  // ============================================================================

  void _validateElements() {
    // Validate anime type and episode title
    if (!_elements.emptyCategory(ElementCategory.animeType) &&
        !_elements.emptyCategory(ElementCategory.episodeTitle)) {
      // Here we check whether the episode title contains an anime type
      final episodeTitle = _elements.get(ElementCategory.episodeTitle);

      for (var i = 0; i < _elements.length; i++) {
        final element = _elements.at(i);
        if (element.category == ElementCategory.animeType) {
          if (isInString(episodeTitle, element.value)) {
            if (episodeTitle.length == element.value.length) {
              _elements.erase(
                ElementCategory.episodeTitle,
              ); // invalid episode title
            } else {
              final keyword = keywordManager.normalize(element.value);
              if (keywordManager.findCategory(
                ElementCategory.animeType,
                keyword,
              )) {
                _elements.erase(
                  ElementCategory.animeType,
                ); // invalid anime type
                break;
              }
            }
          }
        }
      }
    }
  }

  // ============================================================================
  // Helper Methods (to be continued in next section)
  // ============================================================================

  bool _checkTokenCategory(int tokenIndex, TokenCategory category) {
    return tokenIndex >= 0 &&
        tokenIndex < _tokens.length &&
        _tokens[tokenIndex].category == category;
  }

  bool _isTokenIsolated(int tokenIndex) {
    final previousToken = findPreviousToken(
      _tokens,
      tokenIndex,
      TokenFlags.flagNotDelimiter,
    );
    if (!_checkTokenCategory(previousToken, TokenCategory.bracket)) {
      return false;
    }

    final nextToken = findNextToken(
      _tokens,
      tokenIndex,
      TokenFlags.flagNotDelimiter,
    );
    if (!_checkTokenCategory(nextToken, TokenCategory.bracket)) {
      return false;
    }

    return true;
  }

  void _buildElement(
    ElementCategory category,
    bool keepDelimiters,
    int tokenBegin,
    int tokenEnd,
  ) {
    final element = StringBuffer();

    for (var i = tokenBegin; i < tokenEnd; i++) {
      final token = _tokens[i];

      switch (token.category) {
        case TokenCategory.unknown:
          element.write(token.content);
          _tokens[i].category = TokenCategory.identifier;
          break;
        case TokenCategory.bracket:
          element.write(token.content);
          break;
        case TokenCategory.delimiter:
          final delimiter = token.content[0];
          if (keepDelimiters) {
            element.write(delimiter);
          } else if (i != tokenBegin && i != tokenEnd - 1) {
            switch (delimiter) {
              case ',':
              case '&':
                element.write(delimiter);
                break;
              default:
                element.write(' ');
                break;
            }
          }
          break;
        default:
          break;
      }
    }

    var result = element.toString();
    if (!keepDelimiters) {
      result = trimString(result, kDashesWithSpace);
    }

    // Trim brackets from release group names
    if (category == ElementCategory.releaseGroup) {
      result = trimString(result, ' []{}()');
    }

    if (result.isNotEmpty) {
      _elements.insert(category, result);
    }
  }

  int _findNumberInString(String str) {
    for (var i = 0; i < str.length; i++) {
      if (isNumericChar(str[i])) {
        return i;
      }
    }
    return -1;
  }

  String _getNumberFromOrdinal(String word) {
    const ordinals = {
      '1st': '1',
      'First': '1',
      '2nd': '2',
      'Second': '2',
      '3rd': '3',
      'Third': '3',
      '4th': '4',
      'Fourth': '4',
      '5th': '5',
      'Fifth': '5',
      '6th': '6',
      'Sixth': '6',
      '7th': '7',
      'Seventh': '7',
      '8th': '8',
      'Eighth': '8',
      '9th': '9',
      'Ninth': '9',
    };

    return ordinals[word] ?? '';
  }

  bool _isCrc32(String str) {
    return str.length == 8 && isHexadecimalString(str);
  }

  bool _isDashCharacter(String str) {
    if (str.length != 1) return false;
    return kDashes.contains(str[0]);
  }

  bool _isResolution(String str) {
    const minWidthSize = 3;
    const minHeightSize = 3;

    // *###x###*
    if (str.length >= minWidthSize + 1 + minHeightSize) {
      final xChars = ['x', 'X', '\u00D7']; // multiplication sign
      var pos = -1;
      for (final xChar in xChars) {
        pos = str.indexOf(xChar);
        if (pos != -1) break;
      }

      if (pos != -1 &&
          pos >= minWidthSize &&
          pos <= str.length - (minHeightSize + 1)) {
        for (var i = 0; i < str.length; i++) {
          if (i != pos && !isNumericChar(str[i])) {
            return false;
          }
        }
        return true;
      }

      // *###p
    } else if (str.length >= minHeightSize + 1) {
      final lastChar = str[str.length - 1];
      if (lastChar == 'p' || lastChar == 'P') {
        for (var i = 0; i < str.length - 1; i++) {
          if (!isNumericChar(str[i])) {
            return false;
          }
        }
        return true;
      }
    }

    return false;
  }

  bool _checkAnimeSeasonKeyword(int tokenIndex) {
    final setAnimeSeason = (int first, int second, String content) {
      _elements.insert(ElementCategory.animeSeason, content);
      _tokens[first].category = TokenCategory.identifier;
      _tokens[second].category = TokenCategory.identifier;
    };

    final previousToken = findPreviousToken(
      _tokens,
      tokenIndex,
      TokenFlags.flagNotDelimiter,
    );
    if (previousToken != -1) {
      final number = _getNumberFromOrdinal(_tokens[previousToken].content);
      if (number.isNotEmpty) {
        setAnimeSeason(previousToken, tokenIndex, number);
        return true;
      }
    }

    final nextToken = findNextToken(
      _tokens,
      tokenIndex,
      TokenFlags.flagNotDelimiter,
    );
    if (nextToken != -1 && isNumericString(_tokens[nextToken].content)) {
      setAnimeSeason(tokenIndex, nextToken, _tokens[nextToken].content);
      return true;
    }

    return false;
  }

  bool _checkExtentKeyword(ElementCategory category, int tokenIndex) {
    final nextToken = findNextToken(
      _tokens,
      tokenIndex,
      TokenFlags.flagNotDelimiter,
    );

    if (_checkTokenCategory(nextToken, TokenCategory.unknown)) {
      if (_findNumberInString(_tokens[nextToken].content) == 0) {
        switch (category) {
          case ElementCategory.episodeNumber:
            if (!_matchEpisodePatterns(_tokens[nextToken].content, nextToken)) {
              _setEpisodeNumber(_tokens[nextToken].content, nextToken, false);
            }
            break;
          case ElementCategory.volumeNumber:
            if (!_matchVolumePatterns(_tokens[nextToken].content, nextToken)) {
              _setVolumeNumber(_tokens[nextToken].content, nextToken, false);
            }
            break;
          default:
            return false;
        }
        _tokens[tokenIndex].category = TokenCategory.identifier;
        return true;
      }
    }

    return false;
  }

  bool _isElementCategorySearchable(ElementCategory category) {
    switch (category) {
      case ElementCategory.animeSeasonPrefix:
      case ElementCategory.animeType:
      case ElementCategory.audioTerm:
      case ElementCategory.deviceCompatibility:
      case ElementCategory.episodePrefix:
      case ElementCategory.fileChecksum:
      case ElementCategory.language:
      case ElementCategory.other:
      case ElementCategory.releaseGroup:
      case ElementCategory.releaseInformation:
      case ElementCategory.releaseVersion:
      case ElementCategory.source:
      case ElementCategory.subtitles:
      case ElementCategory.videoResolution:
      case ElementCategory.videoTerm:
      case ElementCategory.volumePrefix:
        return true;
      default:
        return false;
    }
  }

  bool _isElementCategorySingular(ElementCategory category) {
    switch (category) {
      case ElementCategory.animeSeason:
      case ElementCategory.animeType:
      case ElementCategory.audioTerm:
      case ElementCategory.deviceCompatibility:
      case ElementCategory.episodeNumber:
      case ElementCategory.language:
      case ElementCategory.other:
      case ElementCategory.releaseInformation:
      case ElementCategory.source:
      case ElementCategory.videoTerm:
        return false;
      default:
        return true;
    }
  }

  // ============================================================================
  // Episode Pattern Matching - Episode Number Methods
  // ============================================================================

  bool _isValidEpisodeNumber(String number) {
    return stringToInt(number) <= kEpisodeNumberMax;
  }

  bool _setEpisodeNumber(String number, int tokenIndex, bool validate) {
    if (validate && !_isValidEpisodeNumber(number)) {
      return false;
    }

    _tokens[tokenIndex].category = TokenCategory.identifier;

    var category = ElementCategory.episodeNumber;

    // Handle equivalent numbers
    if (_foundEpisodeKeywords) {
      for (var i = 0; i < _elements.length; i++) {
        final element = _elements.at(i);
        if (element.category != ElementCategory.episodeNumber) continue;

        // The larger number gets to be the alternative one
        final comparison = stringToInt(number) - stringToInt(element.value);
        if (comparison > 0) {
          category = ElementCategory.episodeNumberAlt;
        } else if (comparison < 0) {
          _elements.at(i).category = ElementCategory.episodeNumberAlt;
        } else {
          return false; // No need to add the same number twice
        }
        break;
      }
    }

    _elements.insert(category, number);
    return true;
  }

  bool _setAlternativeEpisodeNumber(String number, int tokenIndex) {
    _elements.insert(ElementCategory.episodeNumberAlt, number);
    _tokens[tokenIndex].category = TokenCategory.identifier;
    return true;
  }

  bool _isValidVolumeNumber(String number) {
    return stringToInt(number) <= kVolumeNumberMax;
  }

  bool _setVolumeNumber(String number, int tokenIndex, bool validate) {
    if (validate && !_isValidVolumeNumber(number)) {
      return false;
    }

    _elements.insert(ElementCategory.volumeNumber, number);
    _tokens[tokenIndex].category = TokenCategory.identifier;
    return true;
  }

  bool _numberComesAfterPrefix(ElementCategory category, int tokenIndex) {
    final token = _tokens[tokenIndex];
    final numberBegin = _findNumberInString(token.content);
    if (numberBegin == -1) return false;

    final prefix = keywordManager.normalize(
      token.content.substring(0, numberBegin),
    );

    if (keywordManager.findCategory(category, prefix)) {
      final number = token.content.substring(numberBegin);
      switch (category) {
        case ElementCategory.episodePrefix:
          if (!_matchEpisodePatterns(number, tokenIndex)) {
            _setEpisodeNumber(number, tokenIndex, false);
          }
          return true;
        case ElementCategory.volumePrefix:
          if (!_matchVolumePatterns(number, tokenIndex)) {
            _setVolumeNumber(number, tokenIndex, false);
          }
          return true;
        default:
          break;
      }
    }

    return false;
  }

  bool _numberComesBeforeAnotherNumber(int tokenIndex) {
    final separatorToken = findNextToken(
      _tokens,
      tokenIndex,
      TokenFlags.flagNotDelimiter,
    );

    if (separatorToken != -1) {
      const separators = [
        ['&', true],
        ['of', false],
      ];

      for (final separator in separators) {
        if (isStringEqualTo(
          _tokens[separatorToken].content,
          separator[0] as String,
        )) {
          final otherToken = findNextToken(
            _tokens,
            separatorToken,
            TokenFlags.flagNotDelimiter,
          );
          if (otherToken != -1 &&
              isNumericString(_tokens[otherToken].content)) {
            _setEpisodeNumber(_tokens[tokenIndex].content, tokenIndex, false);
            if (separator[1] as bool) {
              _setEpisodeNumber(_tokens[otherToken].content, otherToken, false);
            }
            _tokens[separatorToken].category = TokenCategory.identifier;
            _tokens[otherToken].category = TokenCategory.identifier;
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _searchForEpisodePatterns(List<int> tokens) {
    for (final tokenIndex in tokens) {
      final token = _tokens[tokenIndex];
      final numericFront = isNumericChar(token.content[0]);

      if (!numericFront) {
        // e.g. "EP.1", "Vol.1"
        if (_numberComesAfterPrefix(
          ElementCategory.episodePrefix,
          tokenIndex,
        )) {
          return true;
        }
        if (_numberComesAfterPrefix(ElementCategory.volumePrefix, tokenIndex)) {
          continue;
        }
      } else {
        // e.g. "8 & 10", "01 of 24"
        if (_numberComesBeforeAnotherNumber(tokenIndex)) {
          return true;
        }
      }
      // Look for other patterns
      if (_matchEpisodePatterns(token.content, tokenIndex)) {
        return true;
      }
    }

    return false;
  }

  bool _matchSingleEpisodePattern(String word, int tokenIndex) {
    final pattern = RegExp(r'(\d{1,4})[vV](\d)');
    final match = pattern.firstMatch(word);

    if (match != null) {
      _setEpisodeNumber(match.group(1)!, tokenIndex, false);
      _elements.insert(ElementCategory.releaseVersion, match.group(2)!);
      return true;
    }

    return false;
  }

  bool _matchMultiEpisodePattern(String word, int tokenIndex) {
    final pattern = RegExp(
      r'(\d{1,4})(?:[vV](\d))?[-~&+](\d{1,4})(?:[vV](\d))?',
    );
    final match = pattern.firstMatch(word);

    if (match != null) {
      final lowerBound = match.group(1)!;
      final upperBound = match.group(3)!;
      // Avoid matching expressions such as "009-1" or "5-2"
      if (stringToInt(lowerBound) < stringToInt(upperBound)) {
        if (_setEpisodeNumber(lowerBound, tokenIndex, true)) {
          _setEpisodeNumber(upperBound, tokenIndex, false);
          if (match.group(2) != null) {
            _elements.insert(ElementCategory.releaseVersion, match.group(2)!);
          }
          if (match.group(4) != null) {
            _elements.insert(ElementCategory.releaseVersion, match.group(4)!);
          }
          return true;
        }
      }
    }

    return false;
  }

  bool _matchSeasonAndEpisodePattern(String word, int tokenIndex) {
    final pattern = RegExp(
      r'S?(\d{1,2})(?:-S?(\d{1,2}))?(?:x|[ ._-x]?E)(\d{1,4})(?:-E?(\d{1,4}))?(?:[vV](\d))?',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(word);

    if (match != null) {
      if (stringToInt(match.group(1)!) == 0) {
        return false;
      }
      _elements.insert(ElementCategory.animeSeason, match.group(1)!);
      if (match.group(2) != null) {
        _elements.insert(ElementCategory.animeSeason, match.group(2)!);
      }
      _setEpisodeNumber(match.group(3)!, tokenIndex, false);
      if (match.group(4) != null) {
        _setEpisodeNumber(match.group(4)!, tokenIndex, false);
      }
      return true;
    }

    return false;
  }

  bool _matchTypeAndEpisodePattern(String word, int tokenIndex) {
    final numberBegin = _findNumberInString(word);
    if (numberBegin == -1) return false;

    final prefix = word.substring(0, numberBegin);

    var category = ElementCategory.animeType;
    final options = KeywordOptions();

    final foundCategory = keywordManager.find(
      keywordManager.normalize(prefix),
      category,
      options,
    );
    if (foundCategory != null) {
      category = foundCategory;
      _elements.insert(ElementCategory.animeType, prefix);
      final number = word.substring(numberBegin);
      if (_matchEpisodePatterns(number, tokenIndex) ||
          _setEpisodeNumber(number, tokenIndex, true)) {
        // Split token
        _tokens[tokenIndex].content = number;
        _tokens.insert(
          tokenIndex,
          Token(
            category: options.identifiable
                ? TokenCategory.identifier
                : TokenCategory.unknown,
            content: prefix,
            enclosed: _tokens[tokenIndex].enclosed,
          ),
        );
        return true;
      }
    }

    return false;
  }

  bool _matchFractionalEpisodePattern(String word, int tokenIndex) {
    // We don't allow any fractional part other than ".5"
    final pattern = RegExp(r'\d+\.5');

    if (pattern.hasMatch(word)) {
      if (_setEpisodeNumber(word, tokenIndex, true)) {
        return true;
      }
    }

    return false;
  }

  bool _matchPartialEpisodePattern(String word, int tokenIndex) {
    var suffixStart = 0;
    for (var i = 0; i < word.length; i++) {
      if (!isNumericChar(word[i])) {
        suffixStart = i;
        break;
      }
    }

    final suffixLength = word.length - suffixStart;

    bool isValidSuffix(String char) {
      final code = char.codeUnitAt(0);
      return (code >= 0x41 && code <= 0x43) || // A-C
          (code >= 0x61 && code <= 0x63); // a-c
    }

    if (suffixLength == 1 &&
        suffixStart < word.length &&
        isValidSuffix(word[suffixStart])) {
      if (_setEpisodeNumber(word, tokenIndex, true)) {
        return true;
      }
    }

    return false;
  }

  bool _matchNumberSignPattern(String word, int tokenIndex) {
    if (word.isEmpty || word[0] != '#') return false;

    final pattern = RegExp(r'#(\d{1,4})(?:[-~&+](\d{1,4}))?(?:[vV](\d))?');
    final match = pattern.firstMatch(word);

    if (match != null) {
      if (_setEpisodeNumber(match.group(1)!, tokenIndex, true)) {
        if (match.group(2) != null) {
          _setEpisodeNumber(match.group(2)!, tokenIndex, false);
        }
        if (match.group(3) != null) {
          _elements.insert(ElementCategory.releaseVersion, match.group(3)!);
        }
        return true;
      }
    }

    return false;
  }

  bool _matchJapaneseCounterPattern(String word, int tokenIndex) {
    if (word.isEmpty || word[word.length - 1] != '\u8A71') return false;

    final pattern = RegExp(r'(\d{1,4})\u8A71');
    final match = pattern.firstMatch(word);

    if (match != null) {
      _setEpisodeNumber(match.group(1)!, tokenIndex, false);
      return true;
    }

    return false;
  }

  bool _matchEpisodePatterns(String word, int tokenIndex) {
    // All patterns contain at least one non-numeric character
    if (isNumericString(word)) return false;

    var trimmedWord = trimString(word, ' -');

    final numericFront = isNumericChar(trimmedWord[0]);
    final numericBack = isNumericChar(trimmedWord[trimmedWord.length - 1]);

    // e.g. "01v2"
    if (numericFront && numericBack) {
      if (_matchSingleEpisodePattern(trimmedWord, tokenIndex)) return true;
    }
    // e.g. "01-02", "03-05v2"
    if (numericFront && numericBack) {
      if (_matchMultiEpisodePattern(trimmedWord, tokenIndex)) return true;
    }
    // e.g. "2x01", "S01E03", "S01-02xE001-150"
    if (numericBack) {
      if (_matchSeasonAndEpisodePattern(trimmedWord, tokenIndex)) return true;
    }
    // e.g. "ED1", "OP4a", "OVA2"
    if (!numericFront) {
      if (_matchTypeAndEpisodePattern(trimmedWord, tokenIndex)) return true;
    }
    // e.g. "07.5"
    if (numericFront && numericBack) {
      if (_matchFractionalEpisodePattern(trimmedWord, tokenIndex)) return true;
    }
    // e.g. "4a", "111C"
    if (numericFront && !numericBack) {
      if (_matchPartialEpisodePattern(trimmedWord, tokenIndex)) return true;
    }
    // e.g. "#01", "#02-03v2"
    if (numericBack) {
      if (_matchNumberSignPattern(trimmedWord, tokenIndex)) return true;
    }
    // U+8A71 is used as counter for stories, episodes of TV series, etc.
    if (numericFront) {
      if (_matchJapaneseCounterPattern(trimmedWord, tokenIndex)) return true;
    }

    return false;
  }

  bool _matchSingleVolumePattern(String word, int tokenIndex) {
    final pattern = RegExp(r'(\d{1,2})[vV](\d)');
    final match = pattern.firstMatch(word);

    if (match != null) {
      _setVolumeNumber(match.group(1)!, tokenIndex, false);
      _elements.insert(ElementCategory.releaseVersion, match.group(2)!);
      return true;
    }

    return false;
  }

  bool _matchMultiVolumePattern(String word, int tokenIndex) {
    final pattern = RegExp(r'(\d{1,2})[-~&+](\d{1,2})(?:[vV](\d))?');
    final match = pattern.firstMatch(word);

    if (match != null) {
      final lowerBound = match.group(1)!;
      final upperBound = match.group(2)!;
      if (stringToInt(lowerBound) < stringToInt(upperBound)) {
        if (_setVolumeNumber(lowerBound, tokenIndex, true)) {
          _setVolumeNumber(upperBound, tokenIndex, false);
          if (match.group(3) != null) {
            _elements.insert(ElementCategory.releaseVersion, match.group(3)!);
          }
          return true;
        }
      }
    }

    return false;
  }

  bool _matchVolumePatterns(String word, int tokenIndex) {
    // All patterns contain at least one non-numeric character
    if (isNumericString(word)) return false;

    var trimmedWord = trimString(word, ' -');

    final numericFront = isNumericChar(trimmedWord[0]);
    final numericBack = isNumericChar(trimmedWord[trimmedWord.length - 1]);

    // e.g. "01v2"
    if (numericFront && numericBack) {
      if (_matchSingleVolumePattern(trimmedWord, tokenIndex)) return true;
    }
    // e.g. "01-02", "03-05v2"
    if (numericFront && numericBack) {
      if (_matchMultiVolumePattern(trimmedWord, tokenIndex)) return true;
    }

    return false;
  }

  bool _searchForEquivalentNumbers(List<int> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final tokenIndex = tokens[i];
      final token = _tokens[tokenIndex];

      if (_isTokenIsolated(tokenIndex) ||
          !_isValidEpisodeNumber(token.content)) {
        continue;
      }

      // Find the first enclosed, non-delimiter token
      var nextToken = findNextToken(
        _tokens,
        tokenIndex,
        TokenFlags.flagNotDelimiter,
      );
      if (!_checkTokenCategory(nextToken, TokenCategory.bracket)) {
        continue;
      }
      nextToken = findNextToken(
        _tokens,
        nextToken,
        TokenFlags.flagEnclosed | TokenFlags.flagNotDelimiter,
      );
      if (!_checkTokenCategory(nextToken, TokenCategory.unknown)) {
        continue;
      }

      // Check if it's an isolated number
      if (!_isTokenIsolated(nextToken) ||
          !isNumericString(_tokens[nextToken].content) ||
          !_isValidEpisodeNumber(_tokens[nextToken].content)) {
        continue;
      }

      // Get min/max
      final token1Val = stringToInt(token.content);
      final token2Val = stringToInt(_tokens[nextToken].content);

      if (token1Val < token2Val) {
        _setEpisodeNumber(token.content, tokenIndex, false);
        _setAlternativeEpisodeNumber(_tokens[nextToken].content, nextToken);
      } else {
        _setEpisodeNumber(_tokens[nextToken].content, nextToken, false);
        _setAlternativeEpisodeNumber(token.content, tokenIndex);
      }

      return true;
    }

    return false;
  }

  bool _searchForSeparatedNumbers(List<int> tokens) {
    for (final tokenIndex in tokens) {
      final previousToken = findPreviousToken(
        _tokens,
        tokenIndex,
        TokenFlags.flagNotDelimiter,
      );

      // See if the number has a preceding "-" separator
      if (_checkTokenCategory(previousToken, TokenCategory.unknown) &&
          _isDashCharacter(_tokens[previousToken].content)) {
        if (_setEpisodeNumber(_tokens[tokenIndex].content, tokenIndex, true)) {
          _tokens[previousToken].category = TokenCategory.identifier;
          return true;
        }
      }
    }

    return false;
  }

  bool _searchForLastNumber(List<int> tokens) {
    for (var i = tokens.length - 1; i >= 0; i--) {
      final tokenIndex = tokens[i];
      final token = _tokens[tokenIndex];

      // Assuming that episode number always comes after the title, first token
      // cannot be what we're looking for
      if (tokenIndex == 0) continue;

      // An enclosed token is unlikely to be the episode number at this point
      if (token.enclosed) continue;

      // Ignore if it's the first non-enclosed, non-delimiter token
      bool allEnclosedOrDelimiter = true;
      for (var j = 0; j < tokenIndex; j++) {
        if (!_tokens[j].enclosed &&
            _tokens[j].category != TokenCategory.delimiter) {
          allEnclosedOrDelimiter = false;
          break;
        }
      }
      if (allEnclosedOrDelimiter) continue;

      // Ignore if the previous token is "Movie" or "Part"
      final previousToken = findPreviousToken(
        _tokens,
        tokenIndex,
        TokenFlags.flagNotDelimiter,
      );
      if (_checkTokenCategory(previousToken, TokenCategory.unknown)) {
        if (isStringEqualTo(_tokens[previousToken].content, 'Movie') ||
            isStringEqualTo(_tokens[previousToken].content, 'Part')) {
          continue;
        }
      }

      // We'll use this number after all
      if (_setEpisodeNumber(token.content, tokenIndex, true)) {
        return true;
      }
    }

    return false;
  }
}
