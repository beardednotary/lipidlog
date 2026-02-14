import 'package:flutter/material.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/enums.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/score_service.dart';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Data export will be available in a future update. This will allow you to download your labs, habits, and scores as JSON or CSV.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
