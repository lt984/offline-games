import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_catalog.dart';
import '../state/profile_controller.dart';
import '../theme/arcade_skin.dart';
import '../widgets/arcade_background.dart';
import '../widgets/game_card.dart';
import '../widgets/top_bar.dart';

/// The central hub: header, category tabs and a swipeable carousel with one
/// page per category.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final _pages = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcadeBackground(
        child: SafeArea(
          child: Column(
            children: [
              const HubTopBar(),
              _CategoryTabs(selected: _page, onSelect: _goTo),
              Expanded(
                child: PageView(
                  key: const ValueKey('category-carousel'),
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final c in GameCategory.values)
                      _CategoryPage(category: c),
                  ],
                ),
              ),
              _PageDots(count: GameCategory.values.length, index: _page),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four equal-width category tabs, always fully visible.
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          for (final (i, c) in GameCategory.values.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CategoryTab(
                key: ValueKey('tab-${c.name}'),
                category: c,
                active: i == selected,
                onTap: () {
                  if (i != selected &&
                      context.read<ProfileController>().hapticsOn) {
                    skin.tapHaptic();
                  }
                  onSelect(i);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.category,
    required this.active,
    required this.onTap,
  });

  final GameCategory category;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return Semantics(
      button: true,
      selected: active,
      label: category.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? skin.primary : skin.surface,
            borderRadius: skin.radius,
            border: Border.all(color: skin.primary.withValues(alpha: 0.4)),
            boxShadow: active ? skin.glowShadow : const [],
          ),
          child: Column(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                category.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? skin.surface : skin.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPage extends StatelessWidget {
  const _CategoryPage({required this.category});

  final GameCategory category;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final games = gamesIn(category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: SkinPanel(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${category.icon}  ${category.label}',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              '${games.length} mini-games',
              style: TextStyle(color: skin.mutedText, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [for (final g in games) GameCard(game: g)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? skin.primary
                  : skin.mutedText.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(
                skin.cornerRadius == 0 ? 0 : 4,
              ),
            ),
          ),
      ],
    );
  }
}
