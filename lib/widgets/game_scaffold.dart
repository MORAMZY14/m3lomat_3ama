import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.safeArea = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: child,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: safeArea ? SafeArea(child: body) : body,
    );
  }
}
