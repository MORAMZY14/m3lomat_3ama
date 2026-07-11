import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../state/game_controller.dart';
import '../widgets/game_scaffold.dart';

class EndGameScreen extends StatelessWidget {
  const EndGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final rankings = [...game.teams]..sort((a, b) => b.score.compareTo(a.score));
    final tie = rankings.length > 1 && rankings[0].score == rankings[1].score;
    final winner = rankings.first;
    final winnerIndex = game.teams.indexOf(winner);
    final palette = teamPalette(winner.color, winnerIndex);

    return GameScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Icon(tie ? Icons.handshake_rounded : Icons.emoji_events_rounded, size: 92, color: tie ? AppColors.cyan : AppColors.amber),
                const SizedBox(height: 12),
                Text(
                  tie ? 'تعادل قوي!' : 'لدينا فائز!',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 22),
                if (!tie)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: palette.color, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('الفريق الفائز', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          Container(
                            width: 78,
                            height: 78,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(24)),
                            child: Text(winner.icon, style: const TextStyle(fontSize: 38)),
                          ),
                          const SizedBox(height: 10),
                          Text(winner.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                          Text('${winner.score} نقطة', style: TextStyle(color: palette.color, fontSize: 29, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                ...rankings.asMap().entries.map((entry) => _rankingRow(game.teams, entry.value, entry.key)),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => context.read<GameController>().restart(),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('العب مرة أخرى'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rankingRow(List<Team> original, Team team, int rank) {
    final index = original.indexOf(team);
    final palette = teamPalette(team.color, index);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: palette.endColor,
          child: Text(team.icon),
        ),
        title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(rank == 0 ? 'المركز الأول' : 'المركز الثاني'),
        trailing: Text('${team.score}', style: TextStyle(color: palette.color, fontSize: 24, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
