import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/game_constants.dart';
import '../models/game_models.dart';
import '../state/game_controller.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/network_image_card.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final List<Category> _selected = [];

  void _toggle(Category category) {
    setState(() {
      final existing = _selected.indexWhere((item) => item.id == category.id);
      if (existing >= 0) {
        _selected.removeAt(existing);
      } else if (_selected.length < GameConstants.maxCategories) {
        _selected.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    return GameScaffold(
      padding: EdgeInsets.zero,
      child: game.loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const Text(
                          'اختر الفئات',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اختر ${GameConstants.maxCategories} فئات',
                          style: const TextStyle(color: AppColors.muted, fontSize: 17),
                        ),
                        if (game.loadMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.amber.withValues(alpha: .55)),
                            ),
                            child: Text(
                              game.loadMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Text(
                                  'الفئات المختارة: ${_selected.length} / ${GameConstants.maxCategories}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: _selected.length / GameConstants.maxCategories,
                                  minHeight: 9,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...game.groups.expand((group) => [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Divider(color: AppColors.border)),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.crossAxisExtent;
                            final count = width >= 1100 ? 4 : width >= 700 ? 3 : 2;
                            return SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: count,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.08,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final category = group.categories[index];
                                  return _categoryCard(category);
                                },
                                childCount: group.categories.length,
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 30),
                  sliver: SliverToBoxAdapter(
                    child: FilledButton.icon(
                      onPressed: _selected.length == GameConstants.maxCategories
                          ? () => context.read<GameController>().submitCategories(_selected)
                          : null,
                      icon: const Icon(Icons.tablet_rounded),
                      label: Text(
                        _selected.length == GameConstants.maxCategories
                            ? 'يلا بينا'
                            : 'اختاروا ${GameConstants.maxCategories - _selected.length} كمان',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _categoryCard(Category category) {
    final selected = _selected.any((item) => item.id == category.id);
    final disabled = !selected && _selected.length >= GameConstants.maxCategories;
    return Opacity(
      opacity: disabled ? .4 : 1,
      child: InkWell(
        onTap: disabled ? null : () => _toggle(category),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.cyan : AppColors.border,
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.cyan.withValues(alpha: .22), blurRadius: 18)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageCard(url: category.image, height: double.infinity, borderRadius: 0),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE6000000)],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.cyan,
                      foregroundColor: AppColors.background,
                      child: Icon(Icons.check_rounded, size: 21),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
