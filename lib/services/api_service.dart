import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/game_models.dart';

class ApiService {
  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = (baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:3000',
        ))
            .replaceAll(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<BootstrapData> fetchBootstrap() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/mobile/bootstrap?unusedOnly=true'))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw ApiException('تعذّر تحميل بيانات اللعبة', response.statusCode);
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid bootstrap response');
    }

    final groups = (body['groups'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryGroup.fromJson)
        .toList();
    final questions = (body['questions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((json) => GameQuestion.fromJson(json, kind: QuestionKind.text))
        .toList();
    final audioQuestions = (body['audioQuestions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((json) => GameQuestion.fromJson(json, kind: QuestionKind.audio))
        .toList();

    if (groups.isEmpty) {
      throw const FormatException('The API returned no categories');
    }

    return BootstrapData(
      groups: groups,
      questions: questions,
      audioQuestions: audioQuestions,
    );
  }

  Future<void> markQuestionUsed(GameQuestion question) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/mobile/mark-used'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'id': question.id,
            'type': question.kind == QuestionKind.audio ? 'audio' : 'question',
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('تعذّر تحديث السؤال', response.statusCode);
    }
  }

  Future<String> createChallenge({
    required String content,
    String type = 'text',
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/mobile/challenges'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'type': type,
            'content': content,
            if (imageUrl != null) 'imageUrl': imageUrl,
            if (audioUrl != null) 'audioUrl': audioUrl,
            if (metadata != null) 'metadata': metadata,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw ApiException('تعذّر إنشاء تحدي QR', response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final id = body['id']?.toString();
    if (id == null || id.isEmpty) throw const FormatException('Missing challenge id');
    return '$baseUrl/challenge/$id';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => '$message ($statusCode)';
}
