import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'models/game_models.dart';
import 'screens/auction_screen.dart';
import 'screens/category_selection_screen.dart';
import 'screens/cinematic_intro_screen.dart';
import 'screens/end_game_screen.dart';
import 'screens/game_board_screen.dart';
import 'screens/qr_challenge_screen.dart';
import 'screens/question_screen.dart';
import 'screens/team_input_screen.dart';
import 'services/firebase_service.dart';
import 'state/game_controller.dart';

/// Start Flutter immediately. Firebase is initialized behind a visible startup
/// screen so a slow or unavailable Firebase connection can never leave Chrome
/// showing an empty page before [runApp] is called.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Ma3lomatBootstrap());
}

class _FirebaseBootstrapResult {
  const _FirebaseBootstrapResult({
    required this.ready,
    this.error,
  });

  final bool ready;
  final Object? error;
}

class Ma3lomatBootstrap extends StatefulWidget {
  const Ma3lomatBootstrap({super.key});

  @override
  State<Ma3lomatBootstrap> createState() => _Ma3lomatBootstrapState();
}

class _Ma3lomatBootstrapState extends State<Ma3lomatBootstrap> {
  late final Future<_FirebaseBootstrapResult> _firebaseFuture =
      _initializeFirebase();

  Future<_FirebaseBootstrapResult> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 12));
      return const _FirebaseBootstrapResult(ready: true);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Firebase initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return _FirebaseBootstrapResult(ready: false, error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FirebaseBootstrapResult>(
      future: _firebaseFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _StartupApp();
        }

        final result = snapshot.data!;
        return ChangeNotifierProvider(
          create: (_) => GameController(
            FirebaseService(firebaseReady: result.ready),
          )..initialize(),
          child: const Ma3lomatApp(),
        );
      },
    );
  }
}

class _StartupApp extends StatelessWidget {
  const _StartupApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 18),
              Text(
                'جاري تشغيل معلومات عامة…',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Ma3lomatApp extends StatelessWidget {
  const Ma3lomatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'معلومات عامة',
      theme: buildAppTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const GameRouter(),
    );
  }
}

class GameRouter extends StatelessWidget {
  const GameRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: switch (game.phase) {
            GamePhase.input => const TeamInputScreen(key: ValueKey('input')),
            GamePhase.categories =>
              const CategorySelectionScreen(key: ValueKey('categories')),
            GamePhase.intro =>
              const CinematicIntroScreen(key: ValueKey('intro')),
            GamePhase.board =>
              const GameBoardScreen(key: ValueKey('board')),
            GamePhase.question => _questionMode(game),
            GamePhase.end => const EndGameScreen(key: ValueKey('end')),
          },
        );
      },
    );
  }

  Widget _questionMode(GameController game) {
    if (game.isAuction) {
      return const AuctionScreen(key: ValueKey('auction'));
    }
    if (game.isBedoonKalam || game.isYesNo) {
      return QrChallengeScreen(
        key: ValueKey('qr-${game.currentQuestion?.id}'),
        yesNo: game.isYesNo,
      );
    }
    return QuestionScreen(
      key: ValueKey('question-${game.currentQuestion?.id}'),
    );
  }
}
