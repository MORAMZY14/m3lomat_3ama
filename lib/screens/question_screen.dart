import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/game_constants.dart';
import '../models/game_models.dart';
import '../state/game_controller.dart';
import '../widgets/audio_player_card.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/network_image_card.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  Timer? _timer;
  int _seconds = GameConstants.timerDuration;
  bool _started = false;
  bool _revealed = false;
  bool _secondChance = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() {
          _seconds = 0;
          _revealed = true;
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _useHelp(GameController game, HelpType help) {
    if (game.useHelp(help) && help == HelpType.doubleTime) {
      setState(() => _seconds = GameConstants.timerDuration * 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final question = game.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return GameScaffold(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            sliver: SliverToBoxAdapter(child: _header(game, question)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(child: _timerCard()),
          ),
          if (!_started)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(child: _helps(game)),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(child: _questionCard(question)),
          ),
          if (_revealed)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(child: _answerCard(question)),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            sliver: SliverToBoxAdapter(child: _actions(game)),
          ),
        ],
      ),
    );
  }

  Widget _header(GameController game, GameQuestion question) {
    final team = game.teams[game.currentTeamIndex];
    final palette = teamPalette(team.color, game.currentTeamIndex);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(14)),
          child: Text(team.icon, style: const TextStyle(fontSize: 23)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.categoryName, style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900)),
              Text('دور ${team.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Text('${game.selectedPoints} نقطة', style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 19, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _timerCard() {
    final urgent = _seconds <= 10;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 142,
        height: 142,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (urgent ? AppColors.red : AppColors.purple).withValues(alpha: .12),
          border: Border.all(color: urgent ? AppColors.red : AppColors.purple, width: 7),
          boxShadow: [
            BoxShadow(
              color: (urgent ? AppColors.red : AppColors.purple).withValues(alpha: .22),
              blurRadius: 24,
            ),
          ],
        ),
        child: Text(
          '$_seconds',
          style: TextStyle(
            color: urgent ? const Color(0xFFFCA5A5) : Colors.white,
            fontSize: 45,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _helps(GameController game) {
    final help = game.teamHelps[game.currentTeamIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('وسائل المساعدة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _helpButton(game, help, HelpType.doubleTime, '⏱️', 'مضاعفة الوقت')),
            const SizedBox(width: 8),
            Expanded(child: _helpButton(game, help, HelpType.hole, '🕳️', 'حُفرة')),
            const SizedBox(width: 8),
            Expanded(child: _helpButton(game, help, HelpType.twoAnswers, '✌️', 'إجابتان')),
          ],
        ),
      ],
    );
  }

  Widget _helpButton(GameController game, TeamHelp helps, HelpType type, String icon, String label) {
    final used = helps.isUsed(type);
    final active = game.activeHelp == type;
    return OutlinedButton(
      onPressed: used || game.activeHelp != null ? null : () => _useHelp(game, type),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        side: BorderSide(color: active ? AppColors.amber : AppColors.border, width: active ? 2 : 1),
        backgroundColor: active ? AppColors.amber.withValues(alpha: .12) : AppColors.surfaceSoft.withValues(alpha: .55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 25)),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          if (used) const Text('مستخدمة', style: TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _questionCard(GameQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('السؤال', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              question.question,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 27, height: 1.45, fontWeight: FontWeight.w900),
            ),
            if (question.questionImageUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _showImage(question.questionImageUrl!),
                child: NetworkImageCard(url: question.questionImageUrl, height: 230),
              ),
            ],
            if (question.audioUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              AudioPlayerCard(url: question.audioUrl!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answerCard(GameQuestion question) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.green.withValues(alpha: .7), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('✓ الإجابة الصحيحة', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 12),
            if (question.imageUrl?.isNotEmpty == true) ...[
              GestureDetector(
                onTap: () => _showImage(question.imageUrl!),
                child: NetworkImageCard(url: question.imageUrl, height: 220),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              question.answer,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 30, fontWeight: FontWeight.w900),
            ),
            if (question.fact?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Text('💡 ${question.fact}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA7F3D0), height: 1.4)),
            ],
            if (question.acceptedAnswers.isNotEmpty || question.answerRule?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background.withValues(alpha: .45), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (question.acceptedAnswers.isNotEmpty)
                      Text('إجابات مقبولة أيضًا: ${question.acceptedAnswers.join(' · ')}', textAlign: TextAlign.center),
                    if (question.answerRule?.isNotEmpty == true)
                      Text('قاعدة الحكم: ${question.answerRule}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actions(GameController game) {
    if (!_started) {
      return FilledButton.icon(
        onPressed: _start,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('ابدأ السؤال'),
      );
    }

    if (!_revealed) {
      return FilledButton.icon(
        onPressed: () {
          _timer?.cancel();
          setState(() => _revealed = true);
        },
        icon: const Icon(Icons.visibility_rounded),
        label: const Text('اعرض الإجابة'),
      );
    }

    return Column(
      children: [
        Text(
          _secondChance ? 'الفرصة الثانية والأخيرة' : 'مين جاوب صح؟',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(game.teams.length, (index) {
            final team = game.teams[index];
            final palette = teamPalette(team.color, index);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 6 : 0, right: index == 1 ? 6 : 0),
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
        OutlinedButton.icon(
          onPressed: () {
            if (game.activeHelp == HelpType.twoAnswers && !_secondChance) {
              setState(() => _secondChance = true);
            } else {
              context.read<GameController>().resolveQuestion(-1, false);
            }
          },
          icon: const Icon(Icons.close_rounded),
          label: Text(game.activeHelp == HelpType.twoAnswers && !_secondChance ? 'الإجابة الأولى غلط — فرصة ثانية' : 'لا أحد'),
        ),
      ],
    );
  }

  void _showImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black.withValues(alpha: .93),
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: NetworkImageCard(url: url, height: MediaQuery.sizeOf(context).height * .75, fit: BoxFit.contain, borderRadius: 0))),
            Positioned(
              top: 18,
              right: 18,
              child: IconButton.filled(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ),
          ],
        ),
      ),
    );
  }
}
