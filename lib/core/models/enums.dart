// Core enums for LipidLog

enum FocusMode {
  ldl,
  triglycerides,
  both,
}

enum SleepCategory {
  lessThan6h,
  normal6to8h,
  moreThan8h,
}

enum StressLevel {
  low,
  medium,
  high,
}

enum AlcoholLevel {
  none,
  one,
  twoPlus,
}

// Extensions for display strings
extension FocusModeExtension on FocusMode {
  String get displayName {
    switch (this) {
      case FocusMode.ldl:
        return 'LDL Mode';
      case FocusMode.triglycerides:
        return 'Triglyceride Mode';
      case FocusMode.both:
        return 'Both';
    }
  }
}

extension SleepCategoryExtension on SleepCategory {
  String get displayName {
    switch (this) {
      case SleepCategory.lessThan6h:
        return '<6h';
      case SleepCategory.normal6to8h:
        return '6-8h';
      case SleepCategory.moreThan8h:
        return '>8h';
    }
  }
}

extension StressLevelExtension on StressLevel {
  String get displayName {
    switch (this) {
      case StressLevel.low:
        return 'Low';
      case StressLevel.medium:
        return 'Medium';
      case StressLevel.high:
        return 'High';
    }
  }
}

extension AlcoholLevelExtension on AlcoholLevel {
  String get displayName {
    switch (this) {
      case AlcoholLevel.none:
        return '0 drinks';
      case AlcoholLevel.one:
        return '1 drink';
      case AlcoholLevel.twoPlus:
        return '2+ drinks';
    }
  }
}
