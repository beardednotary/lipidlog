import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/lab_result.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/score_service.dart';

enum _ImportState {
  idle,
  picking,
  parsing,
  review,
}

class AddLabScreen extends StatefulWidget {
  final bool startPhotoImport;

  const AddLabScreen({
    super.key,
    this.startPhotoImport = false,
  });

  @override
  State<AddLabScreen> createState() => _AddLabScreenState();
}

class _AddLabScreenState extends State<AddLabScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Controllers
  final _ldlController = TextEditingController();
  final _hdlController = TextEditingController();
  final _tgController = TextEditingController();
  final _totalController = TextEditingController();
  final _nonHdlController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isFasting = false;
  bool _isSaving = false;
  _ImportState _importState = _ImportState.idle;
  String? _importMessage;

  @override
  void initState() {
    super.initState();
    if (widget.startPhotoImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startPhotoImport();
      });
    }
  }

  @override
  void dispose() {
    _ldlController.dispose();
    _hdlController.dispose();
    _tgController.dispose();
    _totalController.dispose();
    _nonHdlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Lab Date',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveLab() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one value is entered
    if (_ldlController.text.isEmpty &&
        _hdlController.text.isEmpty &&
        _tgController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least LDL, HDL, or Triglycerides'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create lab result
      final lab = LabResult(
        id: _uuid.v4(),
        date: _selectedDate,
        ldl: _ldlController.text.isNotEmpty
            ? double.parse(_ldlController.text)
            : null,
        hdl: _hdlController.text.isNotEmpty
            ? double.parse(_hdlController.text)
            : null,
        triglycerides: _tgController.text.isNotEmpty
            ? double.parse(_tgController.text)
            : null,
        totalCholesterol: _totalController.text.isNotEmpty
            ? double.parse(_totalController.text)
            : null,
        nonHdl: _nonHdlController.text.isNotEmpty
            ? double.parse(_nonHdlController.text)
            : null,
        isFasting: _isFasting,
      );

      // Save to storage
      await StorageService.saveLabResult(lab);

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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lab saved! Your score is now ${newScore.overallScore.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving lab: $e'),
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

  Future<void> _startPhotoImport() async {
    if (_importState == _ImportState.picking ||
        _importState == _ImportState.parsing) {
      return;
    }

    setState(() {
      _importState = _ImportState.picking;
      _importMessage = 'Opening image picker...';
    });

    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      _importState = _ImportState.parsing;
      _importMessage = 'Extracting lipid markers from image...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() {
      _importState = _ImportState.review;
      _importMessage =
          'OCR scaffold complete. Automatic extraction will be enabled in a follow-up update.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Lab Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.camera_alt_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Import from Lab Photo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _importMessage ??
                            'Use camera/image import flow (OCR placeholder for MVP).',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_importState == _ImportState.picking ||
                                    _importState == _ImportState.parsing)
                                ? null
                                : _startPhotoImport,
                            icon: const Icon(Icons.photo_camera_back_outlined),
                            label: const Text('Start Photo Import'),
                          ),
                          if (_importState == _ImportState.review)
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _importState = _ImportState.idle;
                                  _importMessage = null;
                                });
                              },
                              child: const Text('Reset Import State'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date picker
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Lab Date'),
                  subtitle: Text(
                    '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // Fasting toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Fasting Test'),
                  subtitle: const Text('Were you fasting before this test?'),
                  value: _isFasting,
                  onChanged: (value) {
                    setState(() {
                      _isFasting = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Cholesterol Values (mg/dL)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // LDL
              TextFormField(
                controller: _ldlController,
                decoration: const InputDecoration(
                  labelText: 'LDL Cholesterol',
                  hintText: 'e.g., 140',
                  suffixText: 'mg/dL',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // HDL
              TextFormField(
                controller: _hdlController,
                decoration: const InputDecoration(
                  labelText: 'HDL Cholesterol',
                  hintText: 'e.g., 45',
                  suffixText: 'mg/dL',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Triglycerides
              TextFormField(
                controller: _tgController,
                decoration: const InputDecoration(
                  labelText: 'Triglycerides',
                  hintText: 'e.g., 180',
                  suffixText: 'mg/dL',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total Cholesterol
              TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(
                  labelText: 'Total Cholesterol (optional)',
                  hintText: 'e.g., 220',
                  suffixText: 'mg/dL',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Non-HDL
              TextFormField(
                controller: _nonHdlController,
                decoration: const InputDecoration(
                  labelText: 'Non-HDL Cholesterol (optional)',
                  hintText: 'e.g., 175',
                  suffixText: 'mg/dL',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLab,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Lab Results'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
