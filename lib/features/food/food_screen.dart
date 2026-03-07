import 'package:flutter/material.dart';
import '../../core/models/food_item.dart';
import '../../core/models/enums.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import 'food_data.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  // 0 = All, 1 = Best Choices, 2 = Limit, 3 = Avoid
  int _selectedFilter = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodItem> get _filteredFoods {
    List<FoodItem> base;
    switch (_selectedFilter) {
      case 1:
        base = FoodDatabase.goodFoods;
        break;
      case 2:
        base = FoodDatabase.limitFoods;
        break;
      case 3:
        base = FoodDatabase.avoidFoods;
        break;
      default:
        base = FoodDatabase.allFoods
          ..sort((a, b) => b.impactScore.compareTo(a.impactScore));
    }

    if (_searchQuery.isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.impactLabel.toLowerCase().contains(q) ||
            f.mechanismNote.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = StorageService.getUserProfile();
    final latestLab = StorageService.getLatestLabResult();

    // Decide personalised section title & foods
    final List<FoodItem> personalizedFoods;
    final String personalizedTitle;
    final String personalizedSubtitle;

    final focusMode = profile?.focusMode;
    final ldl = latestLab?.ldl;
    final tg = latestLab?.triglycerides;

    if (focusMode == FocusMode.triglycerides ||
        (tg != null && tg > 200 && (ldl == null || ldl <= 160))) {
      personalizedFoods = FoodDatabase.topTgFoods;
      personalizedTitle = 'Best for lowering triglycerides';
      personalizedSubtitle =
          tg != null ? 'Based on your TG of ${tg.toStringAsFixed(0)} mg/dL' : 'Based on your focus';
    } else if (focusMode == FocusMode.ldl ||
        (ldl != null && ldl > 130)) {
      personalizedFoods = FoodDatabase.topLdlFoods;
      personalizedTitle = 'Best for lowering LDL';
      personalizedSubtitle =
          ldl != null ? 'Based on your LDL of ${ldl.toStringAsFixed(0)} mg/dL' : 'Based on your focus';
    } else {
      personalizedFoods = FoodDatabase.topOverallFoods;
      personalizedTitle = 'Best for your heart health';
      personalizedSubtitle = 'High-impact choices for your lipid profile';
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Best Foods for You'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.dividerColor,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Personalised recommendation card ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _PersonalizedCard(
                title: personalizedTitle,
                subtitle: personalizedSubtitle,
                foods: personalizedFoods,
                onFoodTap: (food) => _showFoodDetail(context, food, latestLab?.ldl, latestLab?.triglycerides),
              ),
            ),
          ),

          // ── Search bar ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // ── Filter pills ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterPill(label: 'All', isSelected: _selectedFilter == 0, onTap: () => setState(() => _selectedFilter = 0)),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'Best Choices', color: AppTheme.positiveColor, isSelected: _selectedFilter == 1, onTap: () => setState(() => _selectedFilter = 1)),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'Limit', color: AppTheme.warningColor, isSelected: _selectedFilter == 2, onTap: () => setState(() => _selectedFilter = 2)),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'Avoid', color: AppTheme.dangerColor, isSelected: _selectedFilter == 3, onTap: () => setState(() => _selectedFilter = 3)),
                  ],
                ),
              ),
            ),
          ),

          // ── Section label ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                _searchQuery.isNotEmpty
                    ? '${_filteredFoods.length} result${_filteredFoods.length == 1 ? '' : 's'}'
                    : _filterLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),

          // ── Food list ─────────────────────────────────────────────────
          _filteredFoods.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 40, color: AppTheme.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No foods found for "$_searchQuery"',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FoodListItem(
                          food: _filteredFoods[index],
                          onTap: () => _showFoodDetail(
                            context,
                            _filteredFoods[index],
                            latestLab?.ldl,
                            latestLab?.triglycerides,
                          ),
                        ),
                      ),
                      childCount: _filteredFoods.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String get _filterLabel {
    switch (_selectedFilter) {
      case 1:
        return 'Best choices — sorted by impact';
      case 2:
        return 'Foods to limit';
      case 3:
        return 'Foods to avoid';
      default:
        return 'All foods — sorted by impact';
    }
  }

  void _showFoodDetail(
    BuildContext context,
    FoodItem food,
    double? currentLdl,
    double? currentTg,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodDetailSheet(
        food: food,
        currentLdl: currentLdl,
        currentTg: currentTg,
      ),
    );
  }
}

