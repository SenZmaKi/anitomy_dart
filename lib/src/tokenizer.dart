import 'element.dart';
import 'keyword.dart';
import 'options.dart';
import 'string_utils.dart';
import 'token.dart';

class Tokenizer {
  final String _filename;
  final Elements _elements;
  final Options _options;
  final List<Token> _tokens;

  Tokenizer(this._filename, this._elements, this._options, this._tokens);

  bool tokenize() {
    _tokenizeByBrackets();
    return _tokens.isNotEmpty;
  }

  void _addToken(TokenCategory category, bool enclosed, TokenRange range) {
    final content = _filename.substring(
      range.offset,
      range.offset + range.size,
    );
    _tokens.add(
      Token(category: category, content: content, enclosed: enclosed),
    );
  }

  void _tokenizeByBrackets() {
    final brackets = [
      ['(', ')'], // U+0028-U+0029 Parenthesis
      ['[', ']'], // U+005B-U+005D Square bracket
      ['{', '}'], // U+007B-U+007D Curly bracket
      ['\u300C', '\u300D'], // Corner bracket
      ['\u300E', '\u300F'], // White corner bracket
      ['\u3010', '\u3011'], // Black lenticular bracket
      ['\uFF08', '\uFF09'], // Fullwidth parenthesis
    ];

    bool isBracketOpen = false;
    String matchingBracket = '';

    int charBegin = 0;
    int currentChar = 0;

    int findFirstBracket(int start) {
      for (var i = start; i < _filename.length; i++) {
        for (final bracketPair in brackets) {
          if (_filename[i] == bracketPair[0]) {
            matchingBracket = bracketPair[1];
            return i;
          }
        }
      }
      return _filename.length;
    }

    while (currentChar < _filename.length && charBegin < _filename.length) {
      if (!isBracketOpen) {
        currentChar = findFirstBracket(charBegin);
      } else {
        currentChar = _filename.indexOf(matchingBracket, charBegin);
        if (currentChar == -1) {
          currentChar = _filename.length;
        }
      }

      final range = TokenRange(
        offset: charBegin,
        size: currentChar - charBegin,
      );

      if (range.size > 0) {
        // Found unknown token
        _tokenizeByPreidentified(isBracketOpen, range);
      }

      if (currentChar < _filename.length) {
        // Found bracket
        _addToken(
          TokenCategory.bracket,
          true,
          TokenRange(offset: currentChar, size: 1),
        );
        isBracketOpen = !isBracketOpen;
        charBegin = currentChar + 1;
      }
    }
  }

  void _tokenizeByPreidentified(bool enclosed, TokenRange range) {
    final preidentifiedTokens = <TokenRange>[];
    keywordManager.peek(_filename, range, _elements, preidentifiedTokens);

    int offset = range.offset;
    var subrange = TokenRange(offset: range.offset, size: 0);

    while (offset < range.offset + range.size) {
      for (final preidentifiedToken in preidentifiedTokens) {
        if (offset == preidentifiedToken.offset) {
          if (subrange.size > 0) {
            _tokenizeByDelimiters(enclosed, subrange);
          }
          _addToken(TokenCategory.identifier, enclosed, preidentifiedToken);
          subrange.offset = preidentifiedToken.offset + preidentifiedToken.size;
          offset = subrange.offset - 1; // It's going to be incremented below
          break;
        }
      }
      subrange.size = ++offset - subrange.offset;
    }

    // Either there was no preidentified token range, or we're now about to
    // process the tail of our current range.
    if (subrange.size > 0) {
      _tokenizeByDelimiters(enclosed, subrange);
    }
  }

  void _tokenizeByDelimiters(bool enclosed, TokenRange range) {
    final delimiters = _getDelimiters(range);

    if (delimiters.isEmpty) {
      _addToken(TokenCategory.unknown, enclosed, range);
      return;
    }

    int charBegin = range.offset;
    int currentChar = charBegin;

    while (currentChar < range.offset + range.size) {
      // Find first delimiter
      int found = -1;
      for (var i = currentChar; i < range.offset + range.size; i++) {
        if (delimiters.contains(_filename[i])) {
          found = i;
          break;
        }
      }

      if (found == -1) {
        currentChar = range.offset + range.size;
      } else {
        currentChar = found;
      }

      final subrange = TokenRange(
        offset: charBegin,
        size: currentChar - charBegin,
      );

      if (subrange.size > 0) {
        // Found unknown token
        _addToken(TokenCategory.unknown, enclosed, subrange);
      }

      if (currentChar < range.offset + range.size) {
        // Found delimiter
        _addToken(
          TokenCategory.delimiter,
          enclosed,
          TokenRange(offset: currentChar, size: 1),
        );
        charBegin = currentChar + 1;
        currentChar = charBegin;
      }
    }

    _validateDelimiterTokens();
  }

