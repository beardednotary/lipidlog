import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/models/daily_log.dart';
import '../../core/models/enums.dart';
import '../../core/models/lab_result.dart';
import '../../core/models/score_snapshot.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/score_service.dart';
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

    final sortedLabs = List<LabResult>.from(labs)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Compute goal score for the Score chart goal line
    double? computedGoalScore;
    if (profile != null && sortedLabs.isNotEmpty) {
      computedGoalScore = ScoreService.computeGoalScore(
        profile: profile,
        latestLab: sortedLabs.first,
        mode: profile.focusMode,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),
        ),
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
              profile: profile,
              goalScoreValue: computedGoalScore,
              onMetricChanged: (value) {
                setState(() => _selectedMetric = value);
              },
            ),
            const SizedBox(height: 16),
            _ScoreForecastCard(
              scores: scores,
              goalScore: computedGoalScore,
              currentScore: scores.isNotEmpty
                  ? (List<ScoreSnapshot>.from(scores)
                        ..sort((a, b) => b.date.compareTo(a.date)))
                      .first
                      .overallScore
                  : null,
            ),
            const SizedBox(height: 16),
            _WeeklySummaryCard(logs: logs),
            const SizedBox(height: 16),
            _CoreInsightsCard(labs: labs, logs: logs),
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

// ── Metric Trend Card ──────────────────────────────────────────────────────────

class _MetricTrendCard extends StatelessWidget {
  final int selectedMetric;
  final List<LabResult> labs;
  final List<ScoreSnapshot> scores;
  final UserProfile? profile;
  final double? goalScoreValue;
  final ValueChanged<int> onMetricChanged;

  const _MetricTrendCard({
    required this.selectedMetric,
    required this.labs,
    required this.scores,
    required this.profile,
    required this.goalScoreValue,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    final hasEnoughData = points.length >= 2;
    final current = hasEnoughData ? points.last.value : null;
    final delta = hasEnoughData ? points.last.value - points.first.value : null;
    final lineColor = _metricColor();
    final target = _goalValue();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trend Dashboard',
                style: Theme.of(context).textTheme.titleLarge),
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
              _DeltaRow(
                current: current!,
                delta: delta!,
                selectedMetric: selectedMetric,
              ),
              const SizedBox(height: 4),
              Text(
                '${points.length} data points',
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
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.min || value == meta.max) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textTertiary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    extraLinesData: target != null
                        ? ExtraLinesData(horizontalLines: [
                            HorizontalLine(
                              y: target,
                              color: AppTheme.positiveColor
                                  .withValues(alpha: 0.7),
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                labelResolver: (_) => 'Goal',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.positiveColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ])
                        : null,
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
                        curveSmoothness: 0.35,
                        color: lineColor,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            radius: 4,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              lineColor.withValues(alpha: 0.15),
                              lineColor.withValues(alpha: 0.0),
                            ],
                          ),
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
        final day =
            DateTime(score.date.year, score.date.month, score.date.day);
        final existing = byDay[day];
        if (existing == null || score.date.isAfter(existing.date)) {
          byDay[day] = score;
        }
      }
      final sortedDays = byDay.keys.toList()..sort();
      return sortedDays
          .map((day) =>
              _MetricPoint(day: day, value: byDay[day]!.overallScore))
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
        return AppTheme.primaryColor;
      case 1:
        return AppTheme.warningColor;
      default:
        return AppTheme.positiveColor;
    }
  }

  double? _goalValue() {
    if (selectedMetric == 0) return profile?.ldlTarget;
    if (selectedMetric == 1) return profile?.tgTarget;
    return goalScoreValue;
  }
}

class _DeltaRow extends StatelessWidget {
  final double current;
  final double delta;
  final int selectedMetric;

  const _DeltaRow({
    required this.current,
    required this.delta,
    required this.selectedMetric,
  });

