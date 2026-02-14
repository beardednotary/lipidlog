import 'package:uuid/uuid.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../models/lab_result.dart';
import '../models/daily_log.dart';
import '../models/score_snapshot.dart';

/// The Cholesterol Score calculation engine
/// This is the intellectual property of LipidLog
class ScoreService {
  static const _uuid = Uuid();

  // ============================================================================
  // A. LAB SCORE (0-50 points)
  // ============================================================================

  /// Compute LDL subscore (0-10)
  static double _computeLDLScore10(double ldl) {
    if (ldl <= 70) return 10;
    if (ldl <= 99) return 9;
    if (ldl <= 129) return 7;
    if (ldl <= 159) return 5;
    if (ldl <= 189) return 3;
    return 0; // >= 190
  }

  /// Compute Triglycerides subscore (0-10)
  static double _computeTGScore10(double tg) {
    if (tg < 100) return 10;
    if (tg <= 149) return 9;
    if (tg <= 199) return 7;
    if (tg <= 499) return 4;
    return 0; // >= 500
  }

  /// Compute HDL subscore (0-10) - higher is better
  static double _computeHDLScore10(double hdl) {
    if (hdl >= 60) return 10;
    if (hdl >= 50) return 8;
    if (hdl >= 40) return 6;
    return 2; // < 40
  }

  /// Compute Total/HDL ratio subscore (0-10)
  static double _computeRatioScore10(double total, double hdl) {
    if (hdl == 0) return 2; // Avoid division by zero
    final ratio = total / hdl;
    if (ratio <= 3.5) return 10;
    if (ratio <= 4.5) return 8;
    if (ratio <= 6.0) return 5;
    return 2; // > 6.0
  }

  /// Compute Non-HDL subscore (0-10)
  static double _computeNonHDLScore10(double nonHdl) {
    if (nonHdl < 100) return 10;
    if (nonHdl <= 129) return 8;
    if (nonHdl <= 159) return 6;
    if (nonHdl <= 189) return 4;
    return 1; // >= 190
  }

  /// Compute overall Lab Score (0-50)
  static double computeLabScore(List<LabResult> labs, FocusMode mode) {
    if (labs.isEmpty) return 0;

    // Use most recent lab
    final latest = labs.first;

    double ldlScore10 = 0;
    double tgScore10 = 0;
    double hdlScore10 = 0;
    double ratioScore10 = 0;
    double nonHdlScore10 = 0;

    // Calculate each subscore if data available
    if (latest.ldl != null) {
      ldlScore10 = _computeLDLScore10(latest.ldl!);
    }

    if (latest.triglycerides != null) {
      tgScore10 = _computeTGScore10(latest.triglycerides!);
    }

    if (latest.hdl != null) {
      hdlScore10 = _computeHDLScore10(latest.hdl!);
    }

    if (latest.totalCholesterol != null && latest.hdl != null) {
      ratioScore10 = _computeRatioScore10(
        latest.totalCholesterol!,
        latest.hdl!,
      );
    }

    final nonHdl = latest.calculatedNonHdl;
    if (nonHdl != null) {
      nonHdlScore10 = _computeNonHDLScore10(nonHdl);
    }

    // Weighted combination
    // LDL: 35%, TG: 25%, HDL: 15%, Ratio: 15%, Non-HDL: 10%
    final weighted10 = (0.35 * ldlScore10) +
        (0.25 * tgScore10) +
        (0.15 * hdlScore10) +
        (0.15 * ratioScore10) +
        (0.10 * nonHdlScore10);

    // Scale to 0-50
    return (weighted10 * 5).clamp(0, 50);
  }

  // ============================================================================
  // B. BEHAVIOR SCORE (0-30 points)
  // ============================================================================

