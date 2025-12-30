import 'element.dart';
import 'keyword.dart';
import 'options.dart';
import 'parser.dart';
import 'string_utils.dart';
import 'token.dart';
import 'tokenizer.dart';

class Anitomy {
  final Elements _elements = Elements();
  final Options _options = Options();
  final List<Token> _tokens = [];

  Elements get elements => _elements;
  Options get options => _options;
  List<Token> get tokens => _tokens;

  bool parse(String filename) {
    _elements.clear();
    _tokens.clear();

    var processedFilename = filename;

    if (_options.parseFileExtension) {
      final result = _removeExtensionFromFilename(processedFilename);
      if (result != null) {
        processedFilename = result.filename;
        _elements.insert(ElementCategory.fileExtension, result.extension);
      }
    }

    if (_options.ignoredStrings.isNotEmpty) {
      processedFilename = _removeIgnoredStrings(processedFilename);
    }

    if (processedFilename.isEmpty) {
      return false;
    }
    _elements.insert(ElementCategory.fileName, processedFilename);

    final tokenizer = Tokenizer(
      processedFilename,
      _elements,
      _options,
      _tokens,
    );
    if (!tokenizer.tokenize()) {
      return false;
    }

    final parser = Parser(_elements, _options, _tokens);
    if (!parser.parse()) {
      return false;
    }

    return true;
  }

  _ExtensionResult? _removeExtensionFromFilename(String filename) {
    final position = filename.lastIndexOf('.');

    if (position == -1) {
      return null;
    }

    final extension = filename.substring(position + 1);

    const maxLength = 4;
    if (extension.length > maxLength) {
      return null;
    }

    if (!isAlphanumericString(extension)) {
      return null;
    }

    final keyword = keywordManager.normalize(extension);
    if (!keywordManager.findCategory(ElementCategory.fileExtension, keyword)) {
      return null;
    }

    final newFilename = filename.substring(0, position);

    return _ExtensionResult(newFilename, extension);
  }

  String _removeIgnoredStrings(String filename) {
    var result = filename;
    for (final str in _options.ignoredStrings) {
      result = result.replaceAll(str, '');
    }
    return result;
  }
}

class _ExtensionResult {
  final String filename;
  final String extension;

  _ExtensionResult(this.filename, this.extension);
}
