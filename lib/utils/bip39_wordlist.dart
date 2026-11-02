import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:bearby/src/rust/api/methods.dart';
import 'package:bearby/src/rust/api/utils.dart';

enum Bip39Language {
  english(
    code: 'en',
    assetName: 'english',
    nativeName: 'English',
    englishName: 'English',
    shortCode: 'EN',
     badge: '🇬🇧',
  ),
  spanish(
    code: 'es',
    assetName: 'spanish',
    nativeName: 'Español',
    englishName: 'Spanish',
    shortCode: 'ES',
    badge: '🇪🇸',
  ),
  french(
    code: 'fr',
    assetName: 'french',
    nativeName: 'Français',
    englishName: 'French',
    shortCode: 'FR',
    badge: '🇫🇷',
  ),
  italian(
    code: 'it',
    assetName: 'italian',
    nativeName: 'Italiano',
    englishName: 'Italian',
    shortCode: 'IT',
    badge: '🇮🇹',
  ),
  portuguese(
    code: 'pt',
    assetName: 'portuguese',
    nativeName: 'Português',
    englishName: 'Portuguese',
    shortCode: 'PT',
    badge: '🇵🇹',
  ),
  czech(
    code: 'cs',
    assetName: 'czech',
    nativeName: 'Čeština',
    englishName: 'Czech',
    shortCode: 'CS',
    badge: '🇨🇿',
  ),
  japanese(
    code: 'ja',
    assetName: 'japanese',
    nativeName: '日本語',
    englishName: 'Japanese',
    shortCode: 'JA',
    badge: '🇯🇵',
  ),
  korean(
    code: 'ko',
    assetName: 'korean',
    nativeName: '한국어',
    englishName: 'Korean',
    shortCode: 'KO',
    badge: '🇰🇷',
  ),
  chineseSimplified(
    code: 'zh-Hans',
    assetName: 'chinese_simplified',
    nativeName: '简体中文',
    englishName: 'Chinese (Simplified)',
    shortCode: '简',
    badge: '🇨🇳',
  ),
  chineseTraditional(
    code: 'zh-Hant',
    assetName: 'chinese_traditional',
    nativeName: '繁體中文',
    englishName: 'Chinese (Traditional)',
    shortCode: '繁',
    badge: '🇹🇼',
  );

  final String code;
  final String assetName;
  final String nativeName;
  final String englishName;
  final String shortCode;
  final String badge;

  const Bip39Language({
    required this.code,
    required this.assetName,
    required this.nativeName,
    required this.englishName,
    required this.shortCode,
    required this.badge,
  });

  String get assetPath => 'assets/wordlists/$assetName.json';
}

class Bip39WordlistData {
  final Bip39Language language;
  final List<String> words; // NFC-normalized display words (length 2048)
  final List<String> rawWords; // Original JSON words from bitcoinjs/bip39
  final List<String> foldedWords; // Accent-folded lowercase words for fuzzy prefix search
  final Map<String, int> lookupMap; // Maps NFC, NFKD, and lowercase forms -> 0..2047

  Bip39WordlistData({
    required this.language,
    required this.words,
    required this.rawWords,
    required this.foldedWords,
    required this.lookupMap,
  });

  int? indexOfWord(String word) {
    final trimmed = word.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    return lookupMap[trimmed] ?? lookupMap[Bip39WordlistService.toNfc(trimmed)];
  }

  bool containsWord(String word) => indexOfWord(word) != null;

  String canonicalWord(String word) {
    final idx = indexOfWord(word);
    if (idx != null) return words[idx];
    return Bip39WordlistService.toNfc(word.trim().toLowerCase());
  }
}

class Bip39LanguageDetectionResult {
  final Bip39Language language;
  final bool isConfident;
  final int matchedWords;

  const Bip39LanguageDetectionResult({
    required this.language,
    required this.isConfident,
    required this.matchedWords,
  });
}

class Bip39WordlistService {
  Bip39WordlistService._();
  static final Bip39WordlistService instance = Bip39WordlistService._();

  final Map<Bip39Language, Bip39WordlistData> _cache = {};
  Future<void>? _preloadFuture;

  bool get isLoaded => _cache.length == Bip39Language.values.length;

  /// Preloads all 10 BIP39 wordlists from assets/wordlists/*.json.
  Future<void> ensureLoaded() {
    return _preloadFuture ??= _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait(Bip39Language.values.map(loadLanguage));
  }