  /// Compute daily behavior points (raw, roughly -4 to +10)
  static double _computeDailyBehaviorRaw(
    DailyLog log,
    FocusMode mode,
    bool onMedication, // <-- ADD PARAMETER
  ) {
    double points = 0;

    // Steps goal hit: +2 if yes
    if (log.stepsGoalHit) points += 2;

    // Alcohol: 0 drinks = +2, 1 drink = +1, 2+ = -2
    switch (log.alcoholLevel) {
      case AlcoholLevel.none:
        points += 2;
        break;
      case AlcoholLevel.one:
        points += 1;
        break;
      case AlcoholLevel.twoPlus:
        points -= 2;
        break;
    }

    // Sleep: 6-8h = +1, >8h = +0.5, <6h = -1
    switch (log.sleepCategory) {
      case SleepCategory.normal6to8h:
        points += 1;
        break;
      case SleepCategory.moreThan8h:
        points += 0.5;
        break;
      case SleepCategory.lessThan6h:
        points -= 1;
        break;
    }

    // Late-night eating: -1 if yes
    if (log.lateNightEating) points -= 1;

    // High-carb day: -1 if yes
    if (log.highCarbDay) points -= 1;

    // High saturated fat: -2 if yes
    if (log.highSatFatDay) points -= 2;

    // Medication: only score if user is on meds
    if (onMedication) {
      // <-- ADD THIS CHECK
      if (log.medicationTaken) {
        points += 2;
      } else {
        points -= 1;
      }
    }
    // If not on meds, medication field is N/A and doesn't affect score

    // Stress: high = -1, medium = 0, low = +0.5
    switch (log.stressLevel) {
      case StressLevel.low:
        points += 0.5;
        break;
      case StressLevel.medium:
        // neutral
        break;
      case StressLevel.high:
        points -= 1;
        break;
    }

    return points;
  }

  /// Normalize daily behavior to 0-10 scale
  static double _normalizeDailyBehavior(double rawPoints) {
    // Raw points range from roughly -4 to +10
    // Map to 0-10 scale
    final clamped = rawPoints.clamp(-4, 10);
    return ((clamped + 4) / 14) * 10;
  }

  /// Compute Behavior Score (0-30)
  static double computeBehaviorScore(
    List<DailyLog> logs,
    FocusMode mode,
    bool onMedication, // <-- ADD PARAMETER
  ) {
    if (logs.isEmpty) return 15; // Neutral if no data

    const daysToConsider = 14;
    final recentLogs = logs.take(daysToConsider).toList();

    if (recentLogs.isEmpty) return 15;

    // Calculate normalized daily scores
    final normalizedScores = recentLogs.map((log) {
      final raw = _computeDailyBehaviorRaw(
          log, mode, onMedication); // <-- PASS PARAMETER
      return _normalizeDailyBehavior(raw);
    }).toList();

    final avgDaily10 =
        normalizedScores.reduce((a, b) => a + b) / normalizedScores.length;

    return (avgDaily10 * 3).clamp(0, 30);
  }

  // ============================================================================
  // C. TREND SCORE (0-20 points)
  // ============================================================================

  /// Compute Trend Score based on change over time
  static double computeTrendScore(List<LabResult> labs, FocusMode mode) {
    if (labs.length < 2) return 10; // Neutral if not enough data

    // Get oldest and newest (assuming labs are sorted by date desc)
    final latest = labs.first;
    final oldest = labs.last;

    double? latestValue;
    double? oldestValue;

    // Determine which metric to track based on mode
    switch (mode) {
      case FocusMode.ldl:
        latestValue = latest.ldl;
        oldestValue = oldest.ldl;
        break;
      case FocusMode.triglycerides:
        latestValue = latest.triglycerides;
        oldestValue = oldest.triglycerides;
        break;
      case FocusMode.both:
        // Use Non-HDL or combination
        latestValue = latest.calculatedNonHdl ?? latest.ldl;
        oldestValue = oldest.calculatedNonHdl ?? oldest.ldl;
        break;
    }

    if (latestValue == null || oldestValue == null || oldestValue == 0) {
      return 10; // Neutral
    }

    // Calculate percent change
    final delta = latestValue - oldestValue;
    final pctChange = (delta / oldestValue) * 100;

    // Map to points (improvement = negative change for LDL/TG)
    if (pctChange <= -20) return 20; // Excellent improvement
    if (pctChange <= -10) return 16; // Good improvement
    if (pctChange <= -5) return 12; // Moderate improvement
    if (pctChange <= 5) return 10; // Stable
    if (pctChange <= 15) return 5; // Worsening
    return 0; // Significant worsening
  }

