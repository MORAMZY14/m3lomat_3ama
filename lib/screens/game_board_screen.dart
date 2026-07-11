import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/game_constants.dart';
import '../models/game_models.dart';
import '../state/game_controller.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/network_image_card.dart';

class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    return GameScaffold(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 14),
            sliver: SliverToBoxAdapter(child: _ScoreBoard(game: game)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 1180
                    ? 3
                    : constraints.crossAxisExtent >= 760
                        ? 2
                        : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: columns == 1 ? 1.16 : .95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CategoryBoardCard(
                      category: game.selectedCategories[index],
                      game: game,
                    ),
                    childCount: game.selectedCategories.length,
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 30),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (game.allSelectedQuestionsAnswered)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'انتهت جميع الأسئلة!',
                        style: TextStyle(color: Color(0xFFFCD34D), fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: () => context.read<GameController>().finishGame(),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                    icon: const Icon(Icons.emoji_events_rounded),
                    label: const Text('إنهاء المسابقة والنتائج النهائية'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({required this.game});

  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'الدور على ${game.teams[game.currentTeamIndex].name}',
                    style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _TeamScore(game: game, index: 0)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: AppColors.border, fontSize: 38)),
                    ),
                    Expanded(child: _TeamScore(game: game, index: 1)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({required this.game, required this.index});

  final GameController game;
  final int index;

  @override
  Widget build(BuildContext context) {
    final team = game.teams[index];
    final palette = teamPalette(team.color, index);
    final active = game.currentTeamIndex == index;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: palette.gradient,
                shape: BoxShape.circle,
                border: Border.all(color: active ? AppColors.amber : Colors.white24, width: active ? 3 : 1),
              ),
              child: Text(team.icon),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? const Color(0xFFFCD34D) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${team.score}',
          style: TextStyle(color: palette.color, fontSize: 42, fontWeight: FontWeight.w900),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _scoreButton(context, Icons.remove_rounded, -100, palette),
            const SizedBox(width: 12),
            _scoreButton(context, Icons.add_rounded, 100, palette),
          ],
        ),
      ],
    );
  }

  Widget _scoreButton(BuildContext context, IconData icon, int delta, TeamPalette palette) {
    return IconButton.outlined(
      visualDensity: VisualDensity.compact,
      onPressed: () => context.read<GameController>().adjustScore(index, delta),
      style: IconButton.styleFrom(foregroundColor: palette.color, side: BorderSide(color: palette.color)),
      icon: Icon(icon, size: 18),
    );
  }
}

class _CategoryBoardCard extends StatelessWidget {
  const _CategoryBoardCard({required this.category, required this.game});

  final Category category;
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageCard(url: category.image, height: double.infinity),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xE8000000)],
                        ),
                      ),
                      child: Text(
                        category.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _TeamQuestionColumn(category: category, game: game, teamIndex: 0)),
                const SizedBox(width: 10),
                Expanded(child: _TeamQuestionColumn(category: category, game: game, teamIndex: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamQuestionColumn extends StatelessWidget {
  const _TeamQuestionColumn({required this.category, required this.game, required this.teamIndex});

  final Category category;
  final GameController game;
  final int teamIndex;

  @override
  Widget build(BuildContext context) {
    final team = game.teams[teamIndex];
    final palette = teamPalette(team.color, teamIndex);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(team.icon),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.color, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...GameConstants.pointValues.map((points) {
          final available = game.hasQuestion(category.id, points, teamIndex);
          final answered = game.isAnswered(category.id, points, teamIndex);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: answered || !available
                    ? null
                    : () => context.read<GameController>().selectQuestion(category.id, points, teamIndex),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  backgroundColor: palette.endColor,
                  disabledBackgroundColor: AppColors.surfaceSoft,
                  disabledForegroundColor: AppColors.muted.withValues(alpha: .5),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(!available ? '—' : answered ? '✓' : '$points', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
          );
        }),
      ],
    );
  }
}
