import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/score_service.dart';
import '../../core/models/score_snapshot.dart';
import '../../core/models/lab_result.dart';
import '../../core/models/daily_log.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';

class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  @override
  Widget build(BuildContext context) {
    // Get all data
    final profile = StorageService.getUserProfile();
    final labs = StorageService.getAllLabResults();
    final logs = StorageService.getAllDailyLogs();

    // Calculate current score
    ScoreSnapshot? currentScore;
    if (profile != null) {
      currentScore = ScoreService.computeScores(
        profile: profile,
        labs: labs,
        logs: logs,
      );
    }

    // Get historical scores (we'll build this over time)
    final historicalScores = _calculateHistoricalScores(profile, labs, logs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patterns & Trends'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Trend Chart
            if (currentScore != null) ...[
              _ScoreTrendCard(
                scores: historicalScores,
                currentScore: currentScore,
              ),
              const SizedBox(height: 16),
            ],

            // This Week Summary
            _ThisWeekSummaryCard(logs: logs),
            const SizedBox(height: 16),

            // Lab History
            _LabHistoryCard(labs: labs),
            const SizedBox(height: 16),

            // Insights
            if (logs.length >= 7)
              _InsightsCard(logs: logs, currentScore: currentScore),
          ],
        ),
      ),
    );
  }

  List<ScoreSnapshot> _calculateHistoricalScores(
    profile,
    List<LabResult> labs,
    List<DailyLog> logs,
  ) {
    if (profile == null) return [];

    final List<ScoreSnapshot> scores = [];
    final now = DateTime.now();

    // Calculate score for each day we have data
    for (int i = 0; i <= 90; i++) {
      final date = now.subtract(Duration(days: i));

      // Get labs up to this date
      final labsUpToDate = labs
          .where((lab) =>
              lab.date.isBefore(date) || lab.date.isAtSameMomentAs(date))
          .toList();

      // Get logs up to this date
      final logsUpToDate = logs
          .where((log) =>
              log.date.isBefore(date) || log.date.isAtSameMomentAs(date))
          .toList();

      if (labsUpToDate.isEmpty) continue;

      final score = ScoreService.computeScores(
        profile: profile,
        labs: labsUpToDate,
        logs: logsUpToDate,
      );

      scores.add(score);
    }

    // Reverse so oldest is first
    return scores.reversed.toList();
  }
}

class _ScoreTrendCard extends StatelessWidget {
  final List<ScoreSnapshot> scores;
  final ScoreSnapshot currentScore;

  const _ScoreTrendCard({
    required this.scores,
    required this.currentScore,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Score Trend',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Log habits daily to see your trend',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate change
    final firstScore = scores.first.overallScore;
    final lastScore = scores.last.overallScore;
    final change = lastScore - firstScore;
    final isPositive = change > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isPositive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.abs().toStringAsFixed(0)} pts',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: scores.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.overallScore,
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last ${scores.length} days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThisWeekSummaryCard extends StatelessWidget {
  final List<DailyLog> logs;

  const _ThisWeekSummaryCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Get logs from last 7 days
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeekLogs =
        logs.where((log) => log.date.isAfter(weekAgo)).toList();

    if (thisWeekLogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'This Week',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Log your daily habits to see weekly insights',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate stats
    final daysLogged = thisWeekLogs.length;
    final medsCount = thisWeekLogs.where((log) => log.medicationTaken).length;
    final stepsCount = thisWeekLogs.where((log) => log.stepsGoalHit).length;
    final noAlcoholCount = thisWeekLogs
        .where((log) => log.alcoholLevel == AlcoholLevel.none)
        .length;
    final goodSleepCount = thisWeekLogs
        .where((log) => log.sleepCategory == SleepCategory.normal6to8h)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$daysLogged days logged',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _HabitStat(
              icon: Icons.medication,
              label: 'Medication taken',
              count: medsCount,
              total: daysLogged,
            ),
            const SizedBox(height: 8),
            _HabitStat(
              icon: Icons.directions_walk,
              label: 'Steps goal hit',
              count: stepsCount,
              total: daysLogged,
            ),
            const SizedBox(height: 8),
            _HabitStat(
              icon: Icons.no_drinks,
              label: 'No alcohol',
              count: noAlcoholCount,
              total: daysLogged,
            ),
            const SizedBox(height: 8),
            _HabitStat(
              icon: Icons.bedtime,
              label: 'Good sleep (6-8h)',
              count: goodSleepCount,
              total: daysLogged,
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int total;

  const _HabitStat({
    required this.icon,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    final isGood = percentage >= 70;

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '$count/$total',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isGood ? Colors.green : Colors.orange,
              ),
        ),
      ],
    );
  }
}

class _LabHistoryCard extends StatelessWidget {
  final List<LabResult> labs;

  const _LabHistoryCard({required this.labs});

  @override
  Widget build(BuildContext context) {
    if (labs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.science_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Lab History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add lab results to see trends',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lab History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...labs.take(3).map((lab) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LabHistoryItem(lab: lab),
                )),
          ],
        ),
      ),
    );
  }
}

class _LabHistoryItem extends StatelessWidget {
  final LabResult lab;

  const _LabHistoryItem({required this.lab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${lab.date.month}/${lab.date.day}/${lab.date.year}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'LDL: ${lab.ldl?.toStringAsFixed(0) ?? '--'} • '
                'HDL: ${lab.hdl?.toStringAsFixed(0) ?? '--'} • '
                'TG: ${lab.triglycerides?.toStringAsFixed(0) ?? '--'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final List<DailyLog> logs;
  final ScoreSnapshot? currentScore;

  const _InsightsCard({
    required this.logs,
    this.currentScore,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    if (insights.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights() {
    final insights = <String>[];
    final recentLogs = logs.take(14).toList();

    if (recentLogs.isEmpty) return insights;

    // Medication adherence
    final medsTaken = recentLogs.where((log) => log.medicationTaken).length;
    final medsPercentage = (medsTaken / recentLogs.length * 100).toInt();
    if (medsPercentage < 70) {
      insights.add(
          'Taking medication consistently could improve your score by 5-8 points');
    } else if (medsPercentage >= 90) {
      insights.add('Excellent medication adherence! Keep it up.');
    }

    // Steps
    final stepsHit = recentLogs.where((log) => log.stepsGoalHit).length;
    final stepsPercentage = (stepsHit / recentLogs.length * 100).toInt();
    if (stepsPercentage >= 80) {
      insights
          .add('You\'re crushing your step goal $stepsPercentage% of the time');
    }

    // Diet patterns
    final highCarbDays = recentLogs.where((log) => log.highCarbDay).length;
    if (highCarbDays > recentLogs.length / 2) {
      insights.add(
          'High-carb days are common. Reducing carbs could lower triglycerides faster');
    }

    // Sleep
    final poorSleep = recentLogs
        .where((log) => log.sleepCategory == SleepCategory.lessThan6h)
        .length;
    if (poorSleep > 3) {
      insights.add(
          'You had $poorSleep nights with poor sleep. Aim for 6-8 hours consistently');
    }

    return insights.take(3).toList();
  }
}