  // ============================================================================
  // D. OVERALL SCORE (0-100)
  // ============================================================================

  /// Compute overall Cholesterol Score
  static double computeOverallScore({
    required double labScore,
    required double behaviorScore,
    required double trendScore,
  }) {
    return (labScore + behaviorScore + trendScore).clamp(0, 100);
  }

  // ============================================================================
  // E. GOAL SCORE (personalized target)
  // ============================================================================

  /// Compute Goal Score based on user targets
  static double? computeGoalScore({
    required UserProfile profile,
    required LabResult latestLab,
    required FocusMode mode,
  }) {
    // If no target set, return null
    if (profile.ldlTarget == null && profile.tgTarget == null) {
      return null;
    }

    // Create hypothetical lab result at target
    LabResult targetLab;

    switch (mode) {
      case FocusMode.ldl:
        if (profile.ldlTarget == null) return null;
        targetLab = latestLab.copyWith(ldl: profile.ldlTarget);
        break;

      case FocusMode.triglycerides:
        if (profile.tgTarget == null) return null;
        targetLab = latestLab.copyWith(triglycerides: profile.tgTarget);
        break;

      case FocusMode.both:
        // Use stricter of the two or both
        targetLab = latestLab.copyWith(
          ldl: profile.ldlTarget,
          triglycerides: profile.tgTarget,
        );
        break;
    }

    // Calculate lab score at target
    final labScoreAtGoal = computeLabScore([targetLab], mode);

    // Assume neutral behavior (15) and trend (10) at goal
    const behaviorAtGoal = 15.0;
    const trendAtGoal = 10.0;

    return (labScoreAtGoal + behaviorAtGoal + trendAtGoal).clamp(0, 100);
  }

  // ============================================================================
  // F. COMPLETE SCORE CALCULATION
  // ============================================================================

  /// Main entry point: compute all scores and return ScoreSnapshot
  static ScoreSnapshot computeScores({
    required UserProfile profile,
    required List<LabResult> labs,
    required List<DailyLog> logs,
  }) {
    final now = DateTime.now();

    final sortedLabs = List<LabResult>.from(labs)
      ..sort((a, b) => b.date.compareTo(a.date));

    final sortedLogs = List<DailyLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate component scores
    final labScore = computeLabScore(sortedLabs, profile.focusMode);
    final behaviorScore = computeBehaviorScore(
      sortedLogs,
      profile.focusMode,
      profile.onMedication, // <-- PASS PARAMETER
    );
    final trendScore = computeTrendScore(sortedLabs, profile.focusMode);

    final overall = computeOverallScore(
      labScore: labScore,
      behaviorScore: behaviorScore,
      trendScore: trendScore,
    );

    double? goalScore;
    double? deltaToGoal;

    if (sortedLabs.isNotEmpty) {
      goalScore = computeGoalScore(
        profile: profile,
        latestLab: sortedLabs.first,
        mode: profile.focusMode,
      );

      if (goalScore != null) {
        deltaToGoal = goalScore - overall;
      }
    }

    return ScoreSnapshot(
      id: _uuid.v4(),
      date: now,
      overallScore: overall,
      labScore: labScore,
      behaviorScore: behaviorScore,
      trendScore: trendScore,
      goalScore: goalScore,
      deltaToGoal: deltaToGoal,
    );
  }
}
