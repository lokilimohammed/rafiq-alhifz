import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(RafiqAlHifzFullApp(prefs: prefs));
}

// ============================================================================
// نظام التصميم الشامل (Design System)
// ============================================================================
class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color mushafPaper = Color(0xFFFBF8F1);
  static const Color background = Color(0xFFF8FAFC);

  static const Color wordDefault = Color(0xFF1E293B);
  static const Color wordCorrect = Color(0xFF10B981);
  static const Color wordTajweedWarning = Color(0xFFF97316);
  static const Color wordError = Color(0xFFEF4444);
}

// ============================================================================
// نماذج البيانات
// ============================================================================
enum WordEvalStatus { pending, correct, tajweedWarning, error }

class WordEvaluation {
  final int verseIndex;
  final int wordIndex;
  final String expectedWord;
  final String spokenWord;
  final WordEvalStatus status;
  final int makharijScore;
  final String tajweedRule;
  final String feedbackNote;

  WordEvaluation({
    required this.verseIndex,
    required this.wordIndex,
    required this.expectedWord,
    required this.spokenWord,
    required this.status,
    required this.makharijScore,
    required this.tajweedRule,
    required this.feedbackNote,
  });
}

class ReviewItem {
  final int pageNumber;
  final String surahTitle;
  int memoryStrength;
  int intervalDays;
  bool dueToday;
  int lastAccuracy;

  ReviewItem({
    required this.pageNumber,
    required this.surahTitle,
    required this.memoryStrength,
    required this.intervalDays,
    required this.dueToday,
    required this.lastAccuracy,
  });
}

class LoggedErrorItem {
  final String id;
  final int pageNumber;
  final int ayahNumber;
  final String expectedWord;
  final String spokenWord;
  final String category;
  final int makharijScore;
  final String note;
  bool overriddenByParent;

  LoggedErrorItem({
    required this.id,
    required this.pageNumber,
    required this.ayahNumber,
    required this.expectedWord,
    required this.spokenWord,
    required this.category,
    required this.makharijScore,
    required this.note,
    this.overriddenByParent = false,
  });
}

class MapNodeItem {
  final int pageNumber;
  final String title;
  String status;
  int masteryScore;
  int repetitionsLogged;

  MapNodeItem({
    required this.pageNumber,
    required this.title,
    required this.status,
    required this.masteryScore,
    required this.repetitionsLogged,
  });
}

class VerseData {
  final int ayahNumber;
  final String surahName;
  final String audioUrl;
  final List<String> words;

  VerseData({
    required this.ayahNumber,
    required this.surahName,
    required this.audioUrl,
    required this.words,
  });
}

class MushafPageData {
  final int pageNumber;
  final String surahHeader;
  final int juz;
  final int hizbQuarter;
  final List<VerseData> verses;

  MushafPageData({
    required this.pageNumber,
    required this.surahHeader,
    required this.juz,
    required this.hizbQuarter,
    required this.verses,
  });
}