// ── Personalised card ──────────────────────────────────────────────────────────

class _PersonalizedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FoodItem> foods;
  final void Function(FoodItem) onFoodTap;

  const _PersonalizedCard({
    required this.title,
    required this.subtitle,
    required this.foods,
    required this.onFoodTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: foods
                .map((f) => _PersonalizedChip(food: f, onTap: () => onFoodTap(f)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PersonalizedChip extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;

  const _PersonalizedChip({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              food.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(width: 6),
            Text(
              '+${food.impactScore.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter pill ────────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.1)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : AppTheme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? effectiveColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

// ── Food list item ─────────────────────────────────────────────────────────────

class _FoodListItem extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;

  const _FoodListItem({required this.food, required this.onTap});

  Color get _categoryColor {
    switch (food.category) {
      case FoodCategory.good:
        return AppTheme.positiveColor;
      case FoodCategory.limit:
        return AppTheme.warningColor;
      case FoodCategory.avoid:
        return AppTheme.dangerColor;
    }
  }

  String get _impactString {
    final score = food.impactScore;
    if (score >= 0) return '+${score.toStringAsFixed(1)} pts';
    return '${score.toStringAsFixed(1)} pts';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Name + mechanism
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      food.impactLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Impact score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _impactString,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Food detail bottom sheet ───────────────────────────────────────────────────

class _FoodDetailSheet extends StatelessWidget {
  final FoodItem food;
  final double? currentLdl;
  final double? currentTg;

  const _FoodDetailSheet({
    required this.food,
    this.currentLdl,
    this.currentTg,
  });

  Color get _categoryColor {
    switch (food.category) {
      case FoodCategory.good:
        return AppTheme.positiveColor;
      case FoodCategory.limit:
        return AppTheme.warningColor;
      case FoodCategory.avoid:
        return AppTheme.dangerColor;
    }
  }

  String get _categoryLabel {
    switch (food.category) {
      case FoodCategory.good:
        return 'Best Choice';
      case FoodCategory.limit:
        return 'Limit';
      case FoodCategory.avoid:
        return 'Avoid';
    }
  }

  String get _impactString {
    final score = food.impactScore;
    if (score >= 0) return '+${score.toStringAsFixed(1)}';
    return score.toStringAsFixed(1);
  }

  String _buildContextNote() {
    if (food.category == FoodCategory.good) {
      if (food.helpsLdl && currentLdl != null) {
        return 'Your LDL is ${currentLdl!.toStringAsFixed(0)} mg/dL. Regular ${food.name.toLowerCase()} consumption may help bring it down over your next lab cycle.';
      }
      if (food.helpsTriglycerides && currentTg != null) {
        return 'Your triglycerides are ${currentTg!.toStringAsFixed(0)} mg/dL. ${food.name} is one of the strongest foods for reducing TG.';
      }
      return '${food.name} is one of the higher-impact choices for your overall lipid profile.';
    }

    if (food.category == FoodCategory.avoid) {
      return 'Eating ${food.name.toLowerCase()} regularly can trigger your high-satfat or high-carb day flags, directly reducing your behavior score.';
    }

    return 'Fine in moderate amounts — keep an eye on portions and frequency.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: name + category badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _categoryLabel,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: _categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Impact score block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _categoryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _impactString,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: _categoryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              'estimated score impact',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _categoryColor,
                                  ),
                            ),
                            Text(
                              'per lab cycle (~90 days)',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          food.category == FoodCategory.good
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: _categoryColor,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mechanism note
                  Row(
                    children: [
                      Icon(Icons.science_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          food.mechanismNote,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),

                  if (food.details.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.dividerColor, height: 1),
                    const SizedBox(height: 20),
                    Text(
                      food.category == FoodCategory.good ? 'Why it helps' : 'Why it matters',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    ...food.details.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              food.category == FoodCategory.good
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_outlined,
                              size: 16,
                              color: _categoryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                d,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Contextual note based on user's labs
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person_outline, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _buildContextNote(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Disclaimer
                  Text(
                    'Impact estimates are modeled averages. Individual results vary. Consult your doctor before making dietary changes.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                    textAlign: TextAlign.center,
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