  Future<Bip39WordlistData> loadLanguage(Bip39Language language) async {
    final cached = _cache[language];
    if (cached != null) return cached;

    final jsonStr = await rootBundle.loadString(language.assetPath);
    final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
    final rawWords = decoded.cast<String>();
    final words = List<String>.generate(
      rawWords.length,
      (i) => toNfc(rawWords[i]),
      growable: false,
    );
    final foldedWords = List<String>.generate(
      words.length,
      (i) => foldAccents(words[i]),
      growable: false,
    );

    final lookup = <String, int>{};
    for (int i = 0; i < words.length; i++) {
      lookup[rawWords[i].toLowerCase()] = i;
      lookup[words[i].toLowerCase()] = i;
    }

    final data = Bip39WordlistData(
      language: language,
      words: words,
      rawWords: rawWords,
      foldedWords: foldedWords,
      lookupMap: lookup,
    );
    _cache[language] = data;
    return data;
  }

  Bip39WordlistData? getLoaded(Bip39Language language) => _cache[language];

  /// Generates a valid BIP39 mnemonic of [count] words in [language].
  /// Uses Rust's CSPRNG + BIP39 entropy generator and maps the 11-bit indices
  /// (0..2047) to the chosen [language]'s wordlist.
  Future<List<String>> generateWords({
    required int count,
    required Bip39Language language,
  }) async {
    await ensureLoaded();
    final enWordsStr = await genBip39Words(count: count);
    final enList = enWordsStr.trim().split(RegExp(r'\s+'));
    if (language == Bip39Language.english) {
      return enList;
    }

    final enData = _cache[Bip39Language.english]!;
    final targetData = _cache[language]!;

    return enList.map((w) {
      final idx = enData.indexOfWord(w);
      if (idx == null || idx < 0 || idx >= targetData.words.length) {
        return w;
      }
      return targetData.words[idx];
    }).toList();
  }

  /// Automatically detects the BIP39 language from already entered words and/or
  /// the current typing draft.
  Bip39LanguageDetectionResult detectLanguage(
    List<String> enteredWords, {
    String currentDraft = '',
  }) {
    if (_cache.isEmpty) {
      return const Bip39LanguageDetectionResult(
        language: Bip39Language.english,
        isConfident: false,
        matchedWords: 0,
      );
    }

    final nonEmpty = enteredWords
        .map((w) => toNfc(w.trim().toLowerCase()))
        .where((w) => w.isNotEmpty)
        .toList();
    final draft = toNfc(currentDraft.trim().toLowerCase());

    if (nonEmpty.isEmpty && draft.isEmpty) {
      return const Bip39LanguageDetectionResult(
        language: Bip39Language.english,
        isConfident: false,
        matchedWords: 0,
      );
    }

    Bip39Language bestLang = Bip39Language.english;
    int bestExactScore = -1;
    int bestDraftScore = -1;

    for (final lang in Bip39Language.values) {
      final data = _cache[lang];
      if (data == null) continue;

      int exactMatches = 0;
      for (final word in nonEmpty) {
        if (data.containsWord(word)) {
          exactMatches++;
        } else {
          final folded = foldAccents(word);
          if (folded.isNotEmpty && data.foldedWords.contains(folded)) {
            exactMatches++;
          }
        }
      }

      int draftMatches = 0;
      if (draft.isNotEmpty) {
        final foldedDraft = foldAccents(draft);
        for (int i = 0; i < data.words.length; i++) {
          if (data.words[i].startsWith(draft) ||
              (foldedDraft.isNotEmpty &&
                  data.foldedWords[i].startsWith(foldedDraft))) {
            draftMatches = 1;
            if (data.words[i] == draft) {
              draftMatches = 2;
              break;
            }
          }
        }
      }

      if (exactMatches > bestExactScore ||
          (exactMatches == bestExactScore && draftMatches > bestDraftScore)) {
        bestExactScore = exactMatches;
        bestDraftScore = draftMatches;
        bestLang = lang;
      }
    }

    final isConfident = bestExactScore > 0 || bestDraftScore > 0;
    return Bip39LanguageDetectionResult(
      language: isConfident ? bestLang : Bip39Language.english,
      isConfident: isConfident,
      matchedWords: bestExactScore > 0 ? bestExactScore : 0,
    );
  }

