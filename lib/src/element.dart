enum ElementCategory {
  animeSeason,
  animeSeasonPrefix,
  animeTitle,
  animeType,
  animeYear,
  audioTerm,
  deviceCompatibility,
  episodeNumber,
  episodeNumberAlt,
  episodePrefix,
  episodeTitle,
  fileChecksum,
  fileExtension,
  fileName,
  language,
  other,
  releaseGroup,
  releaseInformation,
  releaseVersion,
  source,
  subtitles,
  videoResolution,
  videoTerm,
  volumeNumber,
  volumePrefix,
  unknown,
}

class ElementPair {
  ElementCategory category;
  String value;

  ElementPair(this.category, this.value);
}

class Elements {
  final List<ElementPair> _elements = [];

  // Capacity
  bool get isEmpty => _elements.isEmpty;
  int get length => _elements.length;

  // Iterators
  Iterable<ElementPair> get items => _elements;

  // Element access
  ElementPair at(int position) => _elements[position];

  // Value access
  String get(ElementCategory category) {
    final element = _findElement(category);
    return element?.value ?? '';
  }

  List<String> getAll(ElementCategory category) {
    return _elements
        .where((element) => element.category == category)
        .map((element) => element.value)
        .toList();
  }

  // Modifiers
  void clear() {
    _elements.clear();
  }

  void insert(ElementCategory category, String value) {
    if (value.isNotEmpty) {
      _elements.add(ElementPair(category, value));
    }
  }

  void erase(ElementCategory category) {
    _elements.removeWhere((element) => element.category == category);
  }

  void set(ElementCategory category, String value) {
    final index = _findElementIndex(category);
    if (index != -1) {
      _elements[index].value = value;
    } else {
      _elements.add(ElementPair(category, value));
    }
  }

  String operator [](ElementCategory category) {
    final element = _findElement(category);
    if (element != null) {
      return element.value;
    }
    final newElement = ElementPair(category, '');
    _elements.add(newElement);
    return newElement.value;
  }

  void operator []=(ElementCategory category, String value) {
    set(category, value);
  }

  // Lookup
  int count(ElementCategory category) {
    return _elements.where((element) => element.category == category).length;
  }

  bool emptyCategory(ElementCategory category) {
    return _findElement(category) == null;
  }

  ElementPair? _findElement(ElementCategory category) {
    try {
      return _elements.firstWhere((element) => element.category == category);
    } catch (_) {
      return null;
    }
  }

  int _findElementIndex(ElementCategory category) {
    for (var i = 0; i < _elements.length; i++) {
      if (_elements[i].category == category) {
        return i;
      }
    }
    return -1;
  }
}
