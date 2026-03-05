import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/daily_log.dart';
import '../../core/models/enums.dart';
import '../../core/models/score_snapshot.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/score_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/weekly_insights_service.dart';
import '../../core/theme/app_theme.dart';
import '../food/food_screen.dart';
import '../habits/daily_habit_screen.dart';
import '../labs/labs_screen.dart';
import '../patterns/patterns_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    LabsScreen(),
    PatternsScreen(),
    FoodScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Labs',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ───────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = StorageService.getUserProfile();
    final labs = StorageService.getAllLabResults();
    final logs = StorageService.getAllDailyLogs();
    final scores = StorageService.getAllScoreSnapshots();

    ScoreSnapshot? score;
    if (profile != null) {
      score = ScoreService.computeScores(
        profile: profile,
        labs: labs,
        logs: logs,
      );
    }

    // Find today's log
    final today = DateTime.now();
    final todayLog = logs.where((l) =>
      l.date.year == today.year &&
      l.date.month == today.month &&
      l.date.day == today.day,
    ).firstOrNull;

    // First score ever (for delta on share card)
    final sortedScores = List<ScoreSnapshot>.from(scores)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstScore = sortedScores.isNotEmpty ? sortedScores.first : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('LipidLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: const Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScoreCard(
              score: score,
              firstScore: firstScore,
              profile: profile,
            ),
            const SizedBox(height: 20),
            _TodayHabitsCard(
              todayLog: todayLog,
              onMedication: profile?.onMedication ?? false,
            ),
            const SizedBox(height: 20),
            _ThisWeekCard(
              logs: logs,
              scores: scores,
              onMedication: profile?.onMedication ?? false,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score Card ─────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final ScoreSnapshot? score;
  final ScoreSnapshot? firstScore;
  final UserProfile? profile;

  const _ScoreCard({this.score, this.firstScore, this.profile});

  @override
  Widget build(BuildContext context) {
    final scoreValue = score?.overallScore ?? 0;
    final goalScore = score?.goalScore;
    final delta = score?.deltaToGoal;
    final scoreColor = AppTheme.getScoreColor(scoreValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Your Cholesterol Score',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 24),

            // Score ring — hero size
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: scoreValue / 100,
                      strokeWidth: 14,
                      backgroundColor: AppTheme.dividerColor,
                      color: scoreColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scoreValue.toStringAsFixed(0),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (goalScore != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Goal: ${goalScore.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Progress framing FIRST, then grade
            if (score != null) ...[
              if (delta != null && delta > 0)
                Text(
                  '${delta.toStringAsFixed(0)} points from goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              const SizedBox(height: 4),
              Text(
                score!.scoreGrade,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scoreColor,
                    ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(color: AppTheme.dividerColor, height: 1),
            const SizedBox(height: 20),

            // Latest lab values
            _LabValuesRow(),

            const SizedBox(height: 20),

            // Share progress button
            if (score != null)
              OutlinedButton.icon(
                onPressed: () => _showShareSheet(context, scoreValue, firstScore),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Share Progress'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(
    BuildContext context,
    double currentScore,
    ScoreSnapshot? firstScore,
  ) {
    final latestLab = StorageService.getLatestLabResult();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareProgressSheet(
        currentScore: currentScore,
        firstScore: firstScore?.overallScore,
        firstScoreDate: firstScore?.date,
        ldl: latestLab?.ldl,
        hdl: latestLab?.hdl,
        tg: latestLab?.triglycerides,
        goalScore: score?.goalScore,
      ),
    );
  }
}

class _LabValuesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final latestLab = StorageService.getLatestLabResult();

    if (latestLab == null) {
      return Text(
        'Add your first lab result to see your score',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (latestLab.ldl != null)
          _LabValueChip(label: 'LDL', value: latestLab.ldl!.toStringAsFixed(0)),
        if (latestLab.hdl != null)
          _LabValueChip(label: 'HDL', value: latestLab.hdl!.toStringAsFixed(0)),
        if (latestLab.triglycerides != null)
          _LabValueChip(label: 'TG', value: latestLab.triglycerides!.toStringAsFixed(0)),
      ],
    );
  }
}

class _LabValueChip extends StatelessWidget {
  final String label;
  final String value;

  const _LabValueChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

// ── Today's Habits Card ────────────────────────────────────────────────────────

class _TodayHabitsCard extends StatelessWidget {
  final DailyLog? todayLog;
  final bool onMedication;

  const _TodayHabitsCard({this.todayLog, required this.onMedication});

  List<({String label, IconData icon, bool done})> _habitRows(DailyLog log) {
    return [
      (
        label: 'Steps goal hit',
        icon: Icons.directions_walk_outlined,
        done: log.stepsGoalHit,
      ),
      (
        label: 'Alcohol-free',
        icon: Icons.no_drinks_outlined,
        done: log.alcoholLevel == AlcoholLevel.none,
      ),
      (
        label: 'Good sleep (6–8h)',
        icon: Icons.bedtime_outlined,
        done: log.sleepCategory == SleepCategory.normal6to8h,
      ),
      (
        label: 'No late-night eating',
        icon: Icons.no_food_outlined,
        done: !log.lateNightEating,
      ),
      (
        label: 'Low saturated fat',
        icon: Icons.favorite_outline,
        done: !log.highSatFatDay,
      ),
      if (onMedication)
        (
          label: 'Medication taken',
          icon: Icons.medication_outlined,
          done: log.medicationTaken,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (todayLog == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyHabitScreen()),
                    ),
                    child: const Text('Log Habits'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Not logged yet',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0,
                  backgroundColor: AppTheme.dividerColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final habits = _habitRows(todayLog!);
    final done = habits.where((h) => h.done).length;
    final total = habits.length;
    final progress = total > 0 ? done / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyHabitScreen()),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$done of $total habits complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: done == total ? AppTheme.positiveColor : AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.dividerColor,
                color: done == total ? AppTheme.positiveColor : AppTheme.primaryColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            ...habits.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      h.done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: h.done ? AppTheme.positiveColor : AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Icon(h.icon, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      h.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: h.done ? AppTheme.textPrimary : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (done == total)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.positiveColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppTheme.positiveColor),
                      const SizedBox(width: 6),
                      Text(
                        "Today's habits complete · Score impact recorded",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.positiveColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── This Week Card ─────────────────────────────────────────────────────────────

class _ThisWeekCard extends StatelessWidget {
  final List<DailyLog> logs;
  final List<ScoreSnapshot> scores;
  final bool onMedication;

  const _ThisWeekCard({
    required this.logs,
    required this.scores,
    required this.onMedication,
  });

  @override
  Widget build(BuildContext context) {
    final summary = WeeklyInsightsService.buildCurrentWeekSummary(
      logs,
      scores,
      onMedication: onMedication,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (summary == null)
              Text(
                'Log your daily habits to see weekly insights',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              _WeekStatRow(
                icon: Icons.calendar_today_outlined,
                label: 'Days logged',
                value: summary.daysLogged.toString(),
              ),
              const SizedBox(height: 10),
              _WeekStatRow(
                icon: Icons.emoji_events_outlined,
                label: 'Best habit',
                value:
                    '${summary.bestHabit.label} (${(summary.bestHabit.score * 100).toStringAsFixed(0)}%)',
                valueColor: AppTheme.positiveColor,
              ),
              const SizedBox(height: 10),
              _WeekStatRow(
                icon: Icons.flag_outlined,
                label: 'Needs work',
                value:
                    '${summary.worstHabit.label} (${(summary.worstHabit.score * 100).toStringAsFixed(0)}%)',
                valueColor: AppTheme.warningColor,
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.dividerColor, height: 1),
              const SizedBox(height: 12),
              Text(
                summary.trajectory,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _WeekStatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: valueColor ?? AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }
}

// ── Share Progress Sheet ───────────────────────────────────────────────────────

class _ShareProgressSheet extends StatefulWidget {
  final double currentScore;
  final double? firstScore;
  final DateTime? firstScoreDate;
  final double? ldl;
  final double? hdl;
  final double? tg;
  final double? goalScore;

  const _ShareProgressSheet({
    required this.currentScore,
    this.firstScore,
    this.firstScoreDate,
    this.ldl,
    this.hdl,
    this.tg,
    this.goalScore,
  });

  @override
  State<_ShareProgressSheet> createState() => _ShareProgressSheetState();
}

class _ShareProgressSheetState extends State<_ShareProgressSheet> {
  final _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/lipidlog_progress.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Tracking my cholesterol with LipidLog',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreDelta = widget.firstScore != null
        ? widget.currentScore - widget.firstScore!
        : null;
    final hasDelta = scoreDelta != null && scoreDelta.abs() >= 0.5;
    final scoreColor = AppTheme.getScoreColor(widget.currentScore);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Share Progress', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // The shareable card
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App name
                  Text(
                    'LipidLog',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Cholesterol Score Progress',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Score ring
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: widget.currentScore / 100,
                            strokeWidth: 8,
                            backgroundColor: AppTheme.dividerColor,
                            color: scoreColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          widget.currentScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (hasDelta) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          scoreDelta! > 0 ? Icons.trending_up : Icons.trending_down,
                          color: scoreDelta > 0 ? AppTheme.positiveColor : AppTheme.dangerColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${scoreDelta > 0 ? '+' : ''}${scoreDelta.toStringAsFixed(0)} points',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scoreDelta > 0 ? AppTheme.positiveColor : AppTheme.dangerColor,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Lab values
                  if (widget.ldl != null || widget.hdl != null || widget.tg != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (widget.ldl != null)
                            _ShareStat('LDL', widget.ldl!.toStringAsFixed(0)),
                          if (widget.hdl != null)
                            _ShareStat('HDL', widget.hdl!.toStringAsFixed(0)),
                          if (widget.tg != null)
                            _ShareStat('TG', widget.tg!.toStringAsFixed(0)),
                        ],
                      ),
                    ),
                  ],

                  if (widget.goalScore != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Goal: ${widget.goalScore!.toStringAsFixed(0)} pts',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Text(
                    'Tracked with LipidLog',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _share,
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share_outlined, size: 18),
              label: Text(_isSharing ? 'Preparing...' : 'Share Image'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  final String label;
  final String value;

  const _ShareStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
