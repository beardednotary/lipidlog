import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/enums.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/notification_service.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  FocusMode _selectedMode = FocusMode.both;
  int? _age;
  String? _sex;
  double? _ldlTarget;
  double? _tgTarget;
  bool _onMedication = false;
  bool _prefersMorningLogging = false;
  bool _enableHabitReminder = true;

  static const _uuid = Uuid();

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeOnboarding() async {
    final profile = UserProfile(
      id: _uuid.v4(),
      age: _age,
      sex: _sex,
      focusMode: _selectedMode,
      ldlTarget: _ldlTarget,
      tgTarget: _tgTarget,
      onMedication: _onMedication,
      habitReminderEnabled: _enableHabitReminder,
      habitReminderHour: _prefersMorningLogging ? 8 : 20,
      habitReminderMinute: 0,
      prefersMorningLogging: _prefersMorningLogging,
    );

    await StorageService.saveUserProfile(profile);
    await NotificationService.configureReminders(profile);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to LipidLog'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
              ),
              const SizedBox(height: 32),

              // Content
              Expanded(
                child: _buildStepContent(),
              ),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextStep : null,
                  child: Text(
                    _currentStep == 4 ? 'Get Started' : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildFocusModeStep();
      case 1:
        return _buildProfileStep();
      case 2:
        return _buildMedicationStep();
      case 3:
        return _buildLoggingRoutineStep();
      case 4:
        return _buildTargetsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFocusModeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Focus',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'What are you tracking?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        _FocusModeCard(
          mode: FocusMode.ldl,
          title: 'LDL Cholesterol',
          description: 'Track and lower your LDL ("bad" cholesterol)',
          isSelected: _selectedMode == FocusMode.ldl,
          onTap: () => setState(() => _selectedMode = FocusMode.ldl),
        ),
        const SizedBox(height: 16),
        _FocusModeCard(
          mode: FocusMode.triglycerides,
          title: 'Triglycerides',
          description: 'Manage and reduce triglyceride levels',
          isSelected: _selectedMode == FocusMode.triglycerides,
          onTap: () => setState(() => _selectedMode = FocusMode.triglycerides),
        ),
        const SizedBox(height: 16),
        _FocusModeCard(
          mode: FocusMode.both,
          title: 'Both',
          description: 'Comprehensive lipid health tracking',
          isSelected: _selectedMode == FocusMode.both,
          onTap: () => setState(() => _selectedMode = FocusMode.both),
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About You',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Help us personalize your experience (optional)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'Enter your age',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() => _age = int.tryParse(value));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Sex',
          ),
          value: _sex,
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) {
            setState(() => _sex = value);
          },
        ),
      ],
    );
  }

  Widget _buildMedicationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Medication',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Are you currently taking cholesterol medication?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        _FocusModeCard(
          mode: FocusMode.ldl, // Reusing enum just for UI
          title: 'Yes, I\'m on medication',
          description: 'Statins, fibrates, or other cholesterol meds',
          isSelected: _onMedication,
          onTap: () => setState(() => _onMedication = true),
        ),
        const SizedBox(height: 16),
        _FocusModeCard(
          mode: FocusMode.triglycerides, // Reusing enum just for UI
          title: 'No, not on medication yet',
          description: 'Trying lifestyle changes first',
          isSelected: !_onMedication,
          onTap: () => setState(() => _onMedication = false),
        ),
      ],
    );
  }

  Widget _buildTargetsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Your Targets',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'What are your doctor\'s recommended levels? (optional)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        if (_selectedMode == FocusMode.ldl || _selectedMode == FocusMode.both)
          Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'LDL Target (mg/dL)',
                  hintText: 'e.g., 100',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() => _ldlTarget = double.tryParse(value));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        if (_selectedMode == FocusMode.triglycerides ||
            _selectedMode == FocusMode.both)
          TextField(
            decoration: const InputDecoration(
              labelText: 'Triglycerides Target (mg/dL)',
              hintText: 'e.g., 150',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() => _tgTarget = double.tryParse(value));
            },
          ),
      ],
    );
  }

  Widget _buildLoggingRoutineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When Do You Prefer Logging?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Pick the routine that fits your day. We will remind you at the right time.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _FocusModeCard(
          mode: FocusMode.both,
          title: 'Evening check-in',
          description: 'Log the same day in the evening (recommended default)',
          isSelected: !_prefersMorningLogging,
          onTap: () => setState(() => _prefersMorningLogging = false),
        ),
        const SizedBox(height: 12),
        _FocusModeCard(
          mode: FocusMode.both,
          title: 'Morning catch-up',
          description: 'Log yesterday the next morning',
          isSelected: _prefersMorningLogging,
          onTap: () => setState(() => _prefersMorningLogging = true),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable daily habit reminder'),
          subtitle: Text(
            _prefersMorningLogging
                ? 'Reminder set for 8:00 AM'
                : 'Reminder set for 8:00 PM',
          ),
          value: _enableHabitReminder,
          onChanged: (value) {
            setState(() => _enableHabitReminder = value);
          },
        ),
      ],
    );
  }

  bool _canProceed() {
    // Always allow proceeding - targets and profile are optional
    return true;
  }
}

class _FocusModeCard extends StatelessWidget {
  final FocusMode mode;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusModeCard({
    required this.mode,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