  String _getDelimiters(TokenRange range) {
    final delimiters = StringBuffer();
    final seen = <String>{};

    for (var i = range.offset; i < range.offset + range.size; i++) {
      final c = _filename[i];
      if (!isAlphanumericChar(c) &&
          _options.allowedDelimiters.contains(c) &&
          !seen.contains(c)) {
        delimiters.write(c);
        seen.add(c);
      }
    }

    return delimiters.toString();
  }

  void _validateDelimiterTokens() {
    bool isDelimiterToken(int index) {
      return index >= 0 &&
          index < _tokens.length &&
          _tokens[index].category == TokenCategory.delimiter;
    }

    bool isUnknownToken(int index) {
      return index >= 0 &&
          index < _tokens.length &&
          _tokens[index].category == TokenCategory.unknown;
    }

    bool isSingleCharacterToken(int index) {
      return isUnknownToken(index) &&
          _tokens[index].content.length == 1 &&
          _tokens[index].content != '-';
    }

    void appendTokenTo(int tokenIndex, int appendToIndex) {
      _tokens[appendToIndex].content += _tokens[tokenIndex].content;
      _tokens[tokenIndex].category = TokenCategory.invalid;
    }

    for (var i = 0; i < _tokens.length; i++) {
      if (_tokens[i].category != TokenCategory.delimiter) continue;

      final delimiter = _tokens[i].content[0];
      final prevToken = findPreviousToken(_tokens, i, TokenFlags.flagValid);
      final nextToken = findNextToken(_tokens, i, TokenFlags.flagValid);

      // Check for single-character tokens to prevent splitting group names,
      // keywords, episode number, etc.
      if (delimiter != ' ' && delimiter != '_') {
        if (isSingleCharacterToken(prevToken)) {
          appendTokenTo(i, prevToken);
          var next = nextToken;
          while (isUnknownToken(next)) {
            appendTokenTo(next, prevToken);
            next = findNextToken(_tokens, next, TokenFlags.flagValid);
            if (isDelimiterToken(next) &&
                _tokens[next].content[0] == delimiter) {
              appendTokenTo(next, prevToken);
              next = findNextToken(_tokens, next, TokenFlags.flagValid);
            }
          }
          continue;
        }
        if (isSingleCharacterToken(nextToken)) {
          appendTokenTo(i, prevToken);
          appendTokenTo(nextToken, prevToken);
          continue;
        }
      }

      // Check for adjacent delimiters
      if (isUnknownToken(prevToken) && isDelimiterToken(nextToken)) {
        final nextDelimiter = _tokens[nextToken].content[0];
        if (delimiter != nextDelimiter && delimiter != ',') {
          if (nextDelimiter == ' ' || nextDelimiter == '_') {
            appendTokenTo(i, prevToken);
          }
        }
      } else if (isDelimiterToken(prevToken) && isDelimiterToken(nextToken)) {
        final prevDelimiter = _tokens[prevToken].content[0];
        final nextDelimiter = _tokens[nextToken].content[0];
        if (prevDelimiter == nextDelimiter && prevDelimiter != delimiter) {
          _tokens[i].category = TokenCategory.unknown; // e.g. "&" in "_&_"
        }
      }

      // Check for other special cases
      if (delimiter == '&' || delimiter == '+') {
        if (isUnknownToken(prevToken) && isUnknownToken(nextToken)) {
          if (isNumericString(_tokens[prevToken].content) &&
              isNumericString(_tokens[nextToken].content)) {
            appendTokenTo(i, prevToken);
            appendTokenTo(nextToken, prevToken); // e.g. "01+02"
          }
        }
      }
    }

    _tokens.removeWhere((token) => token.category == TokenCategory.invalid);
  }
}