  @override
  Widget build(BuildContext context) {
    final metric = selectedMetric == 0
        ? 'LDL'
        : selectedMetric == 1
            ? 'TG'
            : 'Score';
    final absStr = delta.abs().toStringAsFixed(0);

    // For LDL/TG, down is good. For Score, up is good.
    final bool isGood = selectedMetric == 2 ? delta > 0 : delta < 0;
    final bool isFlat = delta == 0;
    final color = isFlat
        ? AppTheme.textSecondary
        : isGood
            ? AppTheme.positiveColor
            : AppTheme.dangerColor;

    final arrow = isFlat
        ? '→'
        : delta > 0
            ? '↑'
            : '↓';

    return Row(
      children: [
        Text(
          '$metric ${current.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 8),
        if (!isFlat)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$arrow $absStr pts',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}

// ── Score Forecast Card ────────────────────────────────────────────────────────

class _ScoreForecastCard extends StatelessWidget {
  final List<ScoreSnapshot> scores;
  final double? goalScore;
  final double? currentScore;

  const _ScoreForecastCard({
    required this.scores,
    required this.goalScore,
    required this.currentScore,
  });

  double? _weeklyVelocity() {
    if (scores.length < 2) return null;
    final sorted = List<ScoreSnapshot>.from(scores)
      ..sort((a, b) => a.date.compareTo(b.date));
    final days =
        sorted.last.date.difference(sorted.first.date).inDays;
    if (days < 7) return null;
    return (sorted.last.overallScore - sorted.first.overallScore) /
        days *
        7;
  }

  @override
  Widget build(BuildContext context) {
    final cs = currentScore;
    if (cs == null) return const SizedBox.shrink();

    final velocity = _weeklyVelocity();
    final projected4wk = velocity != null
        ? (cs + velocity * 4).clamp(0.0, 100.0)
        : null;

    final hasContent = projected4wk != null || goalScore != null;
    if (!hasContent) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score Forecast',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Projections based on current data',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.dividerColor, height: 1),
            const SizedBox(height: 16),
            if (projected4wk != null) ...[
              _ForecastRow(
                label: 'If you maintain current habits',
                sublabel: 'Projected score in 4 weeks',
                projected: projected4wk,
                current: cs,
                velocity: velocity,
              ),
            ],
            if (projected4wk != null && goalScore != null)
              const SizedBox(height: 16),
            if (goalScore != null) ...[
              _ForecastRow(
                label: 'At doctor-prescribed targets',
                sublabel: 'Projected score if labs hit goals',
                projected: goalScore!,
                current: cs,
                velocity: null,
                isGoal: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double projected;
  final double current;
  final double? velocity;
  final bool isGoal;

  const _ForecastRow({
    required this.label,
    required this.sublabel,
    required this.projected,
    required this.current,
    this.velocity,
    this.isGoal = false,
  });

  @override
  Widget build(BuildContext context) {
    final delta = projected - current;
    final isImprovement = delta > 0;
    final color = isGoal
        ? AppTheme.primaryColor
        : isImprovement
            ? AppTheme.positiveColor
            : AppTheme.warningColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(sublabel,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                projected.toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)} pts',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    'from ${current.toStringAsFixed(0)} today',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Weekly Summary Card ────────────────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final List<DailyLog> logs;

  const _WeeklySummaryCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = logs.where((log) => log.date.isAfter(weekAgo)).toList();

    if (recent.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
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

    final stats = [
      _StatRow(
        label: 'Days logged',
        value: '$daysLogged / 7',
        highlight: daysLogged >= 5 ? AppTheme.positiveColor : null,
      ),
      _StatRow(
        label: 'Alcohol-free days',
        value: '$alcoholFree / $daysLogged',
        highlight: alcoholFree == daysLogged
            ? AppTheme.positiveColor
            : alcoholFree < daysLogged ~/ 2
                ? AppTheme.warningColor
                : null,
      ),
      _StatRow(
        label: 'Steps goal days',
        value: '$steps / $daysLogged',
        highlight:
            steps >= daysLogged * 0.7 ? AppTheme.positiveColor : null,
      ),
      _StatRow(
        label: 'Medication days',
        value: '$meds / $daysLogged',
        highlight: meds == daysLogged
            ? AppTheme.positiveColor
            : meds < daysLogged * 0.8
                ? AppTheme.warningColor
                : null,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.dividerColor, height: 1),
            const SizedBox(height: 12),
            ...stats.map((stat) => stat),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlight;

  const _StatRow({required this.label, required this.value, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: highlight ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Core Insights Card ─────────────────────────────────────────────────────────

class _CoreInsightsCard extends StatelessWidget {
  final List<LabResult> labs;
  final List<DailyLog> logs;

  const _CoreInsightsCard({required this.labs, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (labs.isEmpty) return const SizedBox.shrink();

    final sorted = List<LabResult>.from(labs)
      ..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.first;

    final sections = <_LabInsightSection>[];

    // TG
    final tg = latest.triglycerides;
    if (tg != null && tg >= 150) {
      final logNote = _tgLogNote();
      sections.add(_LabInsightSection(
        metric: 'Triglycerides',
        value: tg,
        status: tg >= 500
            ? 'Very High'
            : tg >= 200
                ? 'High'
                : 'Borderline',
        statusColor: tg >= 200 ? AppTheme.dangerColor : AppTheme.warningColor,
        drivers: [
          'Sugary beverages & fruit juice',
          'Refined carbohydrates (bread, pasta, rice)',
          'Alcohol',
          'Excess caloric intake',
        ],
        logNote: logNote,
      ));
    }

    // LDL
    final ldl = latest.ldl;
    if (ldl != null && ldl >= 100) {
      final logNote = _ldlLogNote();
      sections.add(_LabInsightSection(
        metric: 'LDL Cholesterol',
        value: ldl,
        status: ldl >= 190
            ? 'Very High'
            : ldl >= 160
                ? 'High'
                : ldl >= 130
                    ? 'Borderline'
                    : 'Near Optimal',
        statusColor: ldl >= 160
            ? AppTheme.dangerColor
            : ldl >= 130
                ? AppTheme.warningColor
                : AppTheme.textSecondary,
        drivers: [
          'Saturated fat (butter, red meat, cheese)',
          'Trans fats (processed foods)',
          'Low dietary fiber',
          'Genetic predisposition',
        ],
        logNote: logNote,
      ));
    }

    // HDL
    final hdl = latest.hdl;
    if (hdl != null && hdl < 60) {
      final logNote = _hdlLogNote();
      sections.add(_LabInsightSection(
        metric: 'HDL Cholesterol',
        value: hdl,
        status: hdl < 40 ? 'Low' : 'Below Optimal',
        statusColor:
            hdl < 40 ? AppTheme.dangerColor : AppTheme.warningColor,
        drivers: [
          'Lack of regular aerobic exercise',
          'High carbohydrate diet',
          'Excess body weight',
          'Smoking',
        ],
        logNote: logNote,
        isLow: true,
      ));
    }

    if (sections.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.positiveColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your lab values look healthy — no major drivers to flag.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.positiveColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What May Be Affecting Your Labs',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Based on your current values and logged habits',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...sections.map((section) => _buildSection(context, section)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, _LabInsightSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric header
          Row(
            children: [
              Expanded(
                child: Text(section.metric,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: section.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${section.value.toStringAsFixed(0)} · ${section.status}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: section.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.isLow ? 'Common reasons HDL stays low:' : 'Common drivers:',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...section.drivers.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(d,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              )),
          if (section.logNote != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_outline,
                      size: 13, color: AppTheme.warningColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Based on your logs: ${section.logNote}',
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
    );
  }

  String? _tgLogNote() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = logs.where((l) => l.date.isAfter(weekAgo)).toList();
    if (recent.isEmpty) return null;
    final highCarb = recent.where((l) => l.highCarbDay).length;
    final alcohol =
        recent.where((l) => l.alcoholLevel != AlcoholLevel.none).length;
    if (highCarb >= 3) return 'High-carb days logged $highCarb times this week.';
    if (alcohol >= 3) return 'Alcohol logged $alcohol days this week.';
    return null;
  }

  String? _ldlLogNote() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = logs.where((l) => l.date.isAfter(weekAgo)).toList();
    if (recent.isEmpty) return null;
    final satFat = recent.where((l) => l.highSatFatDay).length;
    if (satFat >= 3) return 'High saturated fat days logged $satFat times this week.';
    return null;
  }

  String? _hdlLogNote() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = logs.where((l) => l.date.isAfter(weekAgo)).toList();
    if (recent.isEmpty) return null;
    final steps = recent.where((l) => l.stepsGoalHit).length;
    if (steps <= 2) return 'Steps goal hit only $steps days this week — exercise is the #1 way to raise HDL.';
    return null;
  }
}

class _LabInsightSection {
  final String metric;
  final double value;
  final String status;
  final Color statusColor;
  final List<String> drivers;
  final String? logNote;
  final bool isLow;

  const _LabInsightSection({
    required this.metric,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.drivers,
    this.logNote,
    this.isLow = false,
  });
}

// ── Correlation Insights Card ──────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Habit Correlations',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              Text(
                'Need more consistent logs to identify habit-to-score patterns.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.compare_arrows_outlined,
                        size: 16,
                        color: AppTheme.primaryColor,
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
          'LDL is $sign ${ldlChange.abs().toStringAsFixed(0)}% from your earliest recorded lab.');
    }

    final tgChange = _metricPercentChange(
      labs: labs,
      getter: (lab) => lab.triglycerides,
    );
    if (tgChange != null) {
      final sign = tgChange <= 0 ? 'down' : 'up';
      insights.add(
          'Triglycerides are $sign ${tgChange.abs().toStringAsFixed(0)}% from your earliest recorded lab.');
    }

    final weeks = WeeklyInsightsService.buildWeeklyStats(logs, scores);
    if (weeks.length >= 2) {
      final alcoholInsight = _compareWeekBuckets(
        weeks: weeks,
        lowCondition: (w) => w.alcoholDays <= 1,
        highCondition: (w) => w.alcoholDays >= 3,
        label: 'weeks with ≤1 alcohol day',
        altLabel: 'weeks with ≥3 alcohol days',
      );
      if (alcoholInsight != null) insights.add(alcoholInsight);

      final stepsInsight = _compareWeekBuckets(
        weeks: weeks,
        lowCondition: (w) => w.stepsGoalDays <= 2,
        highCondition: (w) => w.stepsGoalDays >= 4,
        label: 'weeks with ≥4 step-goal days',
        altLabel: 'weeks with ≤2 step-goal days',
        reverse: true,
      );
      if (stepsInsight != null) insights.add(stepsInsight);

      if (onMedication) {
        final medsInsight = _compareWeekBuckets(
          weeks: weeks,
          lowCondition: (w) => w.medDays <= 4,
          highCondition: (w) => w.medDays >= 6,
          label: 'weeks with ≥6 medication-adherent days',
          altLabel: 'weeks with ≤4 medication-adherent days',
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

  _MetricPoint({required this.day, required this.value});
}
