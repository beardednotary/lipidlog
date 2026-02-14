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

  UserProfile({
    required this.id,
    this.age,
    this.sex,
    this.focusMode = FocusMode.both,
    this.ldlTarget,
    this.tgTarget,
    this.onMedication = false,
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
    bool? onMedication,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      focusMode: focusMode ?? this.focusMode,
      ldlTarget: ldlTarget ?? this.ldlTarget,
      tgTarget: tgTarget ?? this.tgTarget,
      onMedication: onMedication ?? this.onMedication,
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
      'onMedication': onMedication,
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
      onMedication: json['onMedication'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
