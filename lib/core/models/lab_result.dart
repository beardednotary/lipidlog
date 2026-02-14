import 'package:hive/hive.dart';

part 'lab_result.g.dart';

@HiveType(typeId: 1)
class LabResult extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double? ldl;

  @HiveField(3)
  double? hdl;

  @HiveField(4)
  double? triglycerides;

  @HiveField(5)
  double? totalCholesterol;

  @HiveField(6)
  double? nonHdl;

  @HiveField(7)
  bool isFasting;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  DateTime createdAt;

  LabResult({
    required this.id,
    required this.date,
    this.ldl,
    this.hdl,
    this.triglycerides,
    this.totalCholesterol,
    this.nonHdl,
    this.isFasting = false,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double? get calculatedNonHdl {
    if (totalCholesterol != null && hdl != null) {
      return totalCholesterol! - hdl!;
    }
    return nonHdl;
  }

  double? get totalHdlRatio {
    if (totalCholesterol != null && hdl != null && hdl! > 0) {
      return totalCholesterol! / hdl!;
    }
    return null;
  }

  bool get hasMinimumData {
    return ldl != null || triglycerides != null;
  }

  LabResult copyWith({
    String? id,
    DateTime? date,
    double? ldl,
    double? hdl,
    double? triglycerides,
    double? totalCholesterol,
    double? nonHdl,
    bool? isFasting,
    String? notes,
  }) {
    return LabResult(
      id: id ?? this.id,
      date: date ?? this.date,
      ldl: ldl ?? this.ldl,
      hdl: hdl ?? this.hdl,
      triglycerides: triglycerides ?? this.triglycerides,
      totalCholesterol: totalCholesterol ?? this.totalCholesterol,
      nonHdl: nonHdl ?? this.nonHdl,
      isFasting: isFasting ?? this.isFasting,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'ldl': ldl,
      'hdl': hdl,
      'triglycerides': triglycerides,
      'totalCholesterol': totalCholesterol,
      'nonHdl': nonHdl,
      'isFasting': isFasting,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      ldl: json['ldl'] as double?,
      hdl: json['hdl'] as double?,
      triglycerides: json['triglycerides'] as double?,
      totalCholesterol: json['totalCholesterol'] as double?,
      nonHdl: json['nonHdl'] as double?,
      isFasting: json['isFasting'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
