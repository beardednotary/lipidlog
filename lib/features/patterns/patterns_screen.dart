import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/models/daily_log.dart';
import '../../core/models/enums.dart';
import '../../core/models/lab_result.dart';
import '../../core/models/score_snapshot.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/weekly_insights_service.dart';
import '../../core/theme/app_theme.dart';

class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  int _selectedMetric = 0; // 0 LDL, 1 TG, 2 Score

  @override
  Widget build(BuildContext context) {
    final profile = StorageService.getUserProfile();
    final labs = StorageService.getAllLabResults();
    final logs = StorageService.getAllDailyLogs();
    final scores = StorageService.getAllScoreSnapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patterns & Trends'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricTrendCard(
              selectedMetric: _selectedMetric,
              labs: labs,
              scores: scores,
              onMetricChanged: (value) {
                setState(() => _selectedMetric = value);
              },
            ),
            const SizedBox(height: 16),
            _WeeklySummaryCard(logs: logs),
            const SizedBox(height: 16),
            _CorrelationInsightsCard(
              logs: logs,
              labs: labs,
              scores: scores,
              onMedication: profile?.onMedication ?? false,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTrendCard extends StatelessWidget {
  final int selectedMetric;
  final List<LabResult> labs;
  final List<ScoreSnapshot> scores;
  final ValueChanged<int> onMetricChanged;

  const _MetricTrendCard({
    required this.selectedMetric,
    required this.labs,
    required this.scores,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    final hasEnoughData = points.length >= 2;
    final current = hasEnoughData ? points.last.value : null;
    final delta = hasEnoughData ? points.last.value - points.first.value : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('LDL')),
                ButtonSegment<int>(value: 1, label: Text('TG')),
                ButtonSegment<int>(value: 2, label: Text('Score')),
              ],
              selected: {selectedMetric},
              onSelectionChanged: (selection) {
                onMetricChanged(selection.first);
              },
            ),
            const SizedBox(height: 12),
            if (hasEnoughData) ...[
              Text(
                _headline(current!, delta!),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                _subline(points.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            if (!hasEnoughData)
              Text(
                'Add more data points to unlock this trend.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              SizedBox(
                height: 210,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points
                            .asMap()
                            .entries
                            .map((entry) => FlSpot(
                                  entry.key.toDouble(),
                                  entry.value.value,
                                ))
                            .toList(),
                        isCurved: true,
                        color: _metricColor(),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _metricColor().withValues(alpha: 0.12),
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

  List<_MetricPoint> _buildPoints() {
    if (selectedMetric == 2) {
      final byDay = <DateTime, ScoreSnapshot>{};
      for (final score in scores) {
        final day = DateTime(score.date.year, score.date.month, score.date.day);
        final existing = byDay[day];
        if (existing == null || score.date.isAfter(existing.date)) {
          byDay[day] = score;
        }
      }
      final sortedDays = byDay.keys.toList()..sort();
      return sortedDays
          .map((day) => _MetricPoint(day: day, value: byDay[day]!.overallScore))
          .toList();
    }

    final sortedLabs = List<LabResult>.from(labs)
      ..sort((a, b) => a.date.compareTo(b.date));
    final points = <_MetricPoint>[];
    for (final lab in sortedLabs) {
      final value = selectedMetric == 0 ? lab.ldl : lab.triglycerides;
      if (value != null) {
        points.add(_MetricPoint(day: lab.date, value: value));
      }
    }
    return points;
  }

  Color _metricColor() {
    switch (selectedMetric) {
      case 0:
        return Colors.blue.shade600;
      case 1:
        return Colors.orange.shade700;
      case 2:
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _headline(double current, double delta) {
    final metric = selectedMetric == 0
        ? 'LDL'
        : selectedMetric == 1
            ? 'TG'
            : 'Score';
    final direction = delta > 0 ? 'up' : (delta < 0 ? 'down' : 'flat');
    final abs = delta.abs().toStringAsFixed(0);
    return '$metric now ${current.toStringAsFixed(0)} ($direction $abs)';
  }

  String _subline(int pointsCount) {
    final metric = selectedMetric == 0
        ? 'LDL'
        : selectedMetric == 1
            ? 'triglyceride'
            : 'score';
    return '$pointsCount $metric data points';
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final List<DailyLog> logs;

  const _WeeklySummaryCard({
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = logs.where((log) => log.date.isAfter(weekAgo)).toList();

    if (recent.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Log daily habits to generate a weekly summary.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final daysLogged = recent.length;
    final alcoholFree =
        recent.where((log) => log.alcoholLevel == AlcoholLevel.none).length;
    final steps = recent.where((log) => log.stepsGoalHit).length;
    final meds = recent.where((log) => log.medicationTaken).length;

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
            const SizedBox(height: 10),
            Text('Days logged: $daysLogged'),
            Text('Alcohol-free days: $alcoholFree/$daysLogged'),
            Text('Steps goal days: $steps/$daysLogged'),
            Text('Medication adherence days: $meds/$daysLogged'),
          ],
        ),
      ),
    );
  }
}

class _CorrelationInsightsCard extends StatelessWidget {
  final List<DailyLog> logs;
  final List<LabResult> labs;
  final List<ScoreSnapshot> scores;
  final bool onMedication;

  const _CorrelationInsightsCard({
    required this.logs,
    required this.labs,
    required this.scores,
    required this.onMedication,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correlation Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              Text(
                'Need more consistent logs to identify habit-to-lipid patterns.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('- $insight'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _buildInsights() {
    final insights = <String>[];

    final ldlChange = _metricPercentChange(
      labs: labs,
      getter: (lab) => lab.ldl,
    );
    if (ldlChange != null) {
      final sign = ldlChange <= 0 ? 'down' : 'up';
      insights.add(
          'LDL is $sign ${ldlChange.abs().toStringAsFixed(0)}% from earliest recorded lab.');
    }

    final tgChange = _metricPercentChange(
      labs: labs,
      getter: (lab) => lab.triglycerides,
    );
    if (tgChange != null) {
      final sign = tgChange <= 0 ? 'down' : 'up';
      insights.add(
          'Triglycerides are $sign ${tgChange.abs().toStringAsFixed(0)}% from earliest recorded lab.');
    }

    final weeks = WeeklyInsightsService.buildWeeklyStats(logs, scores);
    if (weeks.length >= 2) {
      final alcoholInsight = _compareWeekBuckets(
        weeks: weeks,
        lowCondition: (w) => w.alcoholDays <= 1,
        highCondition: (w) => w.alcoholDays >= 3,
        label: 'weeks with <=1 alcohol day',
        altLabel: 'weeks with >=3 alcohol days',
      );
      if (alcoholInsight != null) insights.add(alcoholInsight);

      final stepsInsight = _compareWeekBuckets(
        weeks: weeks,
        lowCondition: (w) => w.stepsGoalDays <= 2,
        highCondition: (w) => w.stepsGoalDays >= 4,
        label: 'weeks with >=4 step-goal days',
        altLabel: 'weeks with <=2 step-goal days',
        reverse: true,
      );
      if (stepsInsight != null) insights.add(stepsInsight);

      if (onMedication) {
        final medsInsight = _compareWeekBuckets(
          weeks: weeks,
          lowCondition: (w) => w.medDays <= 4,
          highCondition: (w) => w.medDays >= 6,
          label: 'weeks with >=6 medication-adherent days',
          altLabel: 'weeks with <=4 medication-adherent days',
          reverse: true,
        );
        if (medsInsight != null) insights.add(medsInsight);
      }
    }

    return insights.take(4).toList();
  }

  String? _compareWeekBuckets({
    required List<WeekStats> weeks,
    required bool Function(WeekStats) lowCondition,
    required bool Function(WeekStats) highCondition,
    required String label,
    required String altLabel,
    bool reverse = false,
  }) {
    final low = weeks.where((w) => lowCondition(w) && w.hasScore).toList();
    final high = weeks.where((w) => highCondition(w) && w.hasScore).toList();
    if (low.isEmpty || high.isEmpty) return null;

    final lowAvg =
        low.map((w) => w.avgScore).reduce((a, b) => a + b) / low.length;
    final highAvg =
        high.map((w) => w.avgScore).reduce((a, b) => a + b) / high.length;

    double delta;
    String betterLabel;
    String weakerLabel;
    if (reverse) {
      delta = lowAvg - highAvg;
      betterLabel = label;
      weakerLabel = altLabel;
    } else {
      delta = highAvg - lowAvg;
      betterLabel = label;
      weakerLabel = altLabel;
    }

    return '$betterLabel averaged ${delta.abs().toStringAsFixed(0)} points '
        '${delta >= 0 ? 'higher' : 'lower'} than $weakerLabel.';
  }

  double? _metricPercentChange({
    required List<LabResult> labs,
    required double? Function(LabResult) getter,
  }) {
    final sorted = List<LabResult>.from(labs)
      ..sort((a, b) => a.date.compareTo(b.date));
    double? first;
    double? last;
    for (final lab in sorted) {
      final value = getter(lab);
      if (value != null) {
        first ??= value;
        last = value;
      }
    }
    if (first == null || last == null || first == 0) return null;
    return ((last - first) / first) * 100;
  }
}

class _MetricPoint {
  final DateTime day;
  final double value;

  _MetricPoint({
    required this.day,
    required this.value,
  });
}
