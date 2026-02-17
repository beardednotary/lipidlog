import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/lab_result.dart';
import '../models/daily_log.dart';
import '../models/score_snapshot.dart';
import '../models/enums.dart';

/// Storage service using Hive for local data persistence
class StorageService {
  static const String userProfileBox = 'user_profile';
  static const String labResultsBox = 'lab_results';
  static const String dailyLogsBox = 'daily_logs';
  static const String scoreSnapshotsBox = 'score_snapshots';

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register enum adapters
    _registerAdapterIfNeeded<FocusMode>(FocusModeAdapter());
    _registerAdapterIfNeeded<AlcoholLevel>(AlcoholLevelAdapter());
    _registerAdapterIfNeeded<SleepCategory>(SleepCategoryAdapter());
    _registerAdapterIfNeeded<StressLevel>(StressLevelAdapter());

    // Register model adapters
    _registerAdapterIfNeeded<UserProfile>(UserProfileAdapter());
    _registerAdapterIfNeeded<LabResult>(LabResultAdapter());
    _registerAdapterIfNeeded<DailyLog>(DailyLogAdapter());
    _registerAdapterIfNeeded<ScoreSnapshot>(ScoreSnapshotAdapter());

    // Open boxes
    await Hive.openBox<UserProfile>(userProfileBox);
    await Hive.openBox<LabResult>(labResultsBox);
    await Hive.openBox<DailyLog>(dailyLogsBox);
    await Hive.openBox<ScoreSnapshot>(scoreSnapshotsBox);
  }

  static void _registerAdapterIfNeeded<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  // ==========================================================================
  // USER PROFILE
  // ==========================================================================

  static Box<UserProfile> get _userBox => Hive.box<UserProfile>(userProfileBox);

  static UserProfile? getUserProfile() {
    if (_userBox.isEmpty) return null;
    return _userBox.values.first;
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    await _userBox.clear();
    await _userBox.add(profile);
  }

  static Future<void> updateUserProfile(UserProfile profile) async {
    await saveUserProfile(profile);
  }

  // ==========================================================================
  // LAB RESULTS
  // ==========================================================================

  static Box<LabResult> get _labBox => Hive.box<LabResult>(labResultsBox);

  static List<LabResult> getAllLabResults() {
    return _labBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  static LabResult? getLatestLabResult() {
    final labs = getAllLabResults();
    return labs.isEmpty ? null : labs.first;
  }

  static Future<void> saveLabResult(LabResult lab) async {
    await _labBox.add(lab);
  }

  static Future<void> updateLabResult(int index, LabResult lab) async {
    await _labBox.putAt(index, lab);
  }

  static Future<void> deleteLabResult(int index) async {
    await _labBox.deleteAt(index);
  }

  // ==========================================================================
  // DAILY LOGS
  // ==========================================================================

  static Box<DailyLog> get _logBox => Hive.box<DailyLog>(dailyLogsBox);

  static List<DailyLog> getAllDailyLogs() {
    return _logBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  static DailyLog? getLogForDate(DateTime date) {
    final normalized = DailyLog.normalizeDate(date);
    try {
      return _logBox.values.firstWhere(
        (log) => DailyLog.normalizeDate(log.date).isAtSameMomentAs(normalized),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveDailyLog(DailyLog log) async {
    // Check if log for this date already exists
    final existing = getLogForDate(log.date);
    if (existing != null) {
      // Update existing
      final index = _logBox.values.toList().indexOf(existing);
      await _logBox.putAt(index, log);
    } else {
      // Create new
      await _logBox.add(log);
    }
  }

  static Future<void> deleteDailyLog(int index) async {
    await _logBox.deleteAt(index);
  }

  // ==========================================================================
  // SCORE SNAPSHOTS
  // ==========================================================================

  static Box<ScoreSnapshot> get _scoreBox =>
      Hive.box<ScoreSnapshot>(scoreSnapshotsBox);

  static List<ScoreSnapshot> getAllScoreSnapshots() {
    return _scoreBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  static ScoreSnapshot? getLatestScore() {
    final scores = getAllScoreSnapshots();
    return scores.isEmpty ? null : scores.first;
  }

  static Future<void> saveScoreSnapshot(ScoreSnapshot snapshot) async {
    await _scoreBox.add(snapshot);
  }

  // ==========================================================================
  // CLEANUP
  // ==========================================================================

  static Future<void> clearAll() async {
    await _userBox.clear();
    await _labBox.clear();
    await _logBox.clear();
    await _scoreBox.clear();
  }

  static Future<void> close() async {
    await Hive.close();
  }
}

// Enum adapters (manually added since build_runner doesn't generate these)
class FocusModeAdapter extends TypeAdapter<FocusMode> {
  @override
  final int typeId = 10;

  @override
  FocusMode read(BinaryReader reader) {
    return FocusMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, FocusMode obj) {
    writer.writeByte(obj.index);
  }
}

class AlcoholLevelAdapter extends TypeAdapter<AlcoholLevel> {
  @override
  final int typeId = 11;

  @override
  AlcoholLevel read(BinaryReader reader) {
    return AlcoholLevel.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AlcoholLevel obj) {
    writer.writeByte(obj.index);
  }
}

class SleepCategoryAdapter extends TypeAdapter<SleepCategory> {
  @override
  final int typeId = 12;

  @override
  SleepCategory read(BinaryReader reader) {
    return SleepCategory.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, SleepCategory obj) {
    writer.writeByte(obj.index);
  }
}

class StressLevelAdapter extends TypeAdapter<StressLevel> {
  @override
  final int typeId = 13;

  @override
  StressLevel read(BinaryReader reader) {
    return StressLevel.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, StressLevel obj) {
    writer.writeByte(obj.index);
  }
}
