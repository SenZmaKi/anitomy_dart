enum TokenCategory { unknown, bracket, delimiter, identifier, invalid }

class TokenFlags {
  static const int flagNone = 0;

  // Categories
  static const int flagBracket = 1 << 0;
  static const int flagNotBracket = 1 << 1;
  static const int flagDelimiter = 1 << 2;
  static const int flagNotDelimiter = 1 << 3;
  static const int flagIdentifier = 1 << 4;
  static const int flagNotIdentifier = 1 << 5;
  static const int flagUnknown = 1 << 6;
  static const int flagNotUnknown = 1 << 7;
  static const int flagValid = 1 << 8;
  static const int flagNotValid = 1 << 9;

  // Enclosed
  static const int flagEnclosed = 1 << 10;
  static const int flagNotEnclosed = 1 << 11;

  // Masks
  static const int flagMaskCategories =
      flagBracket |
      flagNotBracket |
      flagDelimiter |
      flagNotDelimiter |
      flagIdentifier |
      flagNotIdentifier |
      flagUnknown |
      flagNotUnknown |
      flagValid |
      flagNotValid;

  static const int flagMaskEnclosed = flagEnclosed | flagNotEnclosed;
}

class TokenRange {
  int offset;
  int size;

  TokenRange({this.offset = 0, this.size = 0});
}

class Token {
  TokenCategory category;
  String content;
  bool enclosed;

  Token({
    this.category = TokenCategory.unknown,
    this.content = '',
    this.enclosed = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Token &&
        other.category == category &&
        other.content == content &&
        other.enclosed == enclosed;
  }

  @override
  int get hashCode => Object.hash(category, content, enclosed);
}

// Token utility functions
bool checkTokenFlags(Token token, int flags) {
  bool checkFlag(int flag) => (flags & flag) == flag;

  if ((flags & TokenFlags.flagMaskEnclosed) != 0) {
    final success = checkFlag(TokenFlags.flagEnclosed)
        ? token.enclosed
        : !token.enclosed;
    if (!success) return false;
  }

  if ((flags & TokenFlags.flagMaskCategories) != 0) {
    bool success = false;

    void checkCategory(int fe, int fn, TokenCategory c) {
      if (!success) {
        success = checkFlag(fe)
            ? token.category == c
            : checkFlag(fn)
            ? token.category != c
            : false;
      }
    }

    checkCategory(
      TokenFlags.flagBracket,
      TokenFlags.flagNotBracket,
      TokenCategory.bracket,
    );
    checkCategory(
      TokenFlags.flagDelimiter,
      TokenFlags.flagNotDelimiter,
      TokenCategory.delimiter,
    );
    checkCategory(
      TokenFlags.flagIdentifier,
      TokenFlags.flagNotIdentifier,
      TokenCategory.identifier,
    );
    checkCategory(
      TokenFlags.flagUnknown,
      TokenFlags.flagNotUnknown,
      TokenCategory.unknown,
    );
    checkCategory(
      TokenFlags.flagNotValid,
      TokenFlags.flagValid,
      TokenCategory.invalid,
    );

    if (!success) return false;
  }

  return true;
}

int findToken(List<Token> tokens, int start, int flags) {
  for (var i = start; i < tokens.length; i++) {
    if (checkTokenFlags(tokens[i], flags)) {
      return i;
    }
  }
  return -1;
}

int findTokenReverse(List<Token> tokens, int start, int flags) {
  for (var i = start; i >= 0; i--) {
    if (checkTokenFlags(tokens[i], flags)) {
      return i;
    }
  }
  return -1;
}

int findPreviousToken(List<Token> tokens, int position, int flags) {
  if (position <= 0) return -1;
  return findTokenReverse(tokens, position - 1, flags);
}

int findNextToken(List<Token> tokens, int position, int flags) {
  if (position >= tokens.length - 1) return -1;
  return findToken(tokens, position + 1, flags);
}
