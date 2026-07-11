import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_theme.dart';
import '../core/game_constants.dart';
import '../models/game_models.dart';
import '../state/game_controller.dart';
import '../widgets/game_scaffold.dart';

class QrChallengeScreen extends StatefulWidget {
  const QrChallengeScreen({required this.yesNo, super.key});

  final bool yesNo;

  @override
  State<QrChallengeScreen> createState() => _QrChallengeScreenState();
}

class _QrChallengeScreenState extends State<QrChallengeScreen> {
  Timer? _timer;
  int _seconds = GameConstants.timerDuration;
  bool _running = false;
  bool _hasStarted = false;
  bool _revealed = false;
  bool _secondChance = false;
  bool _loadingQr = true;
  String? _challengeUrl;

  @override
  void initState() {
    super.initState();
    _createChallenge();
  }

  Future<void> _createChallenge() async {
    final game = context.read<GameController>();
    final question = game.currentQuestion;
    if (question == null) return;
    final url = await game.createChallenge(
      content: question.question,
      metadata: {
        'type': widget.yesNo ? 'yes-no' : 'bedoon-kalam',
        'duration': _seconds,
        'categoryLabel': question.categoryName,
      },
    );
    if (mounted) {
      setState(() {
        _challengeUrl = url;
        _loadingQr = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _hasStarted = true;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() {
          _seconds = 0;
          _running = false;
          _revealed = true;
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _useHelp(GameController game, HelpType type) {
    if (game.useHelp(type) && type == HelpType.doubleTime) {
      setState(() => _seconds = GameConstants.timerDuration * 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final question = game.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return GameScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(widget.yesNo ? 'نعم / لا' : 'بدون كلام', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.categoryName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text('${game.selectedPoints} نقطة', style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_hasStarted && !_revealed) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Text(
                            widget.yesNo
                                ? 'خلّي لاعب يمسح الكود ويشوف الشخصية أو الشيء السري'
                                : 'خلّي لاعب يمسح الكود ويشوف التحدي بعيدًا عن باقي الفريق',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFD8B4FE), fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 16),
                          if (_loadingQr)
                            const SizedBox(width: 230, height: 230, child: Center(child: CircularProgressIndicator()))
                          else if (_challengeUrl != null)
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(12),
                              child: QrImageView(data: _challengeUrl!, size: 220),
                            )
                          else
                            Container(
                              width: 230,
                              height: 230,
                              padding: const EdgeInsets.all(14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Text(
                                'وضع تجريبي أو الخادم غير متصل. استخدم زر عرض التحدي المحلي.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => _showSecret(question.question),
                            icon: const Icon(Icons.phone_android_rounded),
                            label: const Text('عرض التحدي محليًا للاعب'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _helps(game),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text(widget.yesNo ? 'مسموح بالإجابة بنعم أو لا فقط' : 'ممنوع الكلام أو إصدار أصوات'),
                          const SizedBox(height: 5),
                          Text('الوقت: $_seconds ثانية', style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(widget.yesNo ? 'ابدأ أسئلة نعم / لا' : 'ابدأ التمثيل'),
                  ),
                ],
                if (_running) ...[
                  const SizedBox(height: 24),
                  _bigTimer(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _timer?.cancel();
                            setState(() => _running = false);
                          },
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('إيقاف'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            _timer?.cancel();
                            setState(() {
                              _running = false;
                              _revealed = true;
                            });
                          },
                          icon: const Icon(Icons.gavel_rounded),
                          label: const Text('التحكيم الآن'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_hasStarted && !_running && !_revealed) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('استكمال الوقت'),
                  ),
                ],
                if (_revealed) ...[
                  const SizedBox(height: 18),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(color: AppColors.green.withValues(alpha: .7), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('التحدي', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          Text(question.question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                          if (question.answer.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('الإجابة: ${question.answer}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _judge(game),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigTimer() {
    final urgent = _seconds <= 10;
    return Container(
      width: 180,
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (urgent ? AppColors.red : AppColors.purple).withValues(alpha: .12),
        border: Border.all(color: urgent ? AppColors.red : AppColors.purple, width: 8),
      ),
      child: Text('$_seconds', style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w900)),
    );
  }

  Widget _helps(GameController game) {
    final helps = game.teamHelps[game.currentTeamIndex];
    return Row(
      children: [
        Expanded(child: _help(game, helps, HelpType.doubleTime, '⏱️', 'وقت مضاعف')),
        const SizedBox(width: 8),
        Expanded(child: _help(game, helps, HelpType.hole, '🕳️', 'حُفرة')),
        const SizedBox(width: 8),
        Expanded(child: _help(game, helps, HelpType.twoAnswers, '✌️', 'إجابتان')),
      ],
    );
  }

  Widget _help(GameController game, TeamHelp helps, HelpType type, String icon, String label) {
    final used = helps.isUsed(type);
    return OutlinedButton(
      onPressed: used || game.activeHelp != null ? null : () => _useHelp(game, type),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3)),
      child: Column(children: [Text(icon, style: const TextStyle(fontSize: 24)), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))]),
    );
  }

  Widget _judge(GameController game) {
    return Column(
      children: [
        Text(_secondChance ? 'الفرصة الثانية والأخيرة' : 'أي فريق نجح؟', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(game.teams.length, (index) {
            final team = game.teams[index];
            final palette = teamPalette(team.color, index);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 5 : 0, right: index == 1 ? 5 : 0),
                child: FilledButton(
                  onPressed: () => context.read<GameController>().resolveQuestion(index, true),
                  style: FilledButton.styleFrom(backgroundColor: palette.endColor),
                  child: Text('${team.icon} ${team.name}', overflow: TextOverflow.ellipsis),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            if (game.activeHelp == HelpType.twoAnswers && !_secondChance) {
              setState(() => _secondChance = true);
            } else {
              context.read<GameController>().resolveQuestion(-1, false);
            }
          },
          child: Text(game.activeHelp == HelpType.twoAnswers && !_secondChance ? 'المحاولة الأولى فشلت — فرصة ثانية' : 'لم ينجح أحد'),
        ),
      ],
    );
  }

  void _showSecret(String secret) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('التحدي السري', textAlign: TextAlign.center),
        content: Text(secret, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('اخفِ التحدي'),
          ),
        ],
      ),
    );
  }
}
