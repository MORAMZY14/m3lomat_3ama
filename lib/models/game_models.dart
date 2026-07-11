enum GamePhase { input, categories, intro, board, question, end }

enum HelpType { doubleTime, hole, twoAnswers }

enum QuestionKind { text, audio }

class TeamConfig {
  const TeamConfig({required this.name, required this.color, required this.icon});

  final String name;
  final String color;
  final String icon;
}

class Team {
  Team({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.score = 0,
  });

  final String id;
  final String name;
  final String color;
  final String icon;
  int score;
}

class TeamHelp {
  bool doubleTime = false;
  bool hole = false;
  bool twoAnswers = false;

  bool isUsed(HelpType type) => switch (type) {
        HelpType.doubleTime => doubleTime,
        HelpType.hole => hole,
        HelpType.twoAnswers => twoAnswers,
      };

  void use(HelpType type) {
    switch (type) {
      case HelpType.doubleTime:
        doubleTime = true;
        break;
      case HelpType.hole:
        hole = true;
        break;
      case HelpType.twoAnswers:
        twoAnswers = true;
        break;
    }
  }
}

class Category {
  const Category({required this.id, required this.name, this.image});

  final String id;
  final String name;
  final String? image;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        image: (json['image'] ?? json['categoryImage'])?.toString(),
      );
}

class CategoryGroup {
  const CategoryGroup({required this.id, required this.name, required this.categories});

  final String id;
  final String name;
  final List<Category> categories;

  factory CategoryGroup.fromJson(Map<String, dynamic> json) => CategoryGroup(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        categories: (json['categories'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Category.fromJson)
            .toList(),
      );
}

class GameQuestion {
  GameQuestion({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.points,
    required this.teamIndex,
    required this.difficulty,
    required this.question,
    required this.answer,
    this.kind = QuestionKind.text,
    this.imageUrl,
    this.questionImageUrl,
    this.audioUrl,
    this.fact,
    this.acceptedAnswers = const [],
    this.answerRule,
    this.answered = false,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final int points;
  final int teamIndex;
  final String difficulty;
  final String question;
  final String answer;
  final QuestionKind kind;
  final String? imageUrl;
  final String? questionImageUrl;
  final String? audioUrl;
  final String? fact;
  final List<String> acceptedAnswers;
  final String? answerRule;
  bool answered;

  factory GameQuestion.fromJson(Map<String, dynamic> json, {QuestionKind? kind}) {
    final accepted = json['acceptedAnswers'] ?? json['accepted_answers'];
    return GameQuestion(
      id: json['id']?.toString() ?? '',
      categoryId: (json['categoryId'] ?? json['category_id'])?.toString() ?? '',
      categoryName: (json['categoryName'] ?? json['category_name'])?.toString() ?? '',
      points: _asInt(json['points']),
      teamIndex: _asInt(json['teamIndex'] ?? json['team_index']),
      difficulty: json['difficulty']?.toString() ?? 'easy',
      question: (json['question'] ?? json['questionText'] ?? json['question_text'])?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      kind: kind ?? (json['audioUrl'] != null || json['audio_url'] != null ? QuestionKind.audio : QuestionKind.text),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['revealImageUrl'] ?? json['reveal_image_url'])?.toString(),
      questionImageUrl: (json['questionImageUrl'] ?? json['question_image_url'])?.toString(),
      audioUrl: (json['audioUrl'] ?? json['audio_url'])?.toString(),
      fact: (json['fact'] ?? json['transcript'])?.toString(),
      acceptedAnswers: accepted is List ? accepted.map((value) => value.toString()).toList() : const [],
      answerRule: (json['answerRule'] ?? json['answer_rule'])?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class BootstrapData {
  const BootstrapData({
    required this.groups,
    required this.questions,
    required this.audioQuestions,
  });

  final List<CategoryGroup> groups;
  final List<GameQuestion> questions;
  final List<GameQuestion> audioQuestions;
}