final Map<int, MushafPageData> kOfflinePresetPages = {
  604: MushafPageData(
    pageNumber: 604,
    surahHeader: 'سورة الإخلاص والمعوذتين (الجزء 30)',
    juz: 30,
    hizbQuarter: 240,
    verses: [
      VerseData(ayahNumber: 1, surahName: 'الإخلاص', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/112001.mp3', words: ['قُلْ', 'هُوَ', 'اللَّهُ', 'أَحَدٌ']),
      VerseData(ayahNumber: 2, surahName: 'الإخلاص', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/112002.mp3', words: ['اللَّهُ', 'الصَّمَدُ']),
      VerseData(ayahNumber: 3, surahName: 'الإخلاص', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/112003.mp3', words: ['لَمْ', 'يَلِدْ', 'وَلَمْ', 'يُولَدْ']),
      VerseData(ayahNumber: 4, surahName: 'الإخلاص', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/112004.mp3', words: ['وَلَمْ', 'يَكُن', 'لَّهُ', 'كُفُوًا', 'أَحَدٌ']),
    ],
  ),
  582: MushafPageData(
    pageNumber: 582,
    surahHeader: 'سورة النبأ (الجزء 30)',
    juz: 30,
    hizbQuarter: 233,
    verses: [
      VerseData(ayahNumber: 1, surahName: 'النبأ', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/078001.mp3', words: ['عَمَّ', 'يَتَسَاءَلُونَ']),
      VerseData(ayahNumber: 2, surahName: 'النبأ', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/078002.mp3', words: ['عَنِ', 'النَّبَإِ', 'الْعَظِيمِ']),
      VerseData(ayahNumber: 3, surahName: 'النبأ', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/078003.mp3', words: ['الَّذِي', 'هُمْ', 'فِيهِ', 'مُخْتَلِفُونَ']),
      VerseData(ayahNumber: 4, surahName: 'النبأ', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/078004.mp3', words: ['كَلَّا', 'سَيَعْلَمُونَ']),
      VerseData(ayahNumber: 5, surahName: 'النبأ', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/078005.mp3', words: ['ثُمَّ', 'كَلَّا', 'سَيَعْلَمُونَ']),
    ],
  ),
  1: MushafPageData(
    pageNumber: 1,
    surahHeader: 'سورة الفاتحة (بداية المصحف)',
    juz: 1,
    hizbQuarter: 1,
    verses: [
      VerseData(ayahNumber: 1, surahName: 'الفاتحة', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/001001.mp3', words: ['بِسْمِ', 'اللَّهِ', 'الرَّحْمَٰنِ', 'الرَّحِيمِ']),
      VerseData(ayahNumber: 2, surahName: 'الفاتحة', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/001002.mp3', words: ['الْحَمْدُ', 'لِلَّهِ', 'رَبِّ', 'الْعَالَمِينَ']),
      VerseData(ayahNumber: 3, surahName: 'الفاتحة', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/001003.mp3', words: ['الرَّحْمَٰنِ', 'الرَّحِيمِ']),
      VerseData(ayahNumber: 4, surahName: 'الفاتحة', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/001004.mp3', words: ['مَالِكِ', 'يَوْمِ', 'الدِّينِ']),
      VerseData(ayahNumber: 5, surahName: 'الفاتحة', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/001005.mp3', words: ['إِيَّاكَ', 'نَعْبُدُ', 'وَإِيَّاكَ', 'نَسْتَعِينُ']),
      VerseData(ayahNumber: 6, surahName: 'الفاتحة', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/001006.mp3', words: ['اهْدِنَا', 'الصِّرَاطَ', 'الْمُسْتَقِيمَ']),
      VerseData(ayahNumber: 7, surahName: 'الفاتحة', audioUrl: 'https://everyayah.com/data/Alafasy_128kbps/001007.mp3', words: ['صِرَاطَ', 'الَّذِينَ', 'أَنْعَمْتَ', 'عَلَيْهِمْ', 'غَيْرِ', 'الْمَغْضُوبِ', 'عَلَيْهِمْ', 'وَلَا', 'الضَّالِّينَ']),
    ],
  ),
};

class RafiqAlHifzFullApp extends StatelessWidget {
  final SharedPreferences prefs;
  const RafiqAlHifzFullApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رفيق الحفظ',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accentGold,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: MainPlatformController(prefs: prefs),
    );
  }
}

class MainPlatformController extends StatefulWidget {
  final SharedPreferences prefs;
  const MainPlatformController({super.key, required this.prefs});

  @override
  State<MainPlatformController> createState() => _MainPlatformControllerState();
}

class _MainPlatformControllerState extends State<MainPlatformController> {
  int _selectedNavIndex = 1;

  late String _planDirection;
  late String _dailyWirdType;
  late int _mandatoryRepetitions;
  late double _maxAllowedErrorRate;
  late int _minTajweedScore;
  late int _dailyMandatoryReviewQuarters;

  late bool _isReviewCompleted;
  late int _completedRepetitions;
  late bool _isSessionPassed;
  late int _bestAccuracyScore;
  late int _bestTajweedScore;

  late String _childName;
  late int _totalStars;
  late int _streakDays;
  late List<String> _badges;

  int _currentPageNumber = 582;
  MushafPageData _activePageData = kOfflinePresetPages[582]!;
  bool _isLoadingPage = false;
  bool _hideTextForRecitation = false;
  int _selectedVerseIndex = 0;
  double _playbackSpeed = 1.0;
  bool _loopAudio = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isMicListening = false;
  String _currentMicMode = 'repetition';
  String _lastSpokenTranscript = '';

  final Map<String, WordEvaluation> _wordEvaluations = {};
  String _sirajCompanionMessage = 'أهلاً بك يا بطل! تذكّر: لا يفتح الحفظ الجديد إلا بعد إتمام مراجعة اليوم الإجبارية.';

  late List<ReviewItem> _reviewsList;
  late List<MapNodeItem> _mapNodes;
  final List<LoggedErrorItem> _errorsLog = [];
  final List<String> _parentNotifications = [
    '⏰ تذكير يومي: حان موعد ورد المراجعة والحفظ للبطل أحمد.',
  ];

  bool _isParentPinUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
    _setupAudioPlayerListeners();
  }

  void _loadPersistedData() {
    final p = widget.prefs;
    _planDirection = p.getString('planDirection') ?? 'nas_to_fatiha';
    _dailyWirdType = p.getString('dailyWirdType') ?? 'page';
    _mandatoryRepetitions = p.getInt('mandatoryRepetitions') ?? 5;
    _maxAllowedErrorRate = p.getDouble('maxAllowedErrorRate') ?? 0.10;
    _minTajweedScore = p.getInt('minTajweedScore') ?? 75;
    _dailyMandatoryReviewQuarters = p.getInt('dailyReviewQuarters') ?? 2;

    _isReviewCompleted = p.getBool('isReviewCompleted') ?? false;
    _completedRepetitions = p.getInt('completedRepetitions') ?? 0;
    _isSessionPassed = p.getBool('isSessionPassed') ?? false;
    _bestAccuracyScore = p.getInt('bestAccuracyScore') ?? 0;
    _bestTajweedScore = p.getInt('bestTajweedScore') ?? 0;

    _childName = p.getString('childName') ?? 'أحمد';
    _totalStars = p.getInt('totalStars') ?? 120;
    _streakDays = p.getInt('streakDays') ?? 6;
    _badges = p.getStringList('badges') ?? ['🌟 بداية النور', '🛡️ صديق المصحف'];

    _reviewsList = [
      ReviewItem(
        pageNumber: 604,
        surahTitle: 'سورة الإخلاص والمعوذتين (صفحة 604)',
        memoryStrength: _isReviewCompleted ? 92 : 65,
        intervalDays: _isReviewCompleted ? 3 : 1,
        dueToday: !_isReviewCompleted,
        lastAccuracy: 92,
      ),
      ReviewItem(
        pageNumber: 1,
        surahTitle: 'سورة الفاتحة (صفحة 1)',
        memoryStrength: 96,
        intervalDays: 7,
        dueToday: false,
        lastAccuracy: 100,
      ),
    ];

    _mapNodes = [
      MapNodeItem(pageNumber: 1, title: 'سورة الفاتحة', status: 'memorized', masteryScore: 98, repetitionsLogged: 100),
      MapNodeItem(
        pageNumber: 604,
        title: 'سورة الإخلاص والمعوذتين',
        status: _isReviewCompleted ? 'memorized' : 'needs_review',
        masteryScore: _isReviewCompleted ? 95 : 70,
        repetitionsLogged: 100,
      ),
      MapNodeItem(
        pageNumber: 582,
        title: 'سورة النبأ (ورد اليوم)',
        status: _isSessionPassed ? 'memorized' : 'in_progress',
        masteryScore: _isSessionPassed ? _bestAccuracyScore : 45,
        repetitionsLogged: _completedRepetitions,
      ),
      MapNodeItem(pageNumber: 583, title: 'تكملة سورة النبأ', status: 'locked', masteryScore: 0, repetitionsLogged: 0),
      MapNodeItem(pageNumber: 584, title: 'سورة النازعات', status: 'locked', masteryScore: 0, repetitionsLogged: 0),
    ];
  }

  Future<void> _saveStateToDisk() async {
    final p = widget.prefs;
    await p.setString('planDirection', _planDirection);
    await p.setString('dailyWirdType', _dailyWirdType);
    await p.setInt('mandatoryRepetitions', _mandatoryRepetitions);
    await p.setDouble('maxAllowedErrorRate', _maxAllowedErrorRate);
    await p.setInt('minTajweedScore', _minTajweedScore);
    await p.setInt('dailyReviewQuarters', _dailyMandatoryReviewQuarters);

    await p.setBool('isReviewCompleted', _isReviewCompleted);
    await p.setInt('completedRepetitions', _completedRepetitions);
    await p.setBool('isSessionPassed', _isSessionPassed);
    await p.setInt('bestAccuracyScore', _bestAccuracyScore);
    await p.setInt('bestTajweedScore', _bestTajweedScore);

    await p.setInt('totalStars', _totalStars);
    await p.setInt('streakDays', _streakDays);
    await p.setStringList('badges', _badges);
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (_loopAudio) {
        _playSelectedVerseAudio();
      }
    });
  }

  Future<void> _loadMushafPage(int pageNumber) async {
    final clampedPage = pageNumber.clamp(1, 604);
    if (kOfflinePresetPages.containsKey(clampedPage)) {
      setState(() {
        _currentPageNumber = clampedPage;
        _activePageData = kOfflinePresetPages[clampedPage]!;
        _selectedVerseIndex = 0;
        _wordEvaluations.clear();
      });
      return;
    }

    setState(() => _isLoadingPage = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/page/$clampedPage/quran-uthmani'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List ayahs = decoded['data']['ayahs'];
        final List<VerseData> loadedVerses = ayahs.take(8).map<VerseData>((a) {
          final String text = a['text'] ?? '';
          final List<String> words =
              text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
          return VerseData(
            ayahNumber: a['numberInSurah'] ?? 1,
            surahName: a['surah']['name'] ?? 'سورة',
            audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${a['number']}.mp3',
            words: words,
          );
        }).toList();

        setState(() {
          _currentPageNumber = clampedPage;
          _activePageData = MushafPageData(
            pageNumber: clampedPage,
            surahHeader: '${ayahs.first['surah']['name']} (صفحة $clampedPage من 604)',
            juz: ayahs.first['juz'] ?? 1,
            hizbQuarter: ayahs.first['hizbQuarter'] ?? 1,
            verses: loadedVerses,
          );
          _selectedVerseIndex = 0;
          _wordEvaluations.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر جلب الصفحة من الإنترنت؛ يرجى التحقق من الاتصال.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  Future<void> _playSelectedVerseAudio() async {
    if (_activePageData.verses.isEmpty) return;
    final verse = _activePageData.verses[_selectedVerseIndex];
    await _audioPlayer.stop();
    await _audioPlayer.setPlaybackRate(_playbackSpeed);
    await _audioPlayer.play(UrlSource(verse.audioUrl));
  }

  String _normalizeArabicWord(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\u0621-\u064A]'), '')
        .trim();
  }

  Map<String, dynamic> _analyzeMakharijAndTajweed(String word, {bool simulateError = false}) {
    if (simulateError) {
      return {
        'score': 64,
        'rule': 'مخرج الضاد/الظاء أو مقدار المد',
        'note': 'تحتاج لتحسين مخرج الحرف وضبط التشكيل في ($word)',
      };
    }
    if (word.contains('الضَّالِّينَ') || word.contains('الْمَغْضُوبِ')) {
      return {
        'score': 91,
        'rule': 'مخرج الضاد والمد اللازم',
        'note': 'احرص على استطالة الضاد وإتمام المد اللازم 6 حركات',
      };
    }
    if (word.contains('الْعَظِيمِ')) {
      return {
        'score': 94,
        'rule': 'مخرج الظاء',
        'note': 'إخراج طرف اللسان في حرف الظاء مع التفخيم',
      };
    }
    if (word.contains('أَحَدٌ') || word.contains('يَلِدْ') || word.contains('يُولَدْ') || word.contains('النَّبَإِ')) {
      return {
        'score': 95,
        'rule': 'القلقلة',
        'note': 'قلقلة واضحة ومتقنة في نهاية الكلمة',
      };
    }
    if (word.contains('يَتَسَاءَلُونَ')) {
      return {
        'score': 88,
        'rule': 'المد المتصل',
        'note': 'تنبيه تجويدي: راعِ مقدار المد المتصل (4-5 حركات)',
      };
    }
    return {
      'score': 98,
      'rule': 'مخارج سليمة',
      'note': 'نطق متقن وحركات تشكيل صحيحة',
    };
  }

  Future<void> _startRealMicrophoneSession(String mode) async {
    if (!_isReviewCompleted && mode != 'review_test') {
      setState(() {
        _sirajCompanionMessage = '⛔ بوابة الحفظ الجديد مقفلة! يجب إتمام مراجعة اليوم الإجبارية أولاً.';
        _selectedNavIndex = 0;
      });
      return;
    }

    setState(() {
      _currentMicMode = mode;
      _wordEvaluations.clear();
      if (mode == 'recitation_test') {
        _hideTextForRecitation = true;
      }
    });

    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isMicListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isMicListening = false);
      },
    );

    if (!available) {
      setState(() {
        _sirajCompanionMessage = '⚠️ خدمة التعرف الصوتي غير مفعلة على هذا الجهاز حالياً؛ يمكنك استخدام أزرار المحاكاة الفورية بالأسفل لاختبار النظام.';
      });
      return;
    }

    setState(() {
      _isMicListening = true;
      _sirajCompanionMessage = '🎙️ سراج يستمع لتلاوتك الآن... اقرأ الآيات بصوت واضح ورتّل بتأنٍّ.';
    });

    await _speechToText.listen(
      localeId: 'ar-SA',
      onResult: (result) {
        setState(() {
          _lastSpokenTranscript = result.recognizedWords;
        });
        if (result.finalResult || result.recognizedWords.split(' ').length >= 4) {
          _evaluateRecitationTranscript(result.recognizedWords, mode);
        }
      },
    );
  }

  Future<void> _stopRealMicrophoneSession() async {
    await _speechToText.stop();
    setState(() => _isMicListening = false);
  }

  void _evaluateRecitationTranscript(
    String transcript,
    String mode, {
    String? simulationPreset,
  }) {
    final spokenWords =
        transcript.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final Map<String, WordEvaluation> newEvaluations = {};
    int totalWords = 0;
    int severeErrorsCount = 0;
    int totalTajweedScore = 0;

    int flatIndex = 0;
    for (int vIdx = 0; vIdx < _activePageData.verses.length; vIdx++) {
      final verse = _activePageData.verses[vIdx];
      for (int wIdx = 0; wIdx < verse.words.length; wIdx++) {
        totalWords++;
        final expected = verse.words[wIdx];
        final normExpected = _normalizeArabicWord(expected);
        final spokenCandidate = flatIndex < spokenWords.length ? spokenWords[flatIndex] : '';

        WordEvalStatus status = WordEvalStatus.correct;
        Map<String, dynamic> tajweedInfo = _analyzeMakharijAndTajweed(expected);

        if (simulationPreset == 'with_errors' && (flatIndex == 1 || flatIndex == 4)) {
          status = flatIndex == 1 ? WordEvalStatus.tajweedWarning : WordEvalStatus.error;
          tajweedInfo = _analyzeMakharijAndTajweed(expected, simulateError: true);
        } else if (simulationPreset == 'perfect') {
          if ((tajweedInfo['score'] as int) < 90) {
            status = WordEvalStatus.tajweedWarning;
          }
        } else {
          final matched = spokenWords.any((sw) => _normalizeArabicWord(sw) == normExpected);
          if (!matched) {
            status = WordEvalStatus.error;
            tajweedInfo = {
              'score': 55,
              'rule': 'كلمة ناقصة أو خطأ تشكيل',
              'note': 'أعد الكلمة ($expected) بوضوح وتأكد من الحركات',
            };
          } else if ((tajweedInfo['score'] as int) < 90) {
            status = WordEvalStatus.tajweedWarning;
          }
        }

        if (status == WordEvalStatus.error) {
          severeErrorsCount++;
        }
        totalTajweedScore += (tajweedInfo['score'] as int);

        final eval = WordEvaluation(
          verseIndex: vIdx,
          wordIndex: wIdx,
          expectedWord: expected,
          spokenWord: spokenCandidate.isEmpty ? expected : spokenCandidate,
          status: status,
          makharijScore: tajweedInfo['score'] as int,
          tajweedRule: tajweedInfo['rule'] as String,
          feedbackNote: tajweedInfo['note'] as String,
        );
        newEvaluations['${vIdx}_$wIdx'] = eval;

        if (status == WordEvalStatus.error || status == WordEvalStatus.tajweedWarning) {
          _errorsLog.insert(
            0,
            LoggedErrorItem(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}_$flatIndex',
              pageNumber: _activePageData.pageNumber,
              ayahNumber: verse.ayahNumber,
              expectedWord: expected,
              spokenWord: spokenCandidate.isEmpty ? 'تلعثم / خطأ تشكيل' : spokenCandidate,
              category: status == WordEvalStatus.error ? 'كلمة خاطئة / تشكيل' : 'ملاحظة مخارج وتجويد',
              makharijScore: tajweedInfo['score'] as int,
              note: tajweedInfo['note'] as String,
            ),
          );
        }

        flatIndex++;
      }
    }

    final double errorRate = totalWords > 0 ? severeErrorsCount / totalWords : 0.0;
    final int accuracyScore = ((1.0 - errorRate) * 100).round().clamp(0, 100);
    final int avgTajweed = totalWords > 0 ? (totalTajweedScore / totalWords).round() : 95;

    setState(() {
      _wordEvaluations
        ..clear()
        ..addAll(newEvaluations);
    });

    if (mode == 'repetition') {
      if (accuracyScore >= 70) {
        setState(() {
          _completedRepetitions++;
          _sirajCompanionMessage = '👏 أحسنت يا بطل! تم احتساب التكرار الصوتي رقم ($_completedRepetitions من $_mandatoryRepetitions) بدقة $accuracyScore%.';
        });
        _saveStateToDisk();
      } else {
        setState(() {
          _sirajCompanionMessage = '⚠️ أعد الآية! لم يُحتسب التكرار لأن نسبة الأخطاء مرتفعة (الدقة $accuracyScore%).';
        });
      }
      return;
    }

    if (mode == 'review_test') {
      if (errorRate <= _maxAllowedErrorRate) {
        setState(() {
          _isReviewCompleted = true;
          for (var r in _reviewsList) {
            if (r.pageNumber == 604) {
              r.dueToday = false;
              r.memoryStrength = 94;
              r.intervalDays = 3;
              r.lastAccuracy = accuracyScore;
            }
          }
          _parentNotifications.insert(
            0,
            '✅ أتم $_childName مراجعة اليوم الإجبارية (ص 604) بدقة $accuracyScore% وفُتحت له بوابة الحفظ الجديد.',
          );
          _sirajCompanionMessage = '🎉 رائع! أتممت مراجعة اليوم بنجاح (قوة الحفظ 94%). فُتحت لك الآن بوابة الحفظ الجديد!';
        });
        _saveStateToDisk();
      } else {
        setState(() {
          for (var r in _reviewsList) {
            if (r.pageNumber == 604) {
              r.memoryStrength = (r.memoryStrength - 15).clamp(25, 100);
              r.intervalDays = 1;
              r.lastAccuracy = accuracyScore;
            }
          }
          _sirajCompanionMessage = '🔄 راجع الكلمات الملونة بالأحمر وأعد التسميع؛ ستبقى المراجعة مجدولة غداً حتى تتقنها.';
        });
      }
      return;
    }

    if (mode == 'recitation_test') {
      if (_completedRepetitions < _mandatoryRepetitions) {
        setState(() {
          _sirajCompanionMessage = '🔒 لا يُمنح الاجتياز إلا بعد إتمام $_mandatoryRepetitions تكرارات صوتية!';
        });
        return;
      }

      final bool passed = errorRate <= _maxAllowedErrorRate && avgTajweed >= _minTajweedScore;

      setState(() {
        _bestAccuracyScore = accuracyScore > _bestAccuracyScore ? accuracyScore : _bestAccuracyScore;
        _bestTajweedScore = avgTajweed > _bestTajweedScore ? avgTajweed : _bestTajweedScore;

        if (passed) {
          _isSessionPassed = true;
          _totalStars += 50;
          _streakDays += 1;
          if (!_badges.contains('🏅 بطل الاجتياز المتقن')) {
            _badges.add('🏅 بطل الاجتياز المتقن');
          }
          for (var node in _mapNodes) {
            if (node.pageNumber == _activePageData.pageNumber) {
              node.status = 'memorized';
              node.masteryScore = accuracyScore;
              node.repetitionsLogged = _completedRepetitions;
            }
          }
          _parentNotifications.insert(
            0,
            '🌟 أتم $_childName ورد اليوم واجتاز التسميع الغيبي بدقة $accuracyScore% ودرجة مخارج $avgTajweed/100!',
          );
          _sirajCompanionMessage = '🏆 مبارك علامة الاجتياز! دقة التلاوة $accuracyScore% ودرجة مخارج الحروف $avgTajweed/100. ربحت 50 نجمة!';
        } else {
          _parentNotifications.insert(
            0,
            '⚠️ حاول $_childName تسميع الورد وحقق دقة $accuracyScore%. يحتاج مراجعة في الكلمات الملونة بالأحمر.',
          );
          _sirajCompanionMessage = '📌 لم يُمنح الاجتياز بعد: الدقة $accuracyScore% (حد الأخطاء المسموح ${(_maxAllowedErrorRate * 100).round()}%). أعد الكلمات الملونة بالأحمر.';
        }
      });
      _saveStateToDisk();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.accentGold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('رفيق الحفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('⭐ $_totalStars | 🔥 $_streakDays يوم', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildThreeGatesBanner(),
            _buildSirajCompanionBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedNavIndex,
                children: [
                  _buildMandatoryReviewScreen(),
                  _buildInteractiveMushafScreen(),
                  _buildMemorizationMapScreen(),
                  _buildGamificationScreen(),
                  _buildParentDashboardScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: !_isReviewCompleted,
                label: const Text('!'),
                child: const Icon(Icons.autorenew_rounded),
              ),
              label: 'المراجعة',
            ),
            const NavigationDestination(icon: Icon(Icons.auto_stories_rounded), label: 'المصحف والتسميع'),
            const NavigationDestination(icon: Icon(Icons.account_tree_rounded), label: 'الخريطة'),
            const NavigationDestination(icon: Icon(Icons.emoji_events_rounded), label: 'إنجازاتي'),
            NavigationDestination(
              icon: Badge(
                label: Text('${_parentNotifications.length}'),
                child: const Icon(Icons.admin_panel_settings_rounded),
              ),
              label: 'الوالدين',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeGatesBanner() {
    final bool repsDone = _completedRepetitions >= _mandatoryRepetitions;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _buildGateChip(title: '1. المراجعة', subtitle: _isReviewCompleted ? 'مكتملة ✅' : 'إجبارية أولاً 🔒', isDone: _isReviewCompleted),
          const SizedBox(width: 6),
          _buildGateChip(title: '2. التكرار', subtitle: '$_completedRepetitions / $_mandatoryRepetitions', isDone: repsDone),
          const SizedBox(width: 6),
          _buildGateChip(title: '3. الاجتياز', subtitle: _isSessionPassed ? 'تم الاجتياز 🏆' : 'قيد التحقق ⏳', isDone: _isSessionPassed),
        ],
      ),
    );
  }

  Widget _buildGateChip({required String title, required String subtitle, required bool isDone}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isDone ? AppColors.wordCorrect.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDone ? AppColors.wordCorrect : Colors.amber.shade700),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Text(subtitle, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSirajCompanionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.primary.withOpacity(0.12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _isMicListening ? AppColors.wordError : AppColors.accentGold,
            child: Icon(_isMicListening ? Icons.mic : Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('سراج: $_sirajCompanionMessage', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMandatoryReviewScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: _isReviewCompleted ? Colors.teal.shade50 : Colors.amber.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isReviewCompleted ? '✅ بوابة المراجعة اليومية مكتملة!' : '🔒 بوابة المراجعة اليومية الإجبارية',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'التطبيق لا يسمح بالانتقال للحفظ الجديد قبل إتمام مراجعة اليوم. كل صفحة لها "قوة حفظ" تُجدول تلقائياً.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._reviewsList.map((rev) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(rev.surahTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      Chip(
                        backgroundColor: rev.dueToday ? Colors.amber.shade700 : AppColors.wordCorrect,
                        label: Text(
                          rev.dueToday ? 'مستحقة اليوم إجبارياً' : 'المراجعة بعد ${rev.intervalDays} أيام',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('قوة الحفظ في الذاكرة: ${rev.memoryStrength}% (آخر دقة: ${rev.lastAccuracy}%)'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: rev.memoryStrength / 100.0,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary,
                  ),
                  if (rev.dueToday) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          icon: const Icon(Icons.mic),
                          label: const Text('تسميع المراجعة بالمايك'),
                          onPressed: () async {
                            await _loadMushafPage(rev.pageNumber);
                            await _startRealMicrophoneSession('review_test');
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('محاكاة إتمام المراجعة بنجاح'),
                          onPressed: () async {
                            await _loadMushafPage(rev.pageNumber);
                            _evaluateRecitationTranscript(
                              'قل هو الله احد الله الصمد لم يلد ولم يولد ولم يكن له كفوا احد',
                              'review_test',
                              simulationPreset: 'perfect',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInteractiveMushafScreen() {
    final bool canStartTest = _isReviewCompleted && _completedRepetitions >= _mandatoryRepetitions;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (!_isReviewCompleted)
          Card(
            color: Colors.amber.shade100,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.lock, color: Colors.deepOrange),
              title: const Text('الحفظ الجديد مقفل حتى إتمام مراجعة اليوم!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              trailing: ElevatedButton(
                onPressed: () => setState(() => _selectedNavIndex = 0),
                child: const Text('اذهب للمراجعة'),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _loadMushafPage(_currentPageNumber - 1),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                Text('صفحة $_currentPageNumber من 604', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                IconButton(
                  onPressed: () => _loadMushafPage(_currentPageNumber + 1),
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                ),
              ],
            ),
            FilterChip(
              selected: _hideTextForRecitation,
              selectedColor: AppColors.accentGold.withOpacity(0.3),
              label: Text(_hideTextForRecitation ? '👁️ إظهار النص' : '🙈 إخفاء للتسميع'),
              onSelected: (val) => setState(() => _hideTextForRecitation = val),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          children: [
            ActionChip(label: const Text('ص 1 (الفاتحة)'), onPressed: () => _loadMushafPage(1)),
            ActionChip(label: const Text('ص 582 (النبأ)'), onPressed: () => _loadMushafPage(582)),
            ActionChip(label: const Text('ص 604 (الإخلاص)'), onPressed: () => _loadMushafPage(604)),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🔁 عدّاد التكرار الإجباري: $_completedRepetitions / $_mandatoryRepetitions',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      _completedRepetitions >= _mandatoryRepetitions ? 'بوابة التسميع مفتوحة 🔓' : 'أكمل التكرار لفتح الاجتياز 🔒',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _completedRepetitions >= _mandatoryRepetitions ? AppColors.wordCorrect : AppColors.wordTajweedWarning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_completedRepetitions / _mandatoryRepetitions).clamp(0.0, 1.0),
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.mushafPaper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentGold, width: 2),
          ),
          child: _isLoadingPage
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              : Column(
                  children: [
                    Text(
                      '${_activePageData.surahHeader} • الجزء ${_activePageData.juz}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15),
                    ),
                    const Divider(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 14,
                      children: [
                        for (int vIdx = 0; vIdx < _activePageData.verses.length; vIdx++) ...[
                          for (int wIdx = 0; wIdx < _activePageData.verses[vIdx].words.length; wIdx++)
                            _buildInteractiveQuranWord(vIdx, wIdx, _activePageData.verses[vIdx].words[wIdx]),
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedVerseIndex = vIdx);
                              _playSelectedVerseAudio();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedVerseIndex == vIdx ? AppColors.accentGold.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '﴿${_activePageData.verses[vIdx].ayahNumber}﴾',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🎙️ التحكم الصوتي والتسميع بالذكاء الاصطناعي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (_lastSpokenTranscript.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('ما سمعه الميكروفون: "$_lastSpokenTranscript"', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMicListening ? AppColors.wordError : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(_isMicListening ? Icons.stop : Icons.mic),
                      label: Text(_isMicListening ? 'إيقاف الميكروفون' : 'تسميع تكرار بالمايك الحقيقي'),
                      onPressed: !_isReviewCompleted
                          ? null
                          : () {
                              if (_isMicListening) {
                                _stopRealMicrophoneSession();
                              } else {
                                _startRealMicrophoneSession('repetition');
                              }
                            },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.plus_one),
                      label: const Text('محاكاة قراءة تكرار سليم (+1)'),
                      onPressed: !_isReviewCompleted
                          ? null
                          : () => _evaluateRecitationTranscript('تلاوة صحيحة', 'repetition', simulationPreset: 'perfect'),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.black87),
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('اختبار الاجتياز الغيبي بالمايك'),
                      onPressed: canStartTest ? () => _startRealMicrophoneSession('recitation_test') : null,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle, color: AppColors.wordCorrect),
                      label: const Text('محاكاة تسميع متقن (اجتياز)'),
                      onPressed: canStartTest
                          ? () {
                              setState(() => _hideTextForRecitation = true);
                              _evaluateRecitationTranscript('تلاوة متقنة', 'recitation_test', simulationPreset: 'perfect');
                            }
                          : null,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.wordError),
                      label: const Text('محاكاة تسميع بأخطاء ومخارج'),
                      onPressed: canStartTest
                          ? () {
                              setState(() => _hideTextForRecitation = true);
                              _evaluateRecitationTranscript('تلاوة بأخطاء', 'recitation_test', simulationPreset: 'with_errors');
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveQuranWord(int vIdx, int wIdx, String word) {
    final key = '${vIdx}_$wIdx';
    final eval = _wordEvaluations[key];

    Color textColor = AppColors.wordDefault;
    Color bgColor = Colors.transparent;

    if (eval != null) {
      if (eval.status == WordEvalStatus.correct) {
        textColor = AppColors.wordCorrect;
        bgColor = AppColors.wordCorrect.withOpacity(0.12);
      } else if (eval.status == WordEvalStatus.tajweedWarning) {
        textColor = AppColors.wordTajweedWarning;
        bgColor = AppColors.wordTajweedWarning.withOpacity(0.15);
      } else if (eval.status == WordEvalStatus.error) {
        textColor = AppColors.wordError;
        bgColor = AppColors.wordError.withOpacity(0.18);
      }
    }

    final bool shouldMask = _hideTextForRecitation && eval == null;

    return GestureDetector(
      onTap: () => setState(() => _selectedVerseIndex = vIdx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: shouldMask ? Colors.grey.shade300 : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: shouldMask ? const Border(bottom: BorderSide(color: Colors.grey, width: 2)) : null,
        ),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: shouldMask ? Colors.transparent : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMemorizationMapScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '🗺️ خريطة الحفظ (${_planDirection == 'nas_to_fatiha' ? 'من الناس ← الفاتحة' : 'من الفاتحة ← الناس'})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 14),
        ..._mapNodes.map((node) {
          IconData icon = Icons.lock_outline;
          Color color = Colors.grey;
          String statusLabel = 'مغلق';

          if (node.status == 'memorized') {
            icon = Icons.check_circle_rounded;
            color = AppColors.wordCorrect;
            statusLabel = 'محفوظ ومتقن';
          } else if (node.status == 'needs_review') {
            icon = Icons.autorenew_rounded;
            color = AppColors.wordTajweedWarning;
            statusLabel = 'يحتاج مراجعة';
          } else if (node.status == 'in_progress') {
            icon = Icons.play_circle_fill_rounded;
            color = Colors.blue;
            statusLabel = 'قيد الحفظ اليوم';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
              title: Text(node.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('صفحة ${node.pageNumber} • الحالة: $statusLabel • الإتقان: ${node.masteryScore}%'),
              trailing: node.status != 'locked'
                  ? ElevatedButton(
                      onPressed: () {
                        _loadMushafPage(node.pageNumber);
                        setState(() => _selectedNavIndex = 1);
                      },
                      child: const Text('فتح'),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGamificationScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🏆 لوحة إنجازات البطل والشارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 32)),
                      Text('$_totalStars', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      const Text('مجموع النجوم'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 32)),
                      Text('$_streakDays أيام', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      const Text('السلسلة اليومية'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('🎖️ الشارات والأوسمة المكتسبة:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _badges.map((b) => Chip(backgroundColor: Colors.teal.shade50, label: Text(b, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
        ),
      ],
    );
  }

  Widget _buildParentDashboardScreen() {
    if (!_isParentPinUnlocked) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text('بوابة الوالدين والمشرفين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('لفتح لوحة الوالدين، اضغط الزر بالأسفل (الرمز التجريبي: 1234).', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('فتح لوحة تحكم الوالدين (1234)'),
                  onPressed: () => setState(() => _isParentPinUnlocked = true),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚙️ ضبط خطة الحفظ وشروط الاجتياز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('عدد التكرارات اليومية الإجبارية:'),
                    DropdownButton<int>(
                      value: _mandatoryRepetitions,
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3 مرات')),
                        DropdownMenuItem(value: 5, child: Text('5 مرات')),
                        DropdownMenuItem(value: 20, child: Text('20 مرة')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _mandatoryRepetitions = val);
                          _saveStateToDisk();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
