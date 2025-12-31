# Anitomy Dart Port Test Comparison Report

Generated: Wed Dec 31 09:40:16 EAT 2025

## Summary

| Implementation | Passed | Failed | Total | Success Rate |
|---------------|--------|--------|-------|--------------|
| C++ (Original) | 146 | 36 | 182 | 80.22% |
| Dart (Port) | 159 | 23 | 182 | 87.36% |

### Difference

- **Passed**: +13
- **Failed**: -13
- **Success Rate**: +7.14%

## Regressions

Test cases that **pass in C++** but **fail in Dart**: 0

✅ No regressions found!

## Improvements

Test cases that **fail in C++** but **pass in Dart**: 13

### 1. Macross Frontier - Sayonara no Tsubasa (Central Anime, 720p) [46B35E25].mkv

C++ errors:

- release_group: expected "Central Anime", got ""

### 2. [Nubles] Space Battleship Yamato 2199 (2012) episode 18 (720p 8 bit AAC)[BA70BA9C]

C++ errors:

- video_term: expected "8 bit", got ""

### 3. [Nubles] Space Battleship Yamato 2199 (2012) episode 18 (720p 10 bit AAC)[1F56D642]

C++ errors:

- video_term: expected "10 bit", got ""

### 4. [[Zero-Raws] Shingeki no Kyojin - 05 (MBS 1280x720 x264 AAC).mp4

C++ errors:

- release_group: expected "Zero-Raws", got "[Zero-Raws"

### 5. [TV-J] Kidou Senshi Gundam UC Unicorn - episode.02 [BD 1920x1080 h264+AAC(5.1ch JP+EN) +Sub(JP-EN-SP-FR-CH) Chap].mp4

C++ errors:

- audio_term: expected [
- "AAC",
- "5.1ch"
- ], got []

### 6. DRAMAtical Murder Episode 1 - Data_01_Login

C++ errors:

- episode_title: expected "Data_01_Login", got "Data 01 Login"

### 7. 37 [Ruberia]_Death_Note_-_37v2_[FINAL]_[XviD][6FA7D273].avi

C++ errors:

- anime_title: expected "Death Note", got "37 [Ruberia] Death Note"
- release_group: expected "Ruberia", got "FINAL"

### 8. [CH] Sword Art Online Extra Edition Dual Audio [BD 480p][10bitH.264+Vorbis]

C++ errors:

- audio_term: expected [
- "Dual Audio",
- "Vorbis"
- ], got ["Dual Audio","Vorbis"]

### 9. Ep. 01 - The Boy in the Iceberg

C++ errors:

- episode_title: expected "The Boy in the Iceberg", got ""

### 10. [B-G_&_m.3.3.w]_Myself_Yourself_12.DVD(H.264_DD2.0)_[CB2B37F1].mkv

C++ errors:

- audio_term: expected "DD2.0", got ""

### 11. Neko no Ongaeshi - [HQR.remux-DualAudio][NTV.1280x692.h264](0CDC2145).mkv

C++ errors:

- audio_term: expected "DualAudio", got ""

### 12. [EveTaku] AKB0048 Vol.03 - Making of Kibou-ni-Tsuite Music Video (BDRip 1080i H.264-Hi10P FLAC)[C09462E2]

C++ errors:

- video_resolution: expected "1080i", got ""

### 13. [Judas] Aharen-san wa Hakarenai - S01E06v2.mkv

C++ errors:

- release_version: expected "2", got ""

## Common Failures

Test cases that **fail in both** implementations: 22

<details>
<summary>Click to expand common failures</summary>

### 1. Code_Geass_R2_TV_[20_of_25]_[ru_jp]_[HDTV]_[Varies_&_Cuba77_&_AnimeReactor_RU].mkv

**C++ errors:**

- release_group: expected "Varies & Cuba77 & AnimeReactor RU", got "ru_jp"

**Dart errors:**

- release_group: expected "Varies & Cuba77 & AnimeReactor RU", got "ru_jp"

### 2. Noein_[01_of_24]_[ru_jp]_[bodlerov_&_torrents_ru].mkv

**C++ errors:**

- release_group: expected "bodlerov & torrents ru", got "ru_jp"

**Dart errors:**

- release_group: expected "bodlerov & torrents ru", got "ru_jp"

### 3. [Ayu]_Kiddy_Grade_2_-_Pilot_[H264_AC3][650B731B].mkv

**C++ errors:**

- anime_title: expected "Kiddy Grade 2", got "Kiddy Grade"

**Dart errors:**

- anime_title: expected "Kiddy Grade 2", got "Kiddy Grade"

### 4. [Keroro].148.[Xvid.mp3].[FE68D5F1].avi

**C++ errors:**

- anime_title: expected "Keroro", got "148"
- episode_number: expected "148", got ""

**Dart errors:**

- anime_title: expected "Keroro", got "148"
- episode_number: expected "148", got ""

### 5. Aim_For_The_Top!_Gunbuster-ep1.BD(H264.FLAC.10bit)[KAA][69ECCDCF].mkv

**C++ errors:**

- anime_title: expected "Aim For The Top! Gunbuster", got "Aim For The Top! Gunbuster-ep1"
- episode_number: expected "1", got ""

**Dart errors:**

- anime_title: expected "Aim For The Top! Gunbuster", got "Aim For The Top! Gunbuster-ep1"
- episode_number: expected "1", got ""

### 6. [Mobile Suit Gundam Seed Destiny HD REMASTER][07][Big5][720p][AVC_AAC][encoded by SEED].mp4

**C++ errors:**

- anime_title: expected "Mobile Suit Gundam Seed Destiny", got "encoded by SEED"
- release_group: expected "SEED", got ""

**Dart errors:**

