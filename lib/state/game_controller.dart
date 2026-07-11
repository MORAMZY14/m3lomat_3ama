import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' hide Category;

import '../core/game_constants.dart';
import '../models/game_models.dart';
import '../services/firebase_service.dart';
import '../services/demo_data.dart';

class GameController extends ChangeNotifier {
  GameController(this._firebase);

  final FirebaseService _firebase;
  final Random _random = Random();

  GamePhase phase = GamePhase.input;
  bool loading = true;
  bool usingDemoData = false;
  String? loadMessage;

  List<CategoryGroup> groups = const [];
  List<GameQuestion> _allQuestions = [];
  List<GameQuestion> _allAudioQuestions = [];

  List<Team> teams = [];
  List<Category> selectedCategories = [];
  List<GameQuestion> questions = [];
  int currentTeamIndex = 0;
  GameQuestion? currentQuestion;
  int selectedPoints = 0;
  final List<TeamHelp> teamHelps = [TeamHelp(), TeamHelp()];
  HelpType? activeHelp;

  Future<void> initialize() async {
    loading = true;
    loadMessage = null;
    notifyListeners();

    try {
      final data = await _firebase.fetchBootstrap();
      _applyBootstrap(data);
      usingDemoData = false;
    } catch (error) {
      _applyBootstrap(DemoData.build());
      usingDemoData = true;
      loadMessage = _firebase.firebaseReady
          ? 'تعذّر تحميل بيانات Firebase. تم تشغيل البيانات التجريبية المحلية.'
          : 'Firebase غير مهيأ لهذه المنصة. تم تشغيل البيانات التجريبية المحلية.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyBootstrap(BootstrapData data) {
    groups = data.groups;
    _allQuestions = data.questions;
    _allAudioQuestions = data.audioQuestions;
  }

  void submitTeams(List<TeamConfig> configs) {
    if (configs.length != 2 || configs.any((config) => config.name.trim().isEmpty)) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    teams = List.generate(
      configs.length,
      (index) => Team(
        id: 'team-$stamp-$index',
        name: configs[index].name.trim(),
        color: configs[index].color,
        icon: configs[index].icon,
      ),
    );
    phase = GamePhase.categories;
    notifyListeners();
  }

  void submitCategories(List<Category> categories) {
    if (categories.length != GameConstants.maxCategories) return;
    selectedCategories = List<Category>.unmodifiable(categories);
    final ids = categories.map((category) => category.id).toSet();
    questions = [
      ..._allQuestions.where((question) => ids.contains(question.categoryId)).map(_freshCopy),
      ..._allAudioQuestions.where((question) => ids.contains(question.categoryId)).map(_freshCopy),
    ];
    currentTeamIndex = _random.nextInt(2);
    phase = GamePhase.intro;
    notifyListeners();
  }

  GameQuestion _freshCopy(GameQuestion question) => GameQuestion(
        id: question.id,
        categoryId: question.categoryId,
        categoryName: question.categoryName,
        points: question.points,
        teamIndex: question.teamIndex,
        difficulty: question.difficulty,
        question: question.question,
        answer: question.answer,
        kind: question.kind,
        imageUrl: question.imageUrl,
        questionImageUrl: question.questionImageUrl,
        audioUrl: question.audioUrl,
        fact: question.fact,
        acceptedAnswers: question.acceptedAnswers,
        answerRule: question.answerRule,
      );

  void completeIntro() {
    phase = GamePhase.board;
    notifyListeners();
  }

  bool hasQuestion(String categoryId, int points, int teamIndex) {
    return questions.any(
      (question) =>
          question.categoryId == categoryId &&
          question.points == points &&
          question.teamIndex == teamIndex,
    );
  }

  bool isAnswered(String categoryId, int points, int teamIndex) {
    final matching = questions.where(
      (question) =>
          question.categoryId == categoryId &&
          question.points == points &&
          question.teamIndex == teamIndex,
    );
    return matching.isNotEmpty && matching.every((question) => question.answered);
  }

  void selectQuestion(String categoryId, int points, int teamIndex) {
    final candidates = questions
        .where(
          (question) =>
              question.categoryId == categoryId &&
              question.points == points &&
              question.teamIndex == teamIndex &&
              !question.answered,
        )
        .toList();
    if (candidates.isEmpty) return;

    currentQuestion = candidates[_random.nextInt(candidates.length)];
    selectedPoints = points;
    currentTeamIndex = teamIndex;
    activeHelp = null;
    phase = GamePhase.question;
    notifyListeners();

    if (!usingDemoData) {
      unawaited(_markUsedSafely(currentQuestion!));
    }
  }

  Future<void> _markUsedSafely(GameQuestion question) async {
    try {
      await _firebase.markQuestionUsed(question);
    } catch (_) {
      // The local game may continue even when the non-critical used flag fails.
    }
  }

  bool useHelp(HelpType type) {
    final helps = teamHelps[currentTeamIndex];
    if (helps.isUsed(type) || activeHelp != null) return false;
    helps.use(type);
    activeHelp = type;
    notifyListeners();
    return true;
  }

  void adjustScore(int teamIndex, int delta) {
    if (teamIndex < 0 || teamIndex >= teams.length) return;
    teams[teamIndex].score += delta;
    notifyListeners();
  }

  void resolveQuestion(int teamIndex, bool correct) {
    final question = currentQuestion;
    if (question == null) return;
    question.answered = true;

    if (correct && teamIndex >= 0 && teamIndex < teams.length) {
      teams[teamIndex].score += selectedPoints;
      if (activeHelp == HelpType.hole) {
        final other = teamIndex == 0 ? 1 : 0;
        teams[other].score -= selectedPoints;
      }
    }

    currentQuestion = null;
    selectedPoints = 0;
    activeHelp = null;
    currentTeamIndex = (currentTeamIndex + 1) % teams.length;
    phase = GamePhase.board;
    notifyListeners();
  }

  bool get allSelectedQuestionsAnswered =>
      questions.isNotEmpty && questions.every((question) => question.answered);

  bool get isAuction => currentQuestion?.categoryId == GameConstants.auctionCategoryId;

  bool get isBedoonKalam => currentQuestion != null &&
      GameConstants.bedoonKalamCategoryIds.contains(currentQuestion!.categoryId);

  bool get isYesNo => currentQuestion != null &&
      GameConstants.yesNoCategoryIds.contains(currentQuestion!.categoryId);

  Future<String?> createChallenge({
    required String content,
    String type = 'text',
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) async {
    if (usingDemoData) return null;
    try {
      return await _firebase.createChallenge(
        content: content,
        type: type,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        metadata: metadata,
      );
    } catch (_) {
      return null;
    }
  }

  void finishGame() {
    phase = GamePhase.end;
    notifyListeners();
  }

  Future<void> restart() async {
    phase = GamePhase.input;
    teams = [];
    selectedCategories = [];
    questions = [];
    currentQuestion = null;
    selectedPoints = 0;
    currentTeamIndex = 0;
    activeHelp = null;
    teamHelps
      ..clear()
      ..addAll([TeamHelp(), TeamHelp()]);
    notifyListeners();
    await initialize();
  }
}
