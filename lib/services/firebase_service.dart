import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game_models.dart';

class FirebaseService {
  FirebaseService({required this.firebaseReady});

  final bool firebaseReady;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> _ensureReadyAndSignedIn() async {
    if (!firebaseReady) {
      throw StateError('Firebase is not configured for this platform.');
    }

    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<BootstrapData> fetchBootstrap() {
    return _fetchBootstrapInternal().timeout(const Duration(seconds: 15));
  }

  Future<BootstrapData> _fetchBootstrapInternal() async {
    await _ensureReadyAndSignedIn();

    final results = await Future.wait([
      _firestore.collection('categoryGroups').get(),
      _firestore.collection('categories').get(),
      _firestore.collection('questions').where('used', isEqualTo: false).get(),
      _firestore
          .collection('audioQuestions')
          .where('used', isEqualTo: false)
          .get(),
    ]);

    final groupSnapshot =
        results[0] as QuerySnapshot<Map<String, dynamic>>;
    final categorySnapshot =
        results[1] as QuerySnapshot<Map<String, dynamic>>;
    final questionSnapshot =
        results[2] as QuerySnapshot<Map<String, dynamic>>;
    final audioSnapshot =
        results[3] as QuerySnapshot<Map<String, dynamic>>;

    final groupRows = groupSnapshot.docs.map((doc) {
      final data = doc.data();
      return _GroupRow(
        id: doc.id,
        name: _stringValue(data['arabicName'] ?? data['name'], doc.id),
        sortOrder: _intValue(data['sortOrder']),
      );
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final categoriesByGroup = <String, List<Category>>{};
    for (final doc in categorySnapshot.docs) {
      final data = doc.data();
      final groupId = _stringValue(data['groupId'], 'default');
      categoriesByGroup.putIfAbsent(groupId, () => <Category>[]).add(
            Category(
              id: doc.id,
              name: _stringValue(
                data['arabicName'] ?? data['name'],
                doc.id,
              ),
              image: _nullableString(
                data['image'] ?? data['categoryImage'] ?? data['imageUrl'],
              ),
            ),
          );
    }

    for (final categories in categoriesByGroup.values) {
      categories.sort((a, b) => a.name.compareTo(b.name));
    }

    final groups = <CategoryGroup>[];
    for (final row in groupRows) {
      final categories = categoriesByGroup.remove(row.id) ?? const <Category>[];
      if (categories.isNotEmpty) {
        groups.add(
          CategoryGroup(
            id: row.id,
            name: row.name,
            categories: categories,
          ),
        );
      }
    }

    // Keep categories visible even when their group document is missing.
    for (final entry in categoriesByGroup.entries) {
      if (entry.value.isEmpty) continue;
      groups.add(
        CategoryGroup(
          id: entry.key,
          name: entry.key == 'default' ? 'الفئات' : entry.key,
          categories: entry.value,
        ),
      );
    }

    if (groups.isEmpty) {
      throw StateError(
        'Firestore contains no categories. Run the demo seed or migrate your data.',
      );
    }

    final questions = questionSnapshot.docs
        .map(
          (doc) => GameQuestion.fromJson(
            <String, dynamic>{'id': doc.id, ...doc.data()},
            kind: QuestionKind.text,
          ),
        )
        .toList();

    final audioQuestions = audioSnapshot.docs
        .map(
          (doc) => GameQuestion.fromJson(
            <String, dynamic>{'id': doc.id, ...doc.data()},
            kind: QuestionKind.audio,
          ),
        )
        .toList();

    return BootstrapData(
      groups: groups,
      questions: questions,
      audioQuestions: audioQuestions,
    );
  }

  Future<void> markQuestionUsed(GameQuestion question) async {
    await _ensureReadyAndSignedIn();
    final collection = question.kind == QuestionKind.audio
        ? 'audioQuestions'
        : 'questions';

    await _firestore.collection(collection).doc(question.id).update({
      'used': true,
      'usedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 10));
  }

  Future<String> createChallenge({
    required String content,
    String type = 'text',
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureReadyAndSignedIn();

    final result = await _functions
        .httpsCallable('createChallenge')
        .call<Map<String, dynamic>>({
      'content': content,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (metadata != null) 'metadata': metadata,
    }).timeout(const Duration(seconds: 15));

    final url = result.data['url']?.toString();
    if (url == null || url.isEmpty) {
      throw StateError('The createChallenge function returned no URL.');
    }
    return url;
  }

  static String _stringValue(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _GroupRow {
  const _GroupRow({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;
}