  /// Returns indices (0-based) of words in [words] that do not exist in [language].
  List<int> findInvalidWordIndices(
    List<String> words, {
    Bip39Language? language,
  }) {
    final lang = language ?? detectLanguage(words).language;
    final data = _cache[lang];
    if (data == null) return const [];

    final invalidIndices = <int>[];
    for (int i = 0; i < words.length; i++) {
      final w = words[i].trim();
      if (w.isEmpty) continue;
      if (!data.containsWord(w)) {
        invalidIndices.add(i);
      }
    }
    return invalidIndices;
  }

  /// Validates the BIP39 SHA-256 checksum for a phrase in any supported language.
  /// Since BIP39 checksum is defined over the 11-bit word indices (0..2047),
  /// mapping valid localized words to their corresponding 0..2047 indices in
  /// English allows Rust's `bip39ChecksumValid` to verify checksums for all 10 languages.
  Future<bool> validateChecksum(
    List<String> words, {
    Bip39Language? language,
  }) async {
    await ensureLoaded();
    final nonEmpty = words.map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    if (nonEmpty.length != words.length) return false;

    final lang = language ?? detectLanguage(words).language;
    final data = _cache[lang];
    final enData = _cache[Bip39Language.english];
    if (data == null || enData == null) {
      return bip39ChecksumValid(words: words.join(' '));
    }

    final mappedEnglish = <String>[];
    for (final w in words) {
      final idx = data.indexOfWord(w);
      if (idx == null) return false;
      mappedEnglish.add(enData.words[idx]);
    }

    return bip39ChecksumValid(words: mappedEnglish.join(' '));
  }