- anime_title: expected "Mobile Suit Gundam Seed Destiny", got "encoded by SEED"
- release_group: expected "SEED", got ""

### 7. 「K」 Image Blu-ray WHITE & BLACK - Main (BD 1280x720 AVC AAC).mp4

**C++ errors:**

- anime_title: expected "「K」", got "Image"

**Dart errors:**

- anime_title: expected "「K」", got "Image"

### 8. Evangelion Shin Gekijouban Q (BDrip 1920x1080 x264 FLACx2 5.1ch)-ank.mkv

**C++ errors:**

- release_group: expected "ank", got ""

**Dart errors:**

- release_group: expected "ank", got ""

### 9. 【MMZYSUB】★【Golden Time】[24（END）][GB][720P_MP4]

**C++ errors:**

- anime_title: expected "Golden Time", got "★"
- episode_number: expected "24", got ""
- video_term: expected "MP4", got ""

**Dart errors:**

- anime_title: expected "Golden Time", got "★"
- episode_number: expected "24", got ""

### 10. [AoJiaoZero][Mangaka-san to Assistant-san to the Animation] 02 [BIG][X264_AAC][720P].mp4

**C++ errors:**

- anime_title: expected "Mangaka-san to Assistant-san to the Animation", got "02"
- episode_number: expected "02", got ""

**Dart errors:**

- episode_number: expected "02", got ""

### 11. Vol.01

**C++ errors:**

- Failed to parse

**Dart errors:**

- Failed to parse

### 12. [Asenshi] Rozen Maiden 3 - PV [CA57F300].mkv

**C++ errors:**

- anime_title: expected "Rozen Maiden 3", got "Rozen Maiden"

**Dart errors:**

- anime_title: expected "Rozen Maiden 3", got "Rozen Maiden"

### 13. __BLUE DROP 10 (1).avi

**C++ errors:**

- episode_number: expected "10", got "1"

**Dart errors:**

- episode_number: expected "10", got "1"

### 14. [UTW]_Accel_World_-_EX01_[BD][h264-720p_AAC][3E56EE18].mkv

**C++ errors:**

- anime_title: expected "Accel World - EX", got "Accel World - EX01"
- episode_number: expected "01", got ""

**Dart errors:**

- anime_title: expected "Accel World - EX", got "Accel World - EX01"
- episode_number: expected "01", got ""

### 15. EvoBot.[Watakushi]_Akuma_no_Riddle_-_01v2_[720p][69A307A2].mkv

**C++ errors:**

- anime_title: expected "Akuma no Riddle", got "EvoBot [Watakushi] Akuma no Riddle"
- release_group: expected "Watakushi", got ""

**Dart errors:**

- anime_title: expected "Akuma no Riddle", got "EvoBot [Watakushi] Akuma no Riddle"
- release_group: expected "Watakushi", got ""

### 16. 01 - Land of Visible Pain.mkv

**C++ errors:**

- episode_number: expected "01", got ""
- episode_title: expected "Land of Visible Pain", got ""

**Dart errors:**

- episode_number: expected "01", got ""

### 17. The iDOLM@STER 765 Pro to Iu Monogatari.mkv

**C++ errors:**

- anime_title: expected "The iDOLM@STER 765 Pro to Iu Monogatari", got "The iDOLM@STER"

**Dart errors:**

- anime_title: expected "The iDOLM@STER 765 Pro to Iu Monogatari", got "The iDOLM@STER"

### 18. [SpoonSubs]_Hidamari_Sketch_x365_-_04.1_(DVD)[B6CE8458].mkv

**C++ errors:**

- anime_title: expected "Hidamari Sketch x365", got "Hidamari Sketch x365 - 04.1"
- episode_number: expected "04.1", got ""

**Dart errors:**

- anime_title: expected "Hidamari Sketch x365", got "Hidamari Sketch x365 - 04.1"
- episode_number: expected "04.1", got ""

### 19. The.Animatrix.08.A.Detective.Story.720p.BluRay.DTS.x264-ESiR.mkv

**C++ errors:**

- anime_title: expected "The Animatrix", got "The Animatrix 08.A Detective Story"
- episode_number: expected "08", got ""
- episode_title: expected "A Detective Story", got ""
- release_group: expected "ESiR", got ""
- video_term: expected "x264", got ""

**Dart errors:**

- anime_title: expected "The Animatrix", got "The Animatrix 08.A Detective Story"
- episode_number: expected "08", got ""
- release_group: expected "ESiR", got ""

### 20. [ReDone] Memories Off 3.5 - 04 (DVD 10-bit).mkv

**C++ errors:**

- anime_title: expected "Memories Off 3.5", got "Memories Off"
- episode_number: expected "04", got "3.5"

**Dart errors:**

- anime_title: expected "Memories Off 3.5", got "Memories Off"
- episode_number: expected "04", got "3.5"

### 21. Byousoku 5 Centimeter [Blu-Ray][1920x1080 H.264][2.0ch AAC][SOFTSUBS]

**C++ errors:**

- anime_title: expected "Byousoku 5 Centimeter", got "Byousoku"

**Dart errors:**

- anime_title: expected "Byousoku 5 Centimeter", got "Byousoku"

### 22. [Anime

**C++ errors:**

- Failed to parse

**Dart errors:**

- Failed to parse
- Expected: a value greater than <1.0>
- Actual: <0.8736263736263736>
- Which: is not a value greater than <1.0>
- package:matcher               expect
- test/anitomy_test.dart 160:7  main.<fn>.<fn>
- [1m[36mTo run this test again:[0m dart test test/anitomy_test.dart -p vm --plain-name 'Anitomy Tests Parse anime filenames from data.json'
- Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
- For example, 'dart test --chain-stack-traces'.

</details>
