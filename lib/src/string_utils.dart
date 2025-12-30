// Character checking functions
bool isAlphanumericChar(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return (code >= 0x30 && code <= 0x39) || // 0-9
      (code >= 0x41 && code <= 0x5A) || // A-Z
      (code >= 0x61 && code <= 0x7A); // a-z
}

bool isHexadecimalChar(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return (code >= 0x30 && code <= 0x39) || // 0-9
      (code >= 0x41 && code <= 0x46) || // A-F
      (code >= 0x61 && code <= 0x66); // a-f
}

bool isLatinChar(String char) {
  if (char.isEmpty) return false;
  // Check until the end of Latin Extended-B block
  return char.codeUnitAt(0) <= 0x024F;
}

bool isNumericChar(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39; // 0-9
}

// String checking functions
bool isAlphanumericString(String str) {
  if (str.isEmpty) return false;
  return str.runes.every(
    (rune) => isAlphanumericChar(String.fromCharCode(rune)),
  );
}

bool isHexadecimalString(String str) {
  if (str.isEmpty) return false;
  return str.runes.every(
    (rune) => isHexadecimalChar(String.fromCharCode(rune)),
  );
}

bool isMostlyLatinString(String str) {
  if (str.isEmpty) return false;
  final length = str.length;
  final latinCount = str.runes
      .where((rune) => isLatinChar(String.fromCharCode(rune)))
      .length;
  return latinCount / length >= 0.5;
}

bool isNumericString(String str) {
  if (str.isEmpty) return false;
  return str.runes.every((rune) => isNumericChar(String.fromCharCode(rune)));
}

// String comparison functions
bool isInString(String str1, String str2) {
  return str1.contains(str2);
}

bool isStringEqualTo(String str1, String str2) {
  return str1.toLowerCase() == str2.toLowerCase();
}

// String conversion functions
int stringToInt(String str) {
  try {
    return int.parse(str);
  } catch (_) {
    return 0;
  }
}

// String manipulation functions
void eraseString(StringBuffer sb, String eraseThis) {
  if (eraseThis.isEmpty) return;

  var str = sb.toString();
  str = str.replaceAll(eraseThis, '');
  sb.clear();
  sb.write(str);
}

String stringToUpperCopy(String str) {
  return str.toUpperCase();
}

String trimString(String str, [String trimChars = ' ']) {
  if (str.isEmpty) return str;

  // Find first character not in trimChars
  int posBegin = 0;
  while (posBegin < str.length && trimChars.contains(str[posBegin])) {
    posBegin++;
  }

  // Find last character not in trimChars
  int posEnd = str.length - 1;
  while (posEnd >= 0 && trimChars.contains(str[posEnd])) {
    posEnd--;
  }

  // If all characters are in trimChars, return empty
  if (posBegin > posEnd) {
    return '';
  }

  return str.substring(posBegin, posEnd + 1);
}
