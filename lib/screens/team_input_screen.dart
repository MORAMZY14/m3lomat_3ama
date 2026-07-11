import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/game_constants.dart';
import '../models/game_models.dart';
import '../state/game_controller.dart';
import '../widgets/game_scaffold.dart';

class TeamInputScreen extends StatefulWidget {
  const TeamInputScreen({super.key});

  @override
  State<TeamInputScreen> createState() => _TeamInputScreenState();
}

class _TeamInputScreenState extends State<TeamInputScreen> {
  final _controllers = [TextEditingController(), TextEditingController()];
  final _colors = ['blue', 'red'];
  final _icons = ['👑', '🔥'];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _ready => _controllers.every((controller) => controller.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Color(0xFFFCD34D), Color(0xFFF97316)],
                  ).createShader(rect),
                  child: const Text(
                    'تحدي الشباب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('خليط مليط', style: TextStyle(color: AppColors.muted, fontSize: 18)),
                const SizedBox(height: 16),
                Consumer<GameController>(
                  builder: (context, game, _) {
                    if (game.loading) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (game.loadMessage == null) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: .55),
                        ),
                      ),
                      child: Text(
                        game.loadMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFCD34D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final cards = List.generate(2, (index) => _teamCard(index));
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 18),
                              Expanded(child: cards[1]),
                            ],
                          )
                        : Column(children: [cards[0], const SizedBox(height: 16), cards[1]]);
                  },
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _ready
                      ? () {
                          context.read<GameController>().submitTeams([
                                TeamConfig(
                                  name: _controllers[0].text,
                                  color: _colors[0],
                                  icon: _icons[0],
                                ),
                                TeamConfig(
                                  name: _controllers[1].text,
                                  color: _colors[1],
                                  icon: _icons[1],
                                ),
                              ]);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: const Color(0xFF1C1305),
                    minimumSize: const Size.fromHeight(64),
                  ),
                  child: Text(_ready ? 'يلا نبدأ التحدي' : 'اكتبوا أسماء الفرق الأول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamCard(int index) {
    final palette = teamPalette(_colors[index], index);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: palette.color.withValues(alpha: .45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: palette.gradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(_icons[index], style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        index == 0 ? 'الفريق الأول' : 'الفريق الثاني',
                        style: TextStyle(color: palette.color, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _controllers[index],
                        maxLength: 24,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        decoration: const InputDecoration(
                          hintText: 'اسم الفريق…',
                          counterText: '',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('لون الفريق', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: teamPalettes.map((item) {
                final selected = _colors[index] == item.key;
                final taken = _colors[index == 0 ? 1 : 0] == item.key;
                return InkWell(
                  onTap: taken
                      ? null
                      : () => setState(() {
                            _colors[index] = item.key;
                          }),
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: item.gradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Text(taken ? '×' : selected ? '✓' : '', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('شعار الفريق', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GameConstants.teamIcons.map((icon) {
                final selected = _icons[index] == icon;
                return InkWell(
                  onTap: () => setState(() => _icons[index] = icon),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? palette.color.withValues(alpha: .2) : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? palette.color : AppColors.border),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
