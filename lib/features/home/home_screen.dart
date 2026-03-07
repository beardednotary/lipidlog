import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/daily_log.dart';
import '../../core/models/enums.dart';
import '../../core/models/lab_result.dart';
import '../../core/models/score_snapshot.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/score_service.dart';
import '../../core/services/storage_service.dart';
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

    final sortedLabs = List<LabResult>.from(labs)
      ..sort((a, b) => b.date.compareTo(a.date));
    final latestLab = sortedLabs.isNotEmpty ? sortedLabs.first : null;
    final previousLab = sortedLabs.length > 1 ? sortedLabs[1] : null;

    final ldlDelta = (latestLab?.ldl != null && previousLab?.ldl != null)
        ? latestLab!.ldl! - previousLab!.ldl!
        : null;
    final tgDelta =
        (latestLab?.triglycerides != null && previousLab?.triglycerides != null)
            ? latestLab!.triglycerides! - previousLab!.triglycerides!
            : null;

    ScoreSnapshot? score;
    if (profile != null) {
      score = ScoreService.computeScores(
        profile: profile,
        labs: labs,
        logs: logs,
      );
    }

    final today = DateTime.now();
    final todayLog = logs
        .where((l) =>
            l.date.year == today.year &&
            l.date.month == today.month &&
            l.date.day == today.day)
        .firstOrNull;

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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),
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
              ldlDelta: ldlDelta,
              tgDelta: tgDelta,
            ),
            if (latestLab != null) ...[
              const SizedBox(height: 14),
              _InsightCard(
                latestLab: latestLab,
                profile: profile,
                logs: logs,
              ),
            ],
            const SizedBox(height: 16),
            _TodayHabitsCard(
              todayLog: todayLog,
              onMedication: profile?.onMedication ?? false,
            ),
            if (latestLab != null) ...[
              const SizedBox(height: 16),
              _LabCycleCard(
                lastLab: latestLab,
                logs: logs,
                profile: profile,
              ),
            ],
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
  final double? ldlDelta;
  final double? tgDelta;

  const _ScoreCard({
    this.score,
    this.firstScore,
    this.profile,
    this.ldlDelta,
    this.tgDelta,
  });

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

            // Score ring
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
                        style: const TextStyle(
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
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
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

            _LabValuesRow(),

            const SizedBox(height: 20),

            if (score != null)
              OutlinedButton.icon(
                onPressed: () => _showShareSheet(context, scoreValue, firstScore),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Share Progress'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      BuildContext context, double currentScore, ScoreSnapshot? firstScore) {
    final latestLab = StorageService.getLatestLabResult();
    final scoreDelta = firstScore != null
        ? currentScore - firstScore.overallScore
        : null;
    final daysSinceFirst = firstScore != null
        ? DateTime.now().difference(firstScore.date).inDays
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareProgressSheet(
        currentScore: currentScore,
        scoreDelta: scoreDelta,
        daysSinceFirst: daysSinceFirst,
        ldl: latestLab?.ldl,
        hdl: latestLab?.hdl,
        tg: latestLab?.triglycerides,
        goalScore: score?.goalScore,
        ldlDelta: ldlDelta,
        tgDelta: tgDelta,
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
          _LabValueChip(
              label: 'LDL', value: latestLab.ldl!.toStringAsFixed(0)),
        if (latestLab.hdl != null)
          _LabValueChip(
              label: 'HDL', value: latestLab.hdl!.toStringAsFixed(0)),
        if (latestLab.triglycerides != null)
          _LabValueChip(
              label: 'TG',
              value: latestLab.triglycerides!.toStringAsFixed(0)),
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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ── Insight Card ───────────────────────────────────────────────────────────────

class _Opportunity {
  final String metric;
  final double currentValue;
  final double targetValue;
  final double estimatedGain;
  final String advice;
  final List<String> drivers;

  const _Opportunity({
    required this.metric,
    required this.currentValue,
    required this.targetValue,
    required this.estimatedGain,
    required this.advice,
    required this.drivers,
  });
}

class _InsightCard extends StatelessWidget {
  final LabResult latestLab;
  final UserProfile? profile;
  final List<DailyLog> logs;

  const _InsightCard({
    required this.latestLab,
    required this.profile,
    required this.logs,
  });

  _Opportunity? _findBiggestOpportunity() {
    final mode = profile?.focusMode ?? FocusMode.both;
    final currentLS = ScoreService.computeLabScore([latestLab], mode);

    double gain(LabResult hyp) =>
        (ScoreService.computeLabScore([hyp], mode) - currentLS)
            .clamp(0, 50)
            .toDouble();

    // Priority: TG first (most diet-responsive), then LDL, then HDL only if no other issue
    final tg = latestLab.triglycerides;
    if (tg != null) {
      final target = profile?.tgTarget ?? 150.0;
      if (tg > target) {
        return _Opportunity(
          metric: 'Triglycerides',
          currentValue: tg,
          targetValue: target,
          estimatedGain: gain(latestLab.copyWith(triglycerides: target)),
          advice: 'Cut sugary beverages, reduce refined carbs, and limit alcohol.',
          drivers: ['Sugary beverages', 'Refined carbohydrates & bread', 'Alcohol'],
        );
      }
    }

    final ldl = latestLab.ldl;
    if (ldl != null) {
      final target = profile?.ldlTarget ?? 100.0;
      if (ldl > target) {
        return _Opportunity(
          metric: 'LDL',
          currentValue: ldl,
          targetValue: target,
          estimatedGain: gain(latestLab.copyWith(ldl: target)),
          advice: 'Reduce saturated fat, add soluble fiber (oats, beans), and consider plant sterols.',
          drivers: ['Saturated fat (butter, red meat)', 'Low fiber intake', 'Refined carbohydrates'],
        );
      }
    }

    final hdl = latestLab.hdl;
    if (hdl != null) {
      final target = profile?.hdlTarget ?? 60.0;
      if (hdl < target) {
        return _Opportunity(
          metric: 'HDL',
          currentValue: hdl,
          targetValue: target,
          estimatedGain: gain(latestLab.copyWith(hdl: target)),
          advice: 'Regular aerobic exercise and healthy fats (olive oil, nuts, avocado) raise HDL.',
          drivers: ['Lack of aerobic exercise', 'Excess refined carbohydrates', 'Excess body weight'],
        );
      }
    }

    return null;
  }

  String? _getLogNote(_Opportunity opp) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = logs.where((l) => l.date.isAfter(weekAgo)).toList();
    if (recent.isEmpty) return null;

    if (opp.metric == 'Triglycerides') {
      final highCarb = recent.where((l) => l.highCarbDay).length;
      final alcohol =
          recent.where((l) => l.alcoholLevel != AlcoholLevel.none).length;
      if (highCarb >= 3) {
        return 'Your logs show $highCarb high-carb days this week — a likely contributor.';
      }
      if (alcohol >= 3) {
        return 'Alcohol logged $alcohol days this week — this raises TG.';
      }
    } else if (opp.metric == 'LDL') {
      final satFat = recent.where((l) => l.highSatFatDay).length;
      if (satFat >= 3) {
        return 'High saturated fat logged $satFat days this week — a key LDL driver.';
      }
    } else if (opp.metric == 'HDL') {
      final stepsHit = recent.where((l) => l.stepsGoalHit).length;
      if (stepsHit <= 2) {
        return 'Steps goal hit only $stepsHit days this week — exercise is the fastest way to raise HDL.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final opp = _findBiggestOpportunity();

    if (opp == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.positiveColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All lab values are at or near your targets. Keep it up!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.positiveColor,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final logNote = _getLogNote(opp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_outline,
                      color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biggest Opportunity',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(opp.metric,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.positiveColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${opp.estimatedGain.toStringAsFixed(0)} pts',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.positiveColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metric + advice block
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${opp.metric} ${opp.currentValue.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· target ${opp.targetValue.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(opp.advice,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Drivers
            Text(
              'COMMON DRIVERS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            ...opp.drivers.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textTertiary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(d,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )),

            // Log-based personalized note
            if (logNote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        logNote,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.warningColor,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
                  Text('Today',
                      style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DailyHabitScreen()),
                    ),
                    child: const Text('Log Habits'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Not logged yet',
                  style: Theme.of(context).textTheme.bodyMedium),
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
                Text('Today',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DailyHabitScreen()),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$done of $total habits complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: done == total
                        ? AppTheme.positiveColor
                        : AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.dividerColor,
                color: done == total
                    ? AppTheme.positiveColor
                    : AppTheme.primaryColor,
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
                      h.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: h.done
                          ? AppTheme.positiveColor
                          : AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Icon(h.icon, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      h.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: h.done
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.positiveColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: AppTheme.positiveColor),
                      const SizedBox(width: 6),
                      Text(
                        "Today's habits complete · Score impact recorded",
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
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

// ── Lab Cycle Card ─────────────────────────────────────────────────────────────

class _LabCycleCard extends StatelessWidget {
  final LabResult lastLab;
  final List<DailyLog> logs;
  final UserProfile? profile;

  const _LabCycleCard({
    required this.lastLab,
    required this.logs,
    required this.profile,
  });

  int _bestStreak(List<DailyLog> logs) {
    if (logs.isEmpty) return 0;
    final days = logs
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .toList()
      ..sort();
    int best = 1, current = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final cycleStart =
        DateTime(lastLab.date.year, lastLab.date.month, lastLab.date.day);
    final daysSinceLab =
        DateTime.now().difference(cycleStart).inDays.clamp(0, 9999);
    final cycleDuration =
        (profile != null && profile!.labReminderEnabled && profile!.labReminderMonths > 0)
            ? profile!.labReminderMonths * 30
            : 90;
    final progress = (daysSinceLab / cycleDuration).clamp(0.0, 1.0);
    final daysRemaining = (cycleDuration - daysSinceLab).clamp(0, cycleDuration);
    final isOverdue = daysSinceLab >= cycleDuration;

    final logsSinceLab = logs
        .where((l) =>
            !DateTime(l.date.year, l.date.month, l.date.day)
                .isBefore(cycleStart))
        .toList();
    final bestStreak = _bestStreak(logsSinceLab);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lab Cycle',
                    style: Theme.of(context).textTheme.titleLarge),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppTheme.warningColor.withValues(alpha: 0.10)
                        : AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOverdue
                        ? 'Check due'
                        : 'Day $daysSinceLab of $cycleDuration',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isOverdue
                              ? AppTheme.warningColor
                              : AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.dividerColor,
                color: isOverdue
                    ? AppTheme.warningColor
                    : AppTheme.primaryColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _CycleStatChip(
                  label: 'Days logged',
                  value: logsSinceLab.length.toString(),
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(width: 10),
                _CycleStatChip(
                  label: 'Best streak',
                  value: '$bestStreak days',
                  icon: Icons.local_fire_department_outlined,
                ),
                const SizedBox(width: 10),
                _CycleStatChip(
                  label: isOverdue ? 'Days over' : 'Days left',
                  value: isOverdue
                      ? '${daysSinceLab - cycleDuration}'
                      : '$daysRemaining',
                  icon: isOverdue
                      ? Icons.warning_amber_outlined
                      : Icons.hourglass_empty_outlined,
                  accent: isOverdue ? AppTheme.warningColor : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  const _CycleStatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: accent ?? AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accent,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ── Share Progress Sheet ───────────────────────────────────────────────────────

class _ShareProgressSheet extends StatefulWidget {
  final double currentScore;
  final double? scoreDelta;
  final int? daysSinceFirst;
  final double? ldl;
  final double? hdl;
  final double? tg;
  final double? goalScore;
  final double? ldlDelta;
  final double? tgDelta;

  const _ShareProgressSheet({
    required this.currentScore,
    this.scoreDelta,
    this.daysSinceFirst,
    this.ldl,
    this.hdl,
    this.tg,
    this.goalScore,
    this.ldlDelta,
    this.tgDelta,
  });

  @override
  State<_ShareProgressSheet> createState() => _ShareProgressSheetState();
}

class _ShareProgressSheetState extends State<_ShareProgressSheet> {
  final _cardKey = GlobalKey();
  bool _isSharing = false;

  String get _viralHeadline {
    final sd = widget.scoreDelta;
    final days = widget.daysSinceFirst;
    final ld = widget.ldlDelta;
    final td = widget.tgDelta;

    if (sd != null && sd >= 3) {
      if (days != null && days >= 7 && days <= 120) {
        return '+${sd.toStringAsFixed(0)} pts in $days days';
      }
      return '+${sd.toStringAsFixed(0)} point improvement';
    }
    if (ld != null && ld <= -5) {
      return 'LDL ↓ ${ld.abs().toStringAsFixed(0)} mg/dL';
    }
    if (td != null && td <= -10) {
      return 'Triglycerides ↓ ${td.abs().toStringAsFixed(0)} mg/dL';
    }
    return 'Improving my cholesterol health';
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/lipidlog_progress.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$_viralHeadline — tracked with LipidLog',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Share Progress',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // Shareable card
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
                  const Text(
                    'LIPIDLOG',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Improve your cholesterol score.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Viral headline — the hook
                  Text(
                    _viralHeadline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Score ring
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
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
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Score + goal inline
                  Text(
                    'score${widget.goalScore != null ? '  ·  Goal: ${widget.goalScore!.toStringAsFixed(0)}' : ''}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  // Inline lab values with bullet separators
                  if (widget.ldl != null || widget.hdl != null || widget.tg != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      [
                        if (widget.ldl != null) 'LDL ${widget.ldl!.toStringAsFixed(0)}',
                        if (widget.hdl != null) 'HDL ${widget.hdl!.toStringAsFixed(0)}',
                        if (widget.tg != null) 'TG ${widget.tg!.toStringAsFixed(0)}',
                      ].join('  ·  '),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text(
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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

