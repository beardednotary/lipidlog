import '../models/daily_log.dart';
import '../models/enums.dart';
import '../models/score_snapshot.dart';

class WeekStats {
  final DateTime weekStart;
  int totalDays = 0;
  int alcoholDays = 0;
  int stepsGoalDays = 0;
  int medDays = 0;
  int goodSleepDays = 0;
  int highCarbDays = 0;
  int highSatFatDays = 0;
  int lateNightDays = 0;
  double scoreTotal = 0;
  int scoreCount = 0;

  WeekStats({
    required this.weekStart,
  });

  bool get hasScore => scoreCount > 0;
  double get avgScore => scoreCount == 0 ? 0 : scoreTotal / scoreCount;
}

class WeekHabitScore {
  final String label;
  final double score; // 0..1

  const WeekHabitScore({
    required this.label,
    required this.score,
  });
}

class WeekSummary {
  final int daysLogged;
  final WeekHabitScore bestHabit;
  final WeekHabitScore worstHabit;
  final String trajectory;

  const WeekSummary({
    required this.daysLogged,
    required this.bestHabit,
    required this.worstHabit,
    required this.trajectory,
  });
}

class WeeklyInsightsService {
  static List<WeekStats> buildWeeklyStats(
    List<DailyLog> logs,
    List<ScoreSnapshot> scores, {
    int minDays = 3,
  }) {
    final normalizedScores = <DateTime, double>{};
    for (final score in scores) {
      final day = DateTime(score.date.year, score.date.month, score.date.day);
      final existing = normalizedScores[day];
      if (existing == null) {
        normalizedScores[day] = score.overallScore;
      } else {
        normalizedScores[day] = (existing + score.overallScore) / 2;
      }
    }

    final map = <DateTime, WeekStats>{};
    for (final log in logs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      final start = weekStart(day);
      final current = map[start] ?? WeekStats(weekStart: start);
      current.totalDays += 1;
      if (log.alcoholLevel != AlcoholLevel.none) current.alcoholDays += 1;
      if (log.stepsGoalHit) current.stepsGoalDays += 1;
      if (log.medicationTaken) current.medDays += 1;
      if (log.sleepCategory == SleepCategory.normal6to8h) {
        current.goodSleepDays += 1;
      }
      if (log.highCarbDay) current.highCarbDays += 1;
      if (log.highSatFatDay) current.highSatFatDays += 1;
      if (log.lateNightEating) current.lateNightDays += 1;

      final score = normalizedScores[day];
      if (score != null) {
        current.scoreTotal += score;
        current.scoreCount += 1;
      }

      map[start] = current;
    }

    final weeks = map.values.toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return weeks.where((week) => week.totalDays >= minDays).toList();
  }

  static WeekSummary? buildCurrentWeekSummary(
    List<DailyLog> logs,
    List<ScoreSnapshot> scores, {
    required bool onMedication,
  }) {
    final now = DateTime.now();
    final start = weekStart(now);
    final weekLogs = logs.where((log) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      return !day.isBefore(start);
    }).toList();

    if (weekLogs.isEmpty) return null;

    final days = weekLogs.length.toDouble();
    final candidates = <WeekHabitScore>[
      WeekHabitScore(
        label: 'alcohol-free consistency',
        score: weekLogs
                .where((log) => log.alcoholLevel == AlcoholLevel.none)
                .length /
            days,
      ),
      WeekHabitScore(
        label: 'steps goal consistency',
        score: weekLogs.where((log) => log.stepsGoalHit).length / days,
      ),
      WeekHabitScore(
        label: 'good sleep consistency',
        score: weekLogs
                .where((log) => log.sleepCategory == SleepCategory.normal6to8h)
                .length /
            days,
      ),
      WeekHabitScore(
        label: 'low-carb consistency',
        score: 1 - (weekLogs.where((log) => log.highCarbDay).length / days),
      ),
      WeekHabitScore(
        label: 'low sat-fat consistency',
        score: 1 - (weekLogs.where((log) => log.highSatFatDay).length / days),
      ),
      WeekHabitScore(
        label: 'late-night control',
        score: 1 - (weekLogs.where((log) => log.lateNightEating).length / days),
      ),
    ];

    if (onMedication) {
      candidates.add(
        WeekHabitScore(
          label: 'medication adherence',
          score: weekLogs.where((log) => log.medicationTaken).length / days,
        ),
      );
    }

    final sorted = List<WeekHabitScore>.from(candidates)
      ..sort((a, b) => a.score.compareTo(b.score));
    final worst = sorted.first;
    final best = sorted.last;

    final weeks = buildWeeklyStats(logs, scores);
    final trajectory = _buildTrajectory(weeks);

    return WeekSummary(
      daysLogged: weekLogs.length,
      bestHabit: best,
      worstHabit: worst,
      trajectory: trajectory,
    );
  }

  static String _buildTrajectory(List<WeekStats> weeks) {
    final scoredWeeks = weeks.where((week) => week.hasScore).toList();
    if (scoredWeeks.length < 2) {
      return 'Trajectory pending: add more score snapshots this week.';
    }

    final latest = scoredWeeks.last.avgScore;
    final previous = scoredWeeks[scoredWeeks.length - 2].avgScore;
    final delta = latest - previous;

    final projected = (latest + (delta * 4)).clamp(0, 100).toStringAsFixed(0);
    if (delta > 1) {
      return 'Improving: +${delta.toStringAsFixed(0)} this week. 4-week projection: $projected.';
    }
    if (delta < -1) {
      return 'Slipping: ${delta.toStringAsFixed(0)} this week. 4-week projection: $projected.';
    }
    return 'Stable: ${delta.toStringAsFixed(0)} this week. 4-week projection: $projected.';
  }

  static DateTime weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }
}
