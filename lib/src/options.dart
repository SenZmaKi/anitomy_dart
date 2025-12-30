class Options {
  String allowedDelimiters;
  List<String> ignoredStrings;

  bool parseEpisodeNumber;
  bool parseEpisodeTitle;
  bool parseFileExtension;
  bool parseReleaseGroup;

  Options({
    this.allowedDelimiters = ' _.&+,|',
    List<String>? ignoredStrings,
    this.parseEpisodeNumber = true,
    this.parseEpisodeTitle = true,
    this.parseFileExtension = true,
    this.parseReleaseGroup = true,
  }) : ignoredStrings = ignoredStrings ?? [];
}
