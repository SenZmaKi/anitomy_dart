import 'dart:convert';
import 'dart:io';
import 'package:anitomy_dart/anitomy.dart';
import 'package:test/test.dart';

void main() {
  group('Anitomy Tests', () {
    late List<Map<String, dynamic>> testData;

    setUpAll(() async {
      // Load test data from data.json
      final file = File('anitomy_original/anitomy/test/data.json');
      final jsonString = await file.readAsString();
      testData = List<Map<String, dynamic>>.from(json.decode(jsonString));
    });

    test('Parse anime filenames from data.json', () {
      const minimumPassThreshold = 1.0;
      var passedTests = 0;
      var failedTests = 0;
      final failures = <Map<String, dynamic>>[];

      for (final testCase in testData) {
        final filename = testCase['file_name'] as String?;
        if (filename == null || filename.isEmpty) continue;

        final anitomy = Anitomy();
        final parsed = anitomy.parse(filename);

        if (!parsed) {
          failedTests++;
          failures.add({'filename': filename, 'error': 'Failed to parse'});
          continue;
        }

        final elements = anitomy.elements;
        var testPassed = true;
        final errors = <String>[];

        // Check anime_title
        if (testCase.containsKey('anime_title')) {
          final expected = testCase['anime_title'] as String;
          final actual = elements.get(ElementCategory.animeTitle);
          if (actual != expected) {
            testPassed = false;
            errors.add('anime_title: expected "$expected", got "$actual"');
          }
        }

        // Check episode_number
        if (testCase.containsKey('episode_number')) {
          final expected = testCase['episode_number'];
          final actual = elements.get(ElementCategory.episodeNumber);

          if (expected is String) {
            if (actual != expected) {
              testPassed = false;
              errors.add('episode_number: expected "$expected", got "$actual"');
            }
          } else if (expected is List) {
            final actualAll = elements.getAll(ElementCategory.episodeNumber);
            if (actualAll.length != expected.length ||
                !actualAll.every((e) => expected.contains(e))) {
              testPassed = false;
              errors.add('episode_number: expected $expected, got $actualAll');
            }
          }
        }

        // Check release_group
        if (testCase.containsKey('release_group')) {
          final expected = testCase['release_group'] as String;
          final actual = elements.get(ElementCategory.releaseGroup);
          if (actual != expected) {
            testPassed = false;
            errors.add('release_group: expected "$expected", got "$actual"');
          }
        }

        // Check video_resolution
        if (testCase.containsKey('video_resolution')) {
          final expected = testCase['video_resolution'] as String;
          final actual = elements.get(ElementCategory.videoResolution);
          if (actual != expected) {
            testPassed = false;
            errors.add('video_resolution: expected "$expected", got "$actual"');
          }
        }

        // Check anime_year
        if (testCase.containsKey('anime_year')) {
          final expected = testCase['anime_year'] as String;
          final actual = elements.get(ElementCategory.animeYear);
          if (actual != expected) {
            testPassed = false;
            errors.add('anime_year: expected "$expected", got "$actual"');
          }
        }

        // Check audio_term
        if (testCase.containsKey('audio_term')) {
          final expected = testCase['audio_term'];
          final actual = elements.get(ElementCategory.audioTerm);

          if (expected is String) {
            if (actual != expected) {
              testPassed = false;
              errors.add('audio_term: expected "$expected", got "$actual"');
            }
          }
        }

        // Check file_extension
        if (testCase.containsKey('file_extension')) {
          final expected = testCase['file_extension'] as String;
          final actual = elements.get(ElementCategory.fileExtension);
          if (actual != expected) {
            testPassed = false;
            errors.add('file_extension: expected "$expected", got "$actual"');
          }
        }

        if (testPassed) {
          passedTests++;
        } else {
          failedTests++;
          failures.add({
            'filename': filename,
            'errors': errors,
            'expected': testCase,
          });
        }
      }

      print('\n========================================');
      print('Test Results:');
      print('Passed: $passedTests');
      print('Failed: $failedTests');
      print('Total: ${passedTests + failedTests}');
      print(
        'Success Rate: ${(passedTests / (passedTests + failedTests) * 100).toStringAsFixed(2)}%',
      );
      print('========================================\n');

      if (failures.isNotEmpty) {
        print('Failures:');
        for (var i = 0; i < failures.length; i++) {
          final failure = failures[i];
          print('\n${i + 1}. ${failure['filename']}');
          if (failure.containsKey('errors')) {
            for (final error in failure['errors'] as List) {
              print('   $error');
            }
          } else {
            print('   ${failure['error']}');
          }
        }
      }

      expect(
        passedTests / (passedTests + failedTests),
        greaterThan(minimumPassThreshold),
      );
    });

    test('Basic parsing test', () {
      final anitomy = Anitomy();
      const filename =
          '[TaigaSubs]_Toradora!_(2008)_-_01v2_-_Tiger_and_Dragon_[1280x720_H.264_FLAC][1234ABCD].mkv';

      expect(anitomy.parse(filename), isTrue);

      final elements = anitomy.elements;
      expect(elements.get(ElementCategory.animeTitle), equals('Toradora!'));
      expect(elements.get(ElementCategory.animeYear), equals('2008'));
      expect(elements.get(ElementCategory.episodeNumber), equals('01'));
      expect(elements.get(ElementCategory.releaseGroup), equals('TaigaSubs'));
      expect(elements.get(ElementCategory.videoResolution), equals('1280x720'));
      expect(elements.get(ElementCategory.releaseVersion), equals('2'));
    });
  });
}
