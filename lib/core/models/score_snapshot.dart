import 'package:hive/hive.dart';

part 'score_snapshot.g.dart';

@HiveType(typeId: 3)
class ScoreSnapshot extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double overallScore;

  @HiveField(3)
  double labScore;

  @HiveField(4)
  double behaviorScore;

  @HiveField(5)
  double trendScore;

  @HiveField(6)
  double? goalScore;

  @HiveField(7)
  double? deltaToGoal;

  @HiveField(8)
  DateTime createdAt;

  ScoreSnapshot({
    required this.id,
    required this.date,
    required this.overallScore,
    required this.labScore,
    required this.behaviorScore,
    required this.trendScore,
    this.goalScore,
    this.deltaToGoal,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasGoal => goalScore != null;

  String get scoreGrade {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Great';
    if (overallScore >= 70) return 'Good';
    if (overallScore >= 60) return 'Fair';
    return 'Needs Improvement';
  }

  String get deltaDescription {
    if (deltaToGoal == null || goalScore == null) {
      return '';
    }
    if (deltaToGoal! <= 0) {
      return 'Goal achieved! 🎉';
    }
    return '${deltaToGoal!.toStringAsFixed(0)} points to goal';
  }

  ScoreSnapshot copyWith({
    String? id,
    DateTime? date,
    double? overallScore,
    double? labScore,
    double? behaviorScore,
    double? trendScore,
    double? goalScore,
    double? deltaToGoal,
  }) {
    return ScoreSnapshot(
      id: id ?? this.id,
      date: date ?? this.date,
      overallScore: overallScore ?? this.overallScore,
      labScore: labScore ?? this.labScore,
      behaviorScore: behaviorScore ?? this.behaviorScore,
      trendScore: trendScore ?? this.trendScore,
      goalScore: goalScore ?? this.goalScore,
      deltaToGoal: deltaToGoal ?? this.deltaToGoal,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'overallScore': overallScore,
      'labScore': labScore,
      'behaviorScore': behaviorScore,
      'trendScore': trendScore,
      'goalScore': goalScore,
      'deltaToGoal': deltaToGoal,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return ScoreSnapshot(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      overallScore: (json['overallScore'] as num).toDouble(),
      labScore: (json['labScore'] as num).toDouble(),
      behaviorScore: (json['behaviorScore'] as num).toDouble(),
      trendScore: (json['trendScore'] as num).toDouble(),
      goalScore: json['goalScore'] != null
          ? (json['goalScore'] as num).toDouble()
          : null,
      deltaToGoal: json['deltaToGoal'] != null
          ? (json['deltaToGoal'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
