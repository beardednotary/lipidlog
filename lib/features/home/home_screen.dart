import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/score_service.dart';
import '../../core/services/weekly_insights_service.dart';
import '../../core/models/score_snapshot.dart';
import '../../core/models/daily_log.dart';
import '../../core/theme/app_theme.dart';
import '../labs/labs_screen.dart';
import '../patterns/patterns_screen.dart';
import '../food/food_screen.dart';
import '../settings/settings_screen.dart';
import '../habits/daily_habit_screen.dart';

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
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
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
            label: 'Patterns',
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

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recalculate score on each build
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('LipidLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Card
            _ScoreCard(score: score),
            const SizedBox(height: 24),

            // Today's Habits Card
            _TodayHabitsCard(),
            const SizedBox(height: 24),

            // This Week Summary
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

class _ScoreCard extends StatelessWidget {
  final ScoreSnapshot? score;

  const _ScoreCard({this.score});

  @override
  Widget build(BuildContext context) {
    final scoreValue = score?.overallScore ?? 0;
    final goalScore = score?.goalScore;
    final delta = score?.deltaToGoal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Your Cholesterol Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Score Circle
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CircularProgressIndicator(
                      value: scoreValue / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.getScoreColor(scoreValue),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        scoreValue.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      if (goalScore != null)
                        Text(
                          'Goal: ${goalScore.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Score Grade
            if (score != null)
              Text(
                score!.scoreGrade,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.getScoreColor(scoreValue),
                    ),
              ),

            if (delta != null && delta > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${delta.toStringAsFixed(0)} points to your target',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            // Latest Lab Values
            if (score != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _LabValuesRow(),
            ],
          ],
        ),
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
          _LabValue(
            label: 'LDL',
            value: latestLab.ldl!.toStringAsFixed(0),
          ),
        if (latestLab.hdl != null)
          _LabValue(
            label: 'HDL',
            value: latestLab.hdl!.toStringAsFixed(0),
          ),
        if (latestLab.triglycerides != null)
          _LabValue(
            label: 'TG',
            value: latestLab.triglycerides!.toStringAsFixed(0),
          ),
      ],
    );
  }
}

class _LabValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _TodayHabitsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Habits',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyHabitScreen(),
                      ),
                    );
                  },
                  child: const Text('Log'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track your daily behaviors to improve your score',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (summary == null)
              Text(
                'Log your daily habits to see weekly insights',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Text(
                'Days logged: ${summary.daysLogged}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Best habit: ${summary.bestHabit.label} (${(summary.bestHabit.score * 100).toStringAsFixed(0)}%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Needs work: ${summary.worstHabit.label} (${(summary.worstHabit.score * 100).toStringAsFixed(0)}%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
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
