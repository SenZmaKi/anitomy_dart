#include "../anitomy/anitomy/anitomy.h"
#include <codecvt>
#include <fstream>
#include <iostream>
#include <locale>
#include <map>
#include <sstream>
#include <string>
#include <vector>

// Helper function to convert std::string to std::wstring
std::wstring stringToWstring(const std::string &str) {
  std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
  return converter.from_bytes(str);
}

// Helper function to convert std::wstring to std::string
std::string wstringToString(const std::wstring &wstr) {
  std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
  return converter.to_bytes(wstr);
}

// Simple JSON parser for the test data
class SimpleJSON {
public:
  static std::string unescapeString(const std::string &str) {
    std::string result;
    for (size_t i = 0; i < str.length(); i++) {
      if (str[i] == '\\' && i + 1 < str.length()) {
        i++;
        switch (str[i]) {
        case 'n':
          result += '\n';
          break;
        case 't':
          result += '\t';
          break;
        case 'r':
          result += '\r';
          break;
        case '"':
          result += '"';
          break;
        case '\\':
          result += '\\';
          break;
        default:
          result += str[i];
          break;
        }
      } else {
        result += str[i];
      }
    }
    return result;
  }

  static std::string trim(const std::string &str) {
    size_t first = str.find_first_not_of(" \t\n\r");
    if (first == std::string::npos)
      return "";
    size_t last = str.find_last_not_of(" \t\n\r");
    return str.substr(first, last - first + 1);
  }

  static std::string parseString(const std::string &json, size_t &pos) {
    if (json[pos] != '"')
      return "";
    pos++; // skip opening quote

    std::string result;
    while (pos < json.length() && json[pos] != '"') {
      if (json[pos] == '\\' && pos + 1 < json.length()) {
        pos++;
        switch (json[pos]) {
        case 'n':
          result += '\n';
          break;
        case 't':
          result += '\t';
          break;
        case 'r':
          result += '\r';
          break;
        case '"':
          result += '"';
          break;
        case '\\':
          result += '\\';
          break;
        default:
          result += json[pos];
          break;
        }
      } else {
        result += json[pos];
      }
      pos++;
    }

    if (pos < json.length())
      pos++; // skip closing quote
    return result;
  }

  static void skipWhitespace(const std::string &json, size_t &pos) {
    while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\t' ||
                                   json[pos] == '\n' || json[pos] == '\r')) {
      pos++;
    }
  }

  static std::map<std::string, std::string> parseObject(const std::string &json,
                                                        size_t &pos) {
    std::map<std::string, std::string> result;

    skipWhitespace(json, pos);
    if (pos >= json.length() || json[pos] != '{')
      return result;
    pos++; // skip {

    while (pos < json.length()) {
      skipWhitespace(json, pos);
      if (json[pos] == '}') {
        pos++;
        break;
      }

      // Parse key
      skipWhitespace(json, pos);
      std::string key = parseString(json, pos);

      skipWhitespace(json, pos);
      if (pos >= json.length() || json[pos] != ':')
        break;
      pos++; // skip :

      // Parse value
      skipWhitespace(json, pos);
      std::string value;

      if (json[pos] == '"') {
        value = parseString(json, pos);
      } else if (json[pos] == '[') {
        // Handle array
        pos++; // skip [
        std::string arrayValue = "[";
        int depth = 1;
        while (pos < json.length() && depth > 0) {
          if (json[pos] == '[')
            depth++;
          else if (json[pos] == ']')
            depth--;
          if (depth > 0)
            arrayValue += json[pos];
          pos++;
        }
        arrayValue += "]";
        value = arrayValue;
      } else {
        // Parse number or boolean
        while (pos < json.length() && json[pos] != ',' && json[pos] != '}') {
          value += json[pos];
          pos++;
        }
        value = trim(value);
      }

      result[key] = value;

      skipWhitespace(json, pos);
      if (pos < json.length() && json[pos] == ',') {
        pos++;
      }
    }

    return result;
  }

  static std::vector<std::map<std::string, std::string>>
  parseArray(const std::string &json) {
    std::vector<std::map<std::string, std::string>> result;
    size_t pos = 0;

    skipWhitespace(json, pos);
    if (pos >= json.length() || json[pos] != '[')
      return result;
    pos++; // skip [

    while (pos < json.length()) {
      skipWhitespace(json, pos);
      if (json[pos] == ']')
        break;

      auto obj = parseObject(json, pos);
      if (!obj.empty()) {
        result.push_back(obj);
      }

      skipWhitespace(json, pos);
      if (pos < json.length() && json[pos] == ',') {
        pos++;
      }
    }

    return result;
  }
};

// Convert anitomy element category to string for comparison
std::string categoryToKey(anitomy::ElementCategory category) {
  switch (category) {
  case anitomy::kElementAnimeTitle:
    return "anime_title";
  case anitomy::kElementEpisodeNumber:
    return "episode_number";
  case anitomy::kElementReleaseGroup:
    return "release_group";
  case anitomy::kElementVideoResolution:
    return "video_resolution";
  case anitomy::kElementAnimeYear:
    return "anime_year";
  case anitomy::kElementAudioTerm:
    return "audio_term";
  case anitomy::kElementFileExtension:
    return "file_extension";
  case anitomy::kElementFileChecksum:
    return "file_checksum";
  case anitomy::kElementVideoTerm:
    return "video_term";
  case anitomy::kElementEpisodeTitle:
    return "episode_title";
  case anitomy::kElementReleaseVersion:
    return "release_version";
  default:
    return "";
  }
}

