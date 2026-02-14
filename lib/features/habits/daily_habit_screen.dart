import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/daily_log.dart';
import '../../core/models/enums.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/score_service.dart';

class DailyHabitScreen extends StatefulWidget {
  const DailyHabitScreen({super.key});

  @override
  State<DailyHabitScreen> createState() => _DailyHabitScreenState();
}

class _DailyHabitScreenState extends State<DailyHabitScreen> {
  final _uuid = const Uuid();
  late DailyLog _log;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTodayLog();
  }

  void _loadTodayLog() {
    final today = DailyLog.normalizeDate(DateTime.now());
    final existing = StorageService.getLogForDate(today);

    if (existing != null) {
      _log = existing;
    } else {
      _log = DailyLog(
        id: _uuid.v4(),
        date: today,
      );
    }
  }

  Future<void> _saveLog() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await StorageService.saveDailyLog(_log);

      // Recalculate score
      final profile = StorageService.getUserProfile()!;
      final labs = StorageService.getAllLabResults();
      final logs = StorageService.getAllDailyLogs();
      final newScore = ScoreService.computeScores(
        profile: profile,
        labs: labs,
        logs: logs,
      );
      await StorageService.saveScoreSnapshot(newScore);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Habits saved! Score: ${newScore.overallScore.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = StorageService.getUserProfile();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Habits'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateTime.now().toString().split(' ')[0],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your daily behaviors to improve your score',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Medication
            if (profile?.onMedication ?? false)
              _HabitCard(
                title: 'Medication',
                subtitle: 'Did you take your cholesterol medication today?',
                icon: Icons.medication,
                child: Row(
                  children: [
                    _ChoiceChip(
                      label: 'Yes',
                      isSelected: _log.medicationTaken,
                      onTap: () {
                        setState(() {
                          _log = _log.copyWith(medicationTaken: true);
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _ChoiceChip(
                      label: 'No',
                      isSelected: !_log.medicationTaken,
                      onTap: () {
                        setState(() {
                          _log = _log.copyWith(medicationTaken: false);
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.medication,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medication',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Not currently on cholesterol medication',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'N/A',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Steps
            _HabitCard(
              title: 'Steps Goal',
              subtitle: 'Did you hit your daily step goal?',
              icon: Icons.directions_walk,
              child: Row(
                children: [
                  _ChoiceChip(
                    label: 'Yes',
                    isSelected: _log.stepsGoalHit,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(stepsGoalHit: true);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: 'No',
                    isSelected: !_log.stepsGoalHit,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(stepsGoalHit: false);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alcohol
            _HabitCard(
              title: 'Alcohol',
              subtitle: 'How many drinks today?',
              icon: Icons.local_bar,
              child: Row(
                children: [
                  _ChoiceChip(
                    label: '0',
                    isSelected: _log.alcoholLevel == AlcoholLevel.none,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(alcoholLevel: AlcoholLevel.none);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: '1',
                    isSelected: _log.alcoholLevel == AlcoholLevel.one,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(alcoholLevel: AlcoholLevel.one);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: '2+',
                    isSelected: _log.alcoholLevel == AlcoholLevel.twoPlus,
                    onTap: () {
                      setState(() {
                        _log =
                            _log.copyWith(alcoholLevel: AlcoholLevel.twoPlus);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sleep
            _HabitCard(
              title: 'Sleep',
              subtitle: 'How much sleep last night?',
              icon: Icons.bedtime,
              child: Row(
                children: [
                  _ChoiceChip(
                    label: '<6h',
                    isSelected: _log.sleepCategory == SleepCategory.lessThan6h,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(
                            sleepCategory: SleepCategory.lessThan6h);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: '6-8h',
                    isSelected: _log.sleepCategory == SleepCategory.normal6to8h,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(
                            sleepCategory: SleepCategory.normal6to8h);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: '>8h',
                    isSelected: _log.sleepCategory == SleepCategory.moreThan8h,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(
                            sleepCategory: SleepCategory.moreThan8h);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Diet flags
            _HabitCard(
              title: 'Diet',
              subtitle: 'Check what applies today',
              icon: Icons.restaurant,
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Late-night eating'),
                    subtitle: const Text('Ate within 2 hours of bed'),
                    value: _log.lateNightEating,
                    onChanged: (value) {
                      setState(() {
                        _log = _log.copyWith(lateNightEating: value ?? false);
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('High-carb day'),
                    subtitle: const Text('Lots of bread, pasta, sugar'),
                    value: _log.highCarbDay,
                    onChanged: (value) {
                      setState(() {
                        _log = _log.copyWith(highCarbDay: value ?? false);
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('High saturated fat'),
                    subtitle: const Text('Butter, cheese, red meat'),
                    value: _log.highSatFatDay,
                    onChanged: (value) {
                      setState(() {
                        _log = _log.copyWith(highSatFatDay: value ?? false);
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stress
            _HabitCard(
              title: 'Stress Level',
              subtitle: 'How stressed were you today?',
              icon: Icons.psychology,
              child: Row(
                children: [
                  _ChoiceChip(
                    label: 'Low',
                    isSelected: _log.stressLevel == StressLevel.low,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(stressLevel: StressLevel.low);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: 'Medium',
                    isSelected: _log.stressLevel == StressLevel.medium,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(stressLevel: StressLevel.medium);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChoiceChip(
                    label: 'High',
                    isSelected: _log.stressLevel == StressLevel.high,
                    onTap: () {
                      setState(() {
                        _log = _log.copyWith(stressLevel: StressLevel.high);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLog,
                child: const Text('Save Today\'s Habits'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _HabitCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
