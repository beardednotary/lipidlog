import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/storage_service.dart';
import '../../core/models/lab_result.dart';
import 'add_lab_screen.dart';

class LabsScreen extends StatefulWidget {
  const LabsScreen({super.key});

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  int _selectedChart = 0; // 0 = LDL, 1 = TG

  @override
  Widget build(BuildContext context) {
    final labs = StorageService.getAllLabResults();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labs'),
        actions: [
          IconButton(
            tooltip: 'Import from photo',
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddLabScreen(startPhotoImport: true),
                ),
              );
              setState(() {});
            },
          ),
        ],
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TrendChartCard(
                  labs: labs,
                  selectedChart: _selectedChart,
                  onChartChanged: (index) {
                    setState(() => _selectedChart = index);
                  },
                ),
                const SizedBox(height: 16),
                ...labs.map((lab) => _LabCard(lab: lab)),
              ],
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

class _TrendChartCard extends StatelessWidget {
  final List<LabResult> labs;
  final int selectedChart;
  final ValueChanged<int> onChartChanged;

  const _TrendChartCard({
    required this.labs,
    required this.selectedChart,
    required this.onChartChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<LabResult>.from(labs)
      ..sort((a, b) => a.date.compareTo(b.date));

    final points = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final lab = sorted[i];
      final value = selectedChart == 0 ? lab.ldl : lab.triglycerides;
      if (value != null) {
        points.add(FlSpot(i.toDouble(), value));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('LDL')),
                ButtonSegment<int>(value: 1, label: Text('TG')),
              ],
              selected: {selectedChart},
              onSelectionChanged: (selection) {
                onChartChanged(selection.first);
              },
            ),
            const SizedBox(height: 16),
            if (points.length < 2)
              Text(
                'Add at least 2 ${selectedChart == 0 ? 'LDL' : 'TG'} values to see a trend chart.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points,
                        isCurved: true,
                        color: selectedChart == 0
                            ? Colors.blue.shade600
                            : Colors.orange.shade700,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: (selectedChart == 0
                                  ? Colors.blue.shade600
                                  : Colors.orange.shade700)
                              .withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
