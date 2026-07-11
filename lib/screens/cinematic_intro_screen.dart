import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/game_controller.dart';
import '../widgets/game_scaffold.dart';

class CinematicIntroScreen extends StatefulWidget {
  const CinematicIntroScreen({super.key});

  @override
  State<CinematicIntroScreen> createState() => _CinematicIntroScreenState();
}

class _CinematicIntroScreenState extends State<CinematicIntroScreen> {
  Timer? _timer;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _show = true);
    });
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) context.read<GameController>().completeIntro();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    return GameScaffold(
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          scale: _show ? 1 : .75,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            opacity: _show ? 1 : 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 90, color: AppColors.amber),
                const SizedBox(height: 18),
                const Text(
                  'استعدوا للتحدي',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _team(game, 0),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('VS', style: TextStyle(color: AppColors.amber, fontSize: 30, fontWeight: FontWeight.w900)),
                    ),
                    _team(game, 1),
                  ],
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => context.read<GameController>().completeIntro(),
                  child: const Text('تخطي المقدمة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _team(GameController game, int index) {
    final team = game.teams[index];
    final palette = teamPalette(team.color, index);
    return Flexible(
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: palette.gradient, borderRadius: BorderRadius.circular(24)),
            child: Text(team.icon, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 10),
          Text(team.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
