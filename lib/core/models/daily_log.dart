import 'package:hive/hive.dart';
import 'enums.dart';

part 'daily_log.g.dart';

@HiveType(typeId: 2)
class DailyLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  AlcoholLevel alcoholLevel;

  @HiveField(3)
  bool stepsGoalHit;

  @HiveField(4)
  bool lateNightEating;

  @HiveField(5)
  bool highCarbDay;

  @HiveField(6)
  bool highSatFatDay;

  @HiveField(7)
  SleepCategory sleepCategory;

  @HiveField(8)
  bool medicationTaken;

  @HiveField(9)
  StressLevel stressLevel;

  @HiveField(10)
  String? notes;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  DailyLog({
    required this.id,
    required this.date,
    this.alcoholLevel = AlcoholLevel.none,
    this.stepsGoalHit = false,
    this.lateNightEating = false,
    this.highCarbDay = false,
    this.highSatFatDay = false,
    this.sleepCategory = SleepCategory.normal6to8h,
    this.medicationTaken = false,
    this.stressLevel = StressLevel.medium,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DailyLog copyWith({
    String? id,
    DateTime? date,
    AlcoholLevel? alcoholLevel,
    bool? stepsGoalHit,
    bool? lateNightEating,
    bool? highCarbDay,
    bool? highSatFatDay,
    SleepCategory? sleepCategory,
    bool? medicationTaken,
    StressLevel? stressLevel,
    String? notes,
  }) {
    return DailyLog(
      id: id ?? this.id,
      date: date ?? this.date,
      alcoholLevel: alcoholLevel ?? this.alcoholLevel,
      stepsGoalHit: stepsGoalHit ?? this.stepsGoalHit,
      lateNightEating: lateNightEating ?? this.lateNightEating,
      highCarbDay: highCarbDay ?? this.highCarbDay,
      highSatFatDay: highSatFatDay ?? this.highSatFatDay,
      sleepCategory: sleepCategory ?? this.sleepCategory,
      medicationTaken: medicationTaken ?? this.medicationTaken,
      stressLevel: stressLevel ?? this.stressLevel,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'alcoholLevel': alcoholLevel.name,
      'stepsGoalHit': stepsGoalHit,
      'lateNightEating': lateNightEating,
      'highCarbDay': highCarbDay,
      'highSatFatDay': highSatFatDay,
      'sleepCategory': sleepCategory.name,
      'medicationTaken': medicationTaken,
      'stressLevel': stressLevel.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      alcoholLevel: AlcoholLevel.values.firstWhere(
        (e) => e.name == json['alcoholLevel'],
        orElse: () => AlcoholLevel.none,
      ),
      stepsGoalHit: json['stepsGoalHit'] as bool? ?? false,
      lateNightEating: json['lateNightEating'] as bool? ?? false,
      highCarbDay: json['highCarbDay'] as bool? ?? false,
      highSatFatDay: json['highSatFatDay'] as bool? ?? false,
      sleepCategory: SleepCategory.values.firstWhere(
        (e) => e.name == json['sleepCategory'],
        orElse: () => SleepCategory.normal6to8h,
      ),
      medicationTaken: json['medicationTaken'] as bool? ?? false,
      stressLevel: StressLevel.values.firstWhere(
        (e) => e.name == json['stressLevel'],
        orElse: () => StressLevel.medium,
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
