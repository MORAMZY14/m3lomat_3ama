import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_theme.dart';
import '../core/game_constants.dart';
import '../state/game_controller.dart';
import '../widgets/game_scaffold.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  final _bidController = TextEditingController(text: '5');
  Timer? _timer;
  int _seconds = GameConstants.auctionTimerDuration;
  int? _bidTeam;
  bool _running = false;
  bool _judging = false;
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
      type: question.questionImageUrl == null ? 'text' : 'image',
      imageUrl: question.questionImageUrl,
      metadata: {'type': 'auction', 'duration': GameConstants.auctionTimerDuration},
    );
    if (mounted) setState(() {
      _challengeUrl = url;
      _loadingQr = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bidController.dispose();
    super.dispose();
  }

  void _start() {
    if (_bidTeam == null) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() {
          _seconds = 0;
          _running = false;
          _judging = true;
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final question = game.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return GameScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('المزاد', style: TextStyle(color: AppColors.amber, fontSize: 38, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(question.categoryName, style: const TextStyle(color: AppColors.muted, fontSize: 18)),
                const SizedBox(height: 18),
                if (!_running && !_judging) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Text('امسح الكود لمشاهدة تحدي المزاد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                          const SizedBox(height: 14),
                          if (_loadingQr)
                            const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
                          else if (_challengeUrl != null)
                            Container(color: Colors.white, padding: const EdgeInsets.all(10), child: QrImageView(data: _challengeUrl!, size: 210))
                          else
                            const SizedBox(
                              height: 180,
                              child: Center(child: Text('تعذّر إنشاء QR. يمكنك متابعة المزاد محليًا.', textAlign: TextAlign.center)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('الفريق صاحب أعلى مزايدة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(game.teams.length, (index) {
                      final team = game.teams[index];
                      final palette = teamPalette(team.color, index);
                      final selected = _bidTeam == index;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: index == 0 ? 5 : 0, right: index == 1 ? 5 : 0),
                          child: OutlinedButton(
                            onPressed: () => setState(() => _bidTeam = index),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 58),
                              side: BorderSide(color: selected ? palette.color : AppColors.border, width: selected ? 3 : 1),
                              backgroundColor: selected ? palette.color.withValues(alpha: .14) : null,
                            ),
                            child: Text('${team.icon} ${team.name}', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: 'عدد العناصر في المزايدة', prefixIcon: Icon(Icons.numbers_rounded)),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _bidTeam == null ? null : _start,
                    icon: const Icon(Icons.timer_rounded),
                    label: const Text('ابدأ 45 ثانية'),
                  ),
                ],
                if (_running) ...[
                  Container(
                    width: 190,
                    height: 190,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _seconds <= 10 ? AppColors.red : AppColors.amber, width: 8),
                    ),
                    child: Text('$_seconds', style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${game.teams[_bidTeam!].name} يحاول ذكر ${_bidController.text} عناصر',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        _running = false;
                        _judging = true;
                      });
                    },
                    icon: const Icon(Icons.gavel_rounded),
                    label: const Text('انتقل للتحكيم'),
                  ),
                ],
                if (_judging) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('التحدي', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          Text(question.question, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                          if (question.answer.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('الإجابة/المرجع: ${question.answer}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF86EFAC))),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.read<GameController>().resolveQuestion(_bidTeam!, true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                    icon: const Icon(Icons.check_rounded),
                    label: Text('نجح فريق ${game.teams[_bidTeam!].name}'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.read<GameController>().resolveQuestion(-1, false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('فشل في المزايدة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
