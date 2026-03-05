import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/enums.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/score_service.dart';
import '../../core/services/notification_service.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = StorageService.getUserProfile();

    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: Text('No profile found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          const _SectionHeader(title: 'Profile'),
          _SettingsTile(
            icon: Icons.person,
            title: 'Age',
            subtitle: profile.age?.toString() ?? 'Not set',
            onTap: () => _editAge(context, profile),
          ),
          _SettingsTile(
            icon: Icons.wc,
            title: 'Sex',
            subtitle: profile.sex ?? 'Not set',
            onTap: () => _editSex(context, profile),
          ),

          // Focus Mode Section
          const _SectionHeader(title: 'Tracking'),
          _SettingsTile(
            icon: Icons.track_changes,
            title: 'Focus Mode',
            subtitle: _getFocusModeLabel(profile.focusMode),
            onTap: () => _editFocusMode(context, profile),
          ),
          _SettingsTile(
            icon: Icons.medication,
            title: 'Medication Status',
            subtitle: profile.onMedication
                ? 'Taking cholesterol medication'
                : 'Not on medication',
            onTap: () => _toggleMedication(context, profile),
          ),
          _SettingsTile(
            icon: Icons.schedule,
            title: 'Logging Routine',
            subtitle: profile.prefersMorningLogging
                ? 'Morning catch-up (log yesterday)'
                : 'Evening check-in (log today)',
            onTap: () => _editLoggingRoutine(context, profile),
          ),

          // Targets Section
          const _SectionHeader(title: 'Targets'),
          if (profile.focusMode == FocusMode.ldl ||
              profile.focusMode == FocusMode.both)
            _SettingsTile(
              icon: Icons.flag,
              title: 'LDL Target',
              subtitle: profile.ldlTarget != null
                  ? '${profile.ldlTarget} mg/dL'
                  : 'Not set',
              onTap: () => _editLdlTarget(context, profile),
            ),
          if (profile.focusMode == FocusMode.triglycerides ||
              profile.focusMode == FocusMode.both)
            _SettingsTile(
              icon: Icons.flag,
              title: 'Triglycerides Target',
              subtitle: profile.tgTarget != null
                  ? '${profile.tgTarget} mg/dL'
                  : 'Not set',
              onTap: () => _editTgTarget(context, profile),
            ),
          _SettingsTile(
            icon: Icons.flag_outlined,
            title: 'HDL Target',
            subtitle: profile.hdlTarget != null
                ? '${profile.hdlTarget} mg/dL'
                : 'Not set',
            onTap: () => _editHdlTarget(context, profile),
          ),

          // Reminders Section
          const _SectionHeader(title: 'Reminders'),
          _SettingsTile(
            icon: Icons.alarm,
            title: 'Daily Habit Reminder',
            subtitle: profile.habitReminderEnabled
                ? 'On at ${_formatTime(profile.habitReminderHour, profile.habitReminderMinute)}'
                : 'Off',
            onTap: () => _toggleDailyHabitReminder(context, profile),
          ),
          _SettingsTile(
            icon: Icons.schedule,
            title: 'Habit Reminder Time',
            subtitle: _formatTime(
                profile.habitReminderHour, profile.habitReminderMinute),
            onTap: profile.habitReminderEnabled
                ? () => _setDailyHabitReminderTime(context, profile)
                : null,
          ),
          _SettingsTile(
            icon: Icons.medication,
            title: 'Medication Reminder',
            subtitle: profile.medReminderEnabled
                ? 'On at ${_formatTime(profile.medReminderHour, profile.medReminderMinute)}'
                : 'Off',
            onTap: () => _toggleMedicationReminder(context, profile),
          ),
          _SettingsTile(
            icon: Icons.schedule_send,
            title: 'Medication Reminder Time',
            subtitle:
                _formatTime(profile.medReminderHour, profile.medReminderMinute),
            onTap: (profile.medReminderEnabled && profile.onMedication)
                ? () => _setMedicationReminderTime(context, profile)
                : null,
          ),
          _SettingsTile(
            icon: Icons.event_repeat,
            title: 'Lab Check Reminder',
            subtitle: profile.labReminderEnabled
                ? 'Every ${profile.labReminderMonths} months'
                : 'Off',
            onTap: () => _cycleLabReminder(context, profile),
          ),

          // Data Section
          const _SectionHeader(title: 'Data'),
          _SettingsTile(
            icon: Icons.download,
            title: 'Export Data',
            subtitle: 'Download your data as JSON',
            onTap: () => _exportData(context),
          ),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Clear All Data',
            subtitle: 'Delete all logs, labs, and scores',
            onTap: () => _clearAllData(context),
            isDestructive: true,
          ),

          // App Info Section
          const _SectionHeader(title: 'About'),
          const _SettingsTile(
            icon: Icons.info,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          const _SettingsTile(
            icon: Icons.code,
            title: 'Built by',
            subtitle: 'Ray @ DahVio Studios',
            onTap: null,
          ),
        ],
      ),
    );
  }

  String _getFocusModeLabel(FocusMode mode) {
    switch (mode) {
      case FocusMode.ldl:
        return 'LDL Cholesterol';
      case FocusMode.triglycerides:
        return 'Triglycerides';
      case FocusMode.both:
        return 'Both (Comprehensive)';
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minutePadded = minute.toString().padLeft(2, '0');
    return '$hour12:$minutePadded $period';
  }

  // Edit Age
  void _editAge(BuildContext context, UserProfile profile) {
    final controller = TextEditingController(
      text: profile.age?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Age'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'Enter your age',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final age = int.tryParse(controller.text);
              final updated = profile.copyWith(age: age);
              await StorageService.saveUserProfile(updated);
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Edit Sex
  void _editSex(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Sex'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Male'),
              leading: Radio<String>(
                value: 'male',
                groupValue: profile.sex,
                onChanged: (value) async {
                  final updated = profile.copyWith(sex: value);
                  await StorageService.saveUserProfile(updated);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Female'),
              leading: Radio<String>(
                value: 'female',
                groupValue: profile.sex,
                onChanged: (value) async {
                  final updated = profile.copyWith(sex: value);
                  await StorageService.saveUserProfile(updated);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Other'),
              leading: Radio<String>(
                value: 'other',
                groupValue: profile.sex,
                onChanged: (value) async {
                  final updated = profile.copyWith(sex: value);
                  await StorageService.saveUserProfile(updated);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Edit Focus Mode
  void _editFocusMode(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Focus Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('LDL Cholesterol'),
              leading: Radio<FocusMode>(
                value: FocusMode.ldl,
                groupValue: profile.focusMode,
                onChanged: (value) async {
                  if (value == null) return;
                  final updated = profile.copyWith(focusMode: value);
                  await StorageService.saveUserProfile(updated);
                  await _recalculateScore();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Triglycerides'),
              leading: Radio<FocusMode>(
                value: FocusMode.triglycerides,
                groupValue: profile.focusMode,
                onChanged: (value) async {
                  if (value == null) return;
                  final updated = profile.copyWith(focusMode: value);
                  await StorageService.saveUserProfile(updated);
                  await _recalculateScore();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Both (Comprehensive)'),
              leading: Radio<FocusMode>(
                value: FocusMode.both,
                groupValue: profile.focusMode,
                onChanged: (value) async {
                  if (value == null) return;
                  final updated = profile.copyWith(focusMode: value);
                  await StorageService.saveUserProfile(updated);
                  await _recalculateScore();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editLoggingRoutine(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logging Routine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Evening check-in'),
              subtitle: const Text('Log today in the evening'),
              leading: Radio<bool>(
                value: false,
                groupValue: profile.prefersMorningLogging,
                onChanged: (value) async {
                  if (value == null) return;
                  final updated = profile.copyWith(
                    prefersMorningLogging: value,
                    habitReminderHour: 20,
                    habitReminderMinute: 0,
                  );
                  await StorageService.saveUserProfile(updated);
                  await NotificationService.configureReminders(updated);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Morning catch-up'),
              subtitle: const Text('Log yesterday the next morning'),
              leading: Radio<bool>(
                value: true,
                groupValue: profile.prefersMorningLogging,
                onChanged: (value) async {
                  if (value == null) return;
                  final updated = profile.copyWith(
                    prefersMorningLogging: value,
                    habitReminderHour: 8,
                    habitReminderMinute: 0,
                  );
                  await StorageService.saveUserProfile(updated);
                  await NotificationService.configureReminders(updated);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle Medication
  void _toggleMedication(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medication Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Taking medication'),
              subtitle:
                  const Text('Statins, fibrates, or other cholesterol meds'),
              leading: Radio<bool>(
                value: true,
                groupValue: profile.onMedication,
                onChanged: (value) async {
                  if (value == null) return;
                  final updated = profile.copyWith(onMedication: value);
                  await StorageService.saveUserProfile(updated);
                  await NotificationService.configureReminders(updated);
                  await _recalculateScore();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Not on medication'),
              subtitle: const Text('Trying lifestyle changes first'),
              leading: Radio<bool>(
                value: false,
                groupValue: profile.onMedication,
                onChanged: (value) async {
                  if (value == null) return;
                  final updated = profile.copyWith(onMedication: value);
                  await StorageService.saveUserProfile(updated);
                  await NotificationService.configureReminders(updated);
                  await _recalculateScore();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleDailyHabitReminder(
      BuildContext context, UserProfile profile) async {
    UserProfile updated;
    if (profile.habitReminderEnabled) {
      updated = profile.copyWith(habitReminderEnabled: false);
    } else {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: profile.habitReminderHour,
          minute: profile.habitReminderMinute,
        ),
      );
      if (selectedTime == null) return;
      updated = profile.copyWith(
        habitReminderEnabled: true,
        habitReminderHour: selectedTime.hour,
        habitReminderMinute: selectedTime.minute,
      );
    }

    await StorageService.saveUserProfile(updated);
    await NotificationService.configureReminders(updated);
    if (!context.mounted) return;
    setState(() {});
  }

  Future<void> _setDailyHabitReminderTime(
      BuildContext context, UserProfile profile) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: profile.habitReminderHour,
        minute: profile.habitReminderMinute,
      ),
    );
    if (selectedTime == null) return;

    final updated = profile.copyWith(
      habitReminderHour: selectedTime.hour,
      habitReminderMinute: selectedTime.minute,
    );

    await StorageService.saveUserProfile(updated);
    await NotificationService.configureReminders(updated);
    if (!context.mounted) return;
    setState(() {});
  }

  Future<void> _toggleMedicationReminder(
      BuildContext context, UserProfile profile) async {
    if (!profile.onMedication && !profile.medReminderEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable medication status first to use this reminder.'),
        ),
      );
      return;
    }

    UserProfile updated;
    if (profile.medReminderEnabled) {
      updated = profile.copyWith(medReminderEnabled: false);
    } else {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: profile.medReminderHour,
          minute: profile.medReminderMinute,
        ),
      );
      if (selectedTime == null) return;
      updated = profile.copyWith(
        medReminderEnabled: true,
        medReminderHour: selectedTime.hour,
        medReminderMinute: selectedTime.minute,
      );
    }

    await StorageService.saveUserProfile(updated);
    await NotificationService.configureReminders(updated);
    if (!context.mounted) return;
    setState(() {});
  }

  Future<void> _setMedicationReminderTime(
      BuildContext context, UserProfile profile) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: profile.medReminderHour,
        minute: profile.medReminderMinute,
      ),
    );
    if (selectedTime == null) return;

    final updated = profile.copyWith(
      medReminderHour: selectedTime.hour,
      medReminderMinute: selectedTime.minute,
    );

    await StorageService.saveUserProfile(updated);
    await NotificationService.configureReminders(updated);
    if (!context.mounted) return;
    setState(() {});
  }

  Future<void> _cycleLabReminder(
      BuildContext context, UserProfile profile) async {
    final updated =
        switch ((profile.labReminderEnabled, profile.labReminderMonths)) {
      (false, _) =>
        profile.copyWith(labReminderEnabled: true, labReminderMonths: 3),
      (true, 3) =>
        profile.copyWith(labReminderEnabled: true, labReminderMonths: 6),
      (true, 6) =>
        profile.copyWith(labReminderEnabled: true, labReminderMonths: 12),
      _ => profile.copyWith(labReminderEnabled: false),
    };

    await StorageService.saveUserProfile(updated);
    await NotificationService.configureReminders(updated);
    if (!context.mounted) return;
    setState(() {});
  }

  // Edit LDL Target
  void _editLdlTarget(BuildContext context, UserProfile profile) {
    final controller = TextEditingController(
      text: profile.ldlTarget?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit LDL Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'LDL Target (mg/dL)',
            hintText: 'e.g., 100',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final target = double.tryParse(controller.text);
              final updated = profile.copyWith(ldlTarget: target);
              await StorageService.saveUserProfile(updated);
              await _recalculateScore();
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Edit HDL Target
  void _editHdlTarget(BuildContext context, UserProfile profile) {
    final controller = TextEditingController(
      text: profile.hdlTarget?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HDL Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'HDL Target (mg/dL)',
            hintText: 'e.g., 60',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final target = double.tryParse(controller.text);
              final updated = profile.copyWith(hdlTarget: target);
              await StorageService.saveUserProfile(updated);
              await _recalculateScore();
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Edit TG Target
  void _editTgTarget(BuildContext context, UserProfile profile) {
    final controller = TextEditingController(
      text: profile.tgTarget?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Triglycerides Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Triglycerides Target (mg/dL)',
            hintText: 'e.g., 150',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final target = double.tryParse(controller.text);
              final updated = profile.copyWith(tgTarget: target);
              await StorageService.saveUserProfile(updated);
              await _recalculateScore();
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Export Data
  void _exportData(BuildContext context) {
    final profile = StorageService.getUserProfile();
    final labs = StorageService.getAllLabResults();
    final logs = StorageService.getAllDailyLogs();
    final scores = StorageService.getAllScoreSnapshots();

    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'counts': {
        'labs': labs.length,
        'dailyLogs': logs.length,
        'scoreSnapshots': scores.length,
      },
      'labs': labs.map((item) => item.toJson()).toList(),
      'dailyLogs': logs.map((item) => item.toJson()).toList(),
      'scoreSnapshots': scores.map((item) => item.toJson()).toList(),
    };

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    final csvText = _buildCsvExport();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Text(
          'Ready to export:\n'
          '${labs.length} labs, ${logs.length} daily logs, ${scores.length} score snapshots.\n\n'
          'Choose JSON or CSV and copy it to your clipboard.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonText));
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard')),
              );
            },
            child: const Text('Copy JSON'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csvText));
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard')),
              );
            },
            child: const Text('Copy CSV'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _buildCsvExport() {
    final profile = StorageService.getUserProfile();
    final labs = StorageService.getAllLabResults();
    final logs = StorageService.getAllDailyLogs();
    final scores = StorageService.getAllScoreSnapshots();

    final buffer = StringBuffer();
    buffer.writeln('SECTION,FIELD,VALUE');
    if (profile != null) {
      buffer.writeln('profile,id,${_csv(profile.id)}');
      buffer.writeln('profile,age,${profile.age ?? ''}');
      buffer.writeln('profile,sex,${_csv(profile.sex ?? '')}');
      buffer.writeln('profile,focusMode,${profile.focusMode.name}');
      buffer.writeln('profile,ldlTarget,${profile.ldlTarget ?? ''}');
      buffer.writeln('profile,tgTarget,${profile.tgTarget ?? ''}');
      buffer.writeln('profile,onMedication,${profile.onMedication}');
    }

    buffer.writeln();
    buffer.writeln(
        'labs,id,date,ldl,hdl,triglycerides,totalCholesterol,nonHdl,isFasting,notes');
    for (final lab in labs) {
      buffer.writeln([
        'labs',
        _csv(lab.id),
        lab.date.toIso8601String(),
        lab.ldl ?? '',
        lab.hdl ?? '',
        lab.triglycerides ?? '',
        lab.totalCholesterol ?? '',
        lab.nonHdl ?? '',
        lab.isFasting,
        _csv(lab.notes ?? ''),
      ].join(','));
    }

    buffer.writeln();
    buffer.writeln(
        'daily_logs,id,date,alcoholLevel,stepsGoalHit,lateNightEating,highCarbDay,highSatFatDay,sleepCategory,medicationTaken,stressLevel,notes');
    for (final log in logs) {
      buffer.writeln([
        'daily_logs',
        _csv(log.id),
        log.date.toIso8601String(),
        log.alcoholLevel.name,
        log.stepsGoalHit,
        log.lateNightEating,
        log.highCarbDay,
        log.highSatFatDay,
        log.sleepCategory.name,
        log.medicationTaken,
        log.stressLevel.name,
        _csv(log.notes ?? ''),
      ].join(','));
    }

    buffer.writeln();
    buffer.writeln(
        'scores,id,date,overallScore,labScore,behaviorScore,trendScore,goalScore,deltaToGoal');
    for (final score in scores) {
      buffer.writeln([
        'scores',
        _csv(score.id),
        score.date.toIso8601String(),
        score.overallScore,
        score.labScore,
        score.behaviorScore,
        score.trendScore,
        score.goalScore ?? '',
        score.deltaToGoal ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  // Clear All Data
  void _clearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your labs, daily logs, scores, and profile. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await NotificationService.cancelAll();
              await StorageService.clearAll();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(),
                ),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  // Recalculate score after settings change
  Future<void> _recalculateScore() async {
    final profile = StorageService.getUserProfile();
    if (profile == null) return;

    final labs = StorageService.getAllLabResults();
    final logs = StorageService.getAllDailyLogs();

    final newScore = ScoreService.computeScores(
      profile: profile,
      labs: labs,
      logs: logs,
    );

    await StorageService.saveScoreSnapshot(newScore);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
