import 'package:hive/hive.dart';
import 'enums.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int? age;

  @HiveField(2)
  String? sex;

  @HiveField(3)
  FocusMode focusMode;

  @HiveField(4)
  double? ldlTarget;

  @HiveField(5)
  double? tgTarget;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool onMedication;

  @HiveField(9)
  bool habitReminderEnabled;

  @HiveField(10)
  int habitReminderHour;

  @HiveField(11)
  int habitReminderMinute;

  @HiveField(12)
  bool medReminderEnabled;

  @HiveField(13)
  int medReminderHour;

  @HiveField(14)
  int medReminderMinute;

  @HiveField(15)
  bool labReminderEnabled;

  @HiveField(16)
  int labReminderMonths;

  @HiveField(17)
  bool prefersMorningLogging;

  @HiveField(18)
  double? hdlTarget;

  UserProfile({
    required this.id,
    this.age,
    this.sex,
    this.focusMode = FocusMode.both,
    this.ldlTarget,
    this.tgTarget,
    this.hdlTarget,
    this.onMedication = false,
    this.habitReminderEnabled = false,
    this.habitReminderHour = 20,
    this.habitReminderMinute = 0,
    this.medReminderEnabled = false,
    this.medReminderHour = 9,
    this.medReminderMinute = 0,
    this.labReminderEnabled = false,
    this.labReminderMonths = 3,
    this.prefersMorningLogging = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    String? id,
    int? age,
    String? sex,
    FocusMode? focusMode,
    double? ldlTarget,
    double? tgTarget,
    double? hdlTarget,
    bool? onMedication,
    bool? habitReminderEnabled,
    int? habitReminderHour,
    int? habitReminderMinute,
    bool? medReminderEnabled,
    int? medReminderHour,
    int? medReminderMinute,
    bool? labReminderEnabled,
    int? labReminderMonths,
    bool? prefersMorningLogging,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      focusMode: focusMode ?? this.focusMode,
      ldlTarget: ldlTarget ?? this.ldlTarget,
      tgTarget: tgTarget ?? this.tgTarget,
      hdlTarget: hdlTarget ?? this.hdlTarget,
      onMedication: onMedication ?? this.onMedication,
      habitReminderEnabled: habitReminderEnabled ?? this.habitReminderEnabled,
      habitReminderHour: habitReminderHour ?? this.habitReminderHour,
      habitReminderMinute: habitReminderMinute ?? this.habitReminderMinute,
      medReminderEnabled: medReminderEnabled ?? this.medReminderEnabled,
      medReminderHour: medReminderHour ?? this.medReminderHour,
      medReminderMinute: medReminderMinute ?? this.medReminderMinute,
      labReminderEnabled: labReminderEnabled ?? this.labReminderEnabled,
      labReminderMonths: labReminderMonths ?? this.labReminderMonths,
      prefersMorningLogging:
          prefersMorningLogging ?? this.prefersMorningLogging,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'age': age,
      'sex': sex,
      'focusMode': focusMode.name,
      'ldlTarget': ldlTarget,
      'tgTarget': tgTarget,
      'hdlTarget': hdlTarget,
      'onMedication': onMedication,
      'habitReminderEnabled': habitReminderEnabled,
      'habitReminderHour': habitReminderHour,
      'habitReminderMinute': habitReminderMinute,
      'medReminderEnabled': medReminderEnabled,
      'medReminderHour': medReminderHour,
      'medReminderMinute': medReminderMinute,
      'labReminderEnabled': labReminderEnabled,
      'labReminderMonths': labReminderMonths,
      'prefersMorningLogging': prefersMorningLogging,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      age: json['age'] as int?,
      sex: json['sex'] as String?,
      focusMode: FocusMode.values.firstWhere(
        (e) => e.name == json['focusMode'],
        orElse: () => FocusMode.both,
      ),
      ldlTarget: json['ldlTarget'] as double?,
      tgTarget: json['tgTarget'] as double?,
      hdlTarget: json['hdlTarget'] as double?,
      onMedication: json['onMedication'] as bool? ?? false,
      habitReminderEnabled: json['habitReminderEnabled'] as bool? ?? false,
      habitReminderHour: json['habitReminderHour'] as int? ?? 20,
      habitReminderMinute: json['habitReminderMinute'] as int? ?? 0,
      medReminderEnabled: json['medReminderEnabled'] as bool? ?? false,
      medReminderHour: json['medReminderHour'] as int? ?? 9,
      medReminderMinute: json['medReminderMinute'] as int? ?? 0,
      labReminderEnabled: json['labReminderEnabled'] as bool? ?? false,
      labReminderMonths: json['labReminderMonths'] as int? ?? 3,
      prefersMorningLogging: json['prefersMorningLogging'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