  /// Returns up to [limit] autocomplete suggestions for [query].
  List<String> getSuggestions(
    String query, {
    Bip39Language? preferredLanguage,
    List<String> contextWords = const [],
    int limit = 8,
  }) {
    final normalized = toNfc(query.trim().toLowerCase());
    if (normalized.isEmpty || _cache.isEmpty) return const [];

    final foldedQuery = foldAccents(normalized);
    final detected = preferredLanguage ??
        detectLanguage(contextWords, currentDraft: normalized).language;

    final results = <String>[];
    final seen = <String>{};

    void collectFrom(Bip39Language lang, {required bool exactPrefixOnly}) {
      final data = _cache[lang];
      if (data == null) return;

      for (int i = 0; i < data.words.length; i++) {
        if (results.length >= limit) return;
        final w = data.words[i];
        if (exactPrefixOnly) {
          if (w.startsWith(normalized)) {
            if (seen.add(w)) results.add(w);
          }
        } else {
          if (foldedQuery.isNotEmpty &&
              data.foldedWords[i].startsWith(foldedQuery)) {
            if (seen.add(w)) results.add(w);
          }
        }
      }
    }

    // 1. Exact NFC prefix matches in detected/preferred language
    collectFrom(detected, exactPrefixOnly: true);
    // 2. Accent-folded prefix matches in detected/preferred language
    if (results.length < limit) {
      collectFrom(detected, exactPrefixOnly: false);
    }
    // 3. If no context words lock the language yet, also check other languages
    final hasLockedContext =
        contextWords.any((w) => w.trim().isNotEmpty);
    if (!hasLockedContext && results.length < limit) {
      for (final lang in Bip39Language.values) {
        if (lang == detected) continue;
        collectFrom(lang, exactPrefixOnly: true);
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Normalizes NFKD strings from bitcoinjs/bip39 (Hangul Jamo, Japanese dakuten,
  /// and Latin combining accents) to precomposed NFC strings matching OS keyboards.
  static String toNfc(String input) {
    if (input.isEmpty) return input;
    final runes = input.runes.toList(growable: false);
    final out = <int>[];

    int i = 0;
    while (i < runes.length) {
      final r = runes[i];

      // Hangul Jamo composition (L: 0x1100..0x1112, V: 0x1161..0x1175, T: 0x11A8..0x11C2)
      if (r >= 0x1100 && r <= 0x1112 && i + 1 < runes.length) {
        final v = runes[i + 1];
        if (v >= 0x1161 && v <= 0x1175) {
          final lIndex = r - 0x1100;
          final vIndex = v - 0x1161;
          int tIndex = 0;
          if (i + 2 < runes.length) {
            final t = runes[i + 2];
            if (t >= 0x11A8 && t <= 0x11C2) {
              tIndex = t - 0x11A7;
              i += 3;
            } else {
              i += 2;
            }
          } else {
            i += 2;
          }
          out.add(0xAC00 + (lIndex * 21 + vIndex) * 28 + tIndex);
          continue;
        }
      }

      // Combining Latin & Japanese marks
      if (i + 1 < runes.length) {
        final next = runes[i + 1];
        final composed = _composePair(r, next);
        if (composed != null) {
          out.add(composed);
          i += 2;
          continue;
        }
      }

      out.add(r);
      i++;
    }

    return String.fromCharCodes(out);
  }

  static int? _composePair(int base, int combining) {
    if (combining == 0x0301) {
      switch (base) {
        case 0x61:
          return 0xE1; // á
        case 0x65:
          return 0xE9; // é
        case 0x69:
          return 0xED; // í
        case 0x6F:
          return 0xF3; // ó
        case 0x75:
          return 0xFA; // ú
        case 0x79:
          return 0xFD; // ý
      }
    } else if (combining == 0x0300) {
      switch (base) {
        case 0x61:
          return 0xE0; // à
        case 0x65:
          return 0xE8; // è
        case 0x69:
          return 0xEC; // ì
        case 0x6F:
          return 0xF2; // ò
        case 0x75:
          return 0xF9; // ù
      }
    } else if (combining == 0x0303) {
      if (base == 0x6E) return 0xF1; // ñ
    } else if (combining == 0x3099) {
      // Hiragana voiced dakuten
      switch (base) {
        case 0x304B:
        case 0x304D:
        case 0x304F:
        case 0x3051:
        case 0x3053:
        case 0x3055:
        case 0x3057:
        case 0x3059:
        case 0x305B:
        case 0x305D:
        case 0x305F:
        case 0x3061:
        case 0x3064:
        case 0x3066:
        case 0x3068:
        case 0x306F:
        case 0x3072:
        case 0x3075:
        case 0x3078:
        case 0x307B:
          return base + 1;
      }
    } else if (combining == 0x309A) {
      // Hiragana semi-voiced handakuten
      switch (base) {
        case 0x306F:
        case 0x3072:
        case 0x3075:
        case 0x3078:
        case 0x307B:
          return base + 2;
      }
    }
    return null;
  }

  /// Strips Latin accents for convenient ASCII keyboard prefix matching.
  static String foldAccents(String input) {
    if (input.isEmpty) return input;
    final sb = StringBuffer();
    for (final r in input.runes) {
      switch (r) {
        case 0xE0:
        case 0xE1:
        case 0xE2:
        case 0xE3:
        case 0xE4:
          sb.writeCharCode(0x61); // a
          break;
        case 0xE7:
        case 0x010D:
          sb.writeCharCode(0x63); // c
          break;
        case 0x010F:
          sb.writeCharCode(0x64); // d
          break;
        case 0xE8:
        case 0xE9:
        case 0xEA:
        case 0xEB:
        case 0x011B:
          sb.writeCharCode(0x65); // e
          break;
        case 0xEC:
        case 0xED:
        case 0xEE:
        case 0xEF:
          sb.writeCharCode(0x69); // i
          break;
        case 0xF1:
        case 0x0148:
          sb.writeCharCode(0x6E); // n
          break;
        case 0xF2:
        case 0xF3:
        case 0xF4:
        case 0xF5:
        case 0xF6:
          sb.writeCharCode(0x6F); // o
          break;
        case 0x0159:
          sb.writeCharCode(0x72); // r
          break;
        case 0x0161:
          sb.writeCharCode(0x73); // s
          break;
        case 0x0165:
          sb.writeCharCode(0x74); // t
          break;
        case 0xF9:
        case 0xFA:
        case 0xFB:
        case 0xFC:
        case 0x016F:
          sb.writeCharCode(0x75); // u
          break;
        case 0xFD:
        case 0xFF:
          sb.writeCharCode(0x79); // y
          break;
        case 0x017E:
          sb.writeCharCode(0x7A); // z
          break;
        case 0x0300:
        case 0x0301:
        case 0x0302:
        case 0x0303:
        case 0x0308:
        case 0x0327:
          // skip combining Latin marks
          break;
        default:
          sb.writeCharCode(r);
      }
    }
    return sb.toString();
  }
}