struct TestFailure {
  std::string filename;
  std::vector<std::string> errors;
  std::map<std::string, std::string> expected;
};

int main() {
  // Read test data
  std::ifstream file("../anitomy/test/data.json");
  if (!file.is_open()) {
    std::cerr << "Failed to open data.json" << std::endl;
    return 1;
  }

  std::stringstream buffer;
  buffer << file.rdbuf();
  std::string jsonContent = buffer.str();
  file.close();

  auto testData = SimpleJSON::parseArray(jsonContent);

  std::cout << "Loaded " << testData.size() << " test cases" << std::endl;

  int passedTests = 0;
  int failedTests = 0;
  std::vector<TestFailure> failures;

  for (const auto &testCase : testData) {
    auto it = testCase.find("file_name");
    if (it == testCase.end())
      continue;

    std::string filename = it->second;
    if (filename.empty())
      continue;

    anitomy::Anitomy anitomy;
    bool parsed = anitomy.Parse(stringToWstring(filename));

    if (!parsed) {
      failedTests++;
      TestFailure failure;
      failure.filename = filename;
      failure.errors.push_back("Failed to parse");
      failures.push_back(failure);
      continue;
    }

    bool testPassed = true;
    std::vector<std::string> errors;

    // Check each expected field
    for (const auto &expected : testCase) {
      const std::string &key = expected.first;
      const std::string &expectedValue = expected.second;

      if (key == "file_name" || key == "id")
        continue;

      anitomy::ElementCategory category = anitomy::kElementUnknown;

      if (key == "anime_title")
        category = anitomy::kElementAnimeTitle;
      else if (key == "episode_number")
        category = anitomy::kElementEpisodeNumber;
      else if (key == "release_group")
        category = anitomy::kElementReleaseGroup;
      else if (key == "video_resolution")
        category = anitomy::kElementVideoResolution;
      else if (key == "anime_year")
        category = anitomy::kElementAnimeYear;
      else if (key == "audio_term")
        category = anitomy::kElementAudioTerm;
      else if (key == "file_extension")
        category = anitomy::kElementFileExtension;
      else if (key == "file_checksum")
        category = anitomy::kElementFileChecksum;
      else if (key == "video_term")
        category = anitomy::kElementVideoTerm;
      else if (key == "episode_title")
        category = anitomy::kElementEpisodeTitle;
      else if (key == "release_version")
        category = anitomy::kElementReleaseVersion;
      else
        continue;

      // Handle arrays for episode_number
      if (expectedValue[0] == '[') {
        // Array case
        auto allValues = anitomy.elements().get_all(category);

        // Parse expected JSON array - remove whitespace, newlines, tabs
        std::string cleanExpected = expectedValue;
        cleanExpected.erase(
            remove_if(cleanExpected.begin(), cleanExpected.end(),
                      [](char c) {
                        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
                      }),
            cleanExpected.end());

        // Build actual array string (compact format)
        std::string actualArray = "[";
        for (size_t i = 0; i < allValues.size(); i++) {
          if (i > 0)
            actualArray += ",";
          actualArray += "\"" + wstringToString(allValues[i]) + "\"";
        }
        actualArray += "]";

        if (cleanExpected != actualArray) {
          testPassed = false;
          errors.push_back(key + ": expected " + expectedValue + ", got " +
                           actualArray);
        }
      } else {
        // Single value case
        auto actualValue = wstringToString(anitomy.elements().get(category));
        if (actualValue != expectedValue) {
          testPassed = false;
          errors.push_back(key + ": expected \"" + expectedValue +
                           "\", got \"" + actualValue + "\"");
        }
      }
    }

    if (testPassed) {
      passedTests++;
    } else {
      failedTests++;
      TestFailure failure;
      failure.filename = filename;
      failure.errors = errors;
      failure.expected = testCase;
      failures.push_back(failure);
    }
  }

  std::cout << "\n========================================" << std::endl;
  std::cout << "Test Results:" << std::endl;
  std::cout << "Passed: " << passedTests << std::endl;
  std::cout << "Failed: " << failedTests << std::endl;
  std::cout << "Total: " << (passedTests + failedTests) << std::endl;

  double successRate =
      (double)passedTests / (passedTests + failedTests) * 100.0;
  std::cout << "Success Rate: " << std::fixed << std::setprecision(2)
            << successRate << "%" << std::endl;
  std::cout << "========================================\n" << std::endl;

  if (!failures.empty()) {
    std::cout << "Failures:" << std::endl;
    for (size_t i = 0; i < failures.size(); i++) {
      const auto &failure = failures[i];
      std::cout << "\n" << (i + 1) << ". " << failure.filename << std::endl;
      for (const auto &error : failure.errors) {
        std::cout << "   " << error << std::endl;
      }
    }
  }

  return 0;
}
