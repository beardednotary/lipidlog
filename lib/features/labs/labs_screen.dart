import 'package:flutter/material.dart';
import '../../core/services/storage_service.dart';
import '../../core/models/lab_result.dart';
import 'add_lab_screen.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key});

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  @override
  Widget build(BuildContext context) {
    final labs = StorageService.getAllLabResults();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labs'),
      ),
      body: labs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No lab results yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first lab',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: labs.length,
              itemBuilder: (context, index) {
                final lab = labs[index];
                return _LabCard(lab: lab);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLabScreen()),
          );
          setState(() {}); // Refresh list
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LabCard extends StatelessWidget {
  final LabResult lab;

  const _LabCard({required this.lab});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${lab.date.month}/${lab.date.day}/${lab.date.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (lab.isFasting)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Fasting',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (lab.ldl != null)
                  _LabValue(
                    label: 'LDL',
                    value: lab.ldl!.toStringAsFixed(0),
                  ),
                if (lab.hdl != null)
                  _LabValue(
                    label: 'HDL',
                    value: lab.hdl!.toStringAsFixed(0),
                  ),
                if (lab.triglycerides != null)
                  _LabValue(
                    label: 'TG',
                    value: lab.triglycerides!.toStringAsFixed(0),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
