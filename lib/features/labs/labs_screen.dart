import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/storage_service.dart';
import '../../core/models/lab_result.dart';
import '../../core/theme/app_theme.dart';
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
    final profile = StorageService.getUserProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labs'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),
        ),
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
                  Icon(Icons.science_outlined, size: 64, color: AppTheme.textTertiary),
                  const SizedBox(height: 16),
                  Text('No lab results yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first lab result',
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
                  ldlTarget: profile?.ldlTarget,
                  tgTarget: profile?.tgTarget,
                  onChartChanged: (index) => setState(() => _selectedChart = index),
                ),
                const SizedBox(height: 16),
                ...labs.map(
                  (lab) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LabCard(
                      lab: lab,
                      ldlTarget: profile?.ldlTarget,
                      tgTarget: profile?.tgTarget,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLabScreen()),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Trend chart card ───────────────────────────────────────────────────────────

class _TrendChartCard extends StatelessWidget {
  final List<LabResult> labs;
  final int selectedChart;
  final double? ldlTarget;
  final double? tgTarget;
  final ValueChanged<int> onChartChanged;

  const _TrendChartCard({
    required this.labs,
    required this.selectedChart,
    this.ldlTarget,
    this.tgTarget,
    required this.onChartChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<LabResult>.from(labs)
      ..sort((a, b) => a.date.compareTo(b.date));

    final points = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final value = selectedChart == 0 ? sorted[i].ldl : sorted[i].triglycerides;
      if (value != null) points.add(FlSpot(i.toDouble(), value));
    }

    final lineColor = selectedChart == 0 ? AppTheme.primaryColor : AppTheme.warningColor;
    final target = selectedChart == 0 ? ldlTarget : tgTarget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trends', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('LDL')),
                ButtonSegment<int>(value: 1, label: Text('TG')),
              ],
              selected: {selectedChart},
              onSelectionChanged: (s) => onChartChanged(s.first),
            ),
            const SizedBox(height: 16),
            if (points.length < 2)
              Text(
                'Add at least 2 ${selectedChart == 0 ? 'LDL' : 'TG'} values to see a trend.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    extraLinesData: target != null
                        ? ExtraLinesData(horizontalLines: [
                            HorizontalLine(
                              y: target,
                              color: AppTheme.positiveColor.withValues(alpha: 0.7),
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                labelResolver: (_) => 'Goal',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.positiveColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ])
                        : null,
                    lineBarsData: [
                      LineChartBarData(
                        spots: points,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: lineColor,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            radius: 4,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              lineColor.withValues(alpha: 0.15),
                              lineColor.withValues(alpha: 0.0),
                            ],
                          ),
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

// ── Lab card with health signals ───────────────────────────────────────────────

class _LabCard extends StatelessWidget {
  final LabResult lab;
  final double? ldlTarget;
  final double? tgTarget;

  const _LabCard({required this.lab, this.ldlTarget, this.tgTarget});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_monthName(lab.date.month)} ${lab.date.day}, ${lab.date.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (lab.isFasting)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Fasting',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.dividerColor, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (lab.ldl != null)
                  _LabValueWithSignal(
                    label: 'LDL',
                    value: lab.ldl!,
                    signal: _ldlSignal(lab.ldl!),
                    target: ldlTarget != null ? '< ${ldlTarget!.toStringAsFixed(0)}' : '< 100',
                  ),
                if (lab.hdl != null)
                  _LabValueWithSignal(
                    label: 'HDL',
                    value: lab.hdl!,
                    signal: _hdlSignal(lab.hdl!),
                    target: '> 60',
                    higherIsBetter: true,
                  ),
                if (lab.triglycerides != null)
                  _LabValueWithSignal(
                    label: 'TG',
                    value: lab.triglycerides!,
                    signal: _tgSignal(lab.triglycerides!),
                    target: tgTarget != null ? '< ${tgTarget!.toStringAsFixed(0)}' : '< 150',
                  ),
                if (lab.totalCholesterol != null)
                  _LabValueWithSignal(
                    label: 'Total',
                    value: lab.totalCholesterol!,
                    signal: _totalSignal(lab.totalCholesterol!),
                    target: '< 200',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month];
  }

  _HealthSignal _ldlSignal(double v) {
    if (v < 70) return _HealthSignal('Optimal', AppTheme.positiveColor);
    if (v < 100) return _HealthSignal('Near Optimal', AppTheme.positiveColor);
    if (v < 130) return _HealthSignal('Borderline', AppTheme.warningColor);
    if (v < 160) return _HealthSignal('High', AppTheme.warningColor);
    if (v < 190) return _HealthSignal('High', AppTheme.dangerColor);
    return _HealthSignal('Very High', AppTheme.dangerColor);
  }

  _HealthSignal _hdlSignal(double v) {
    if (v >= 60) return _HealthSignal('Optimal', AppTheme.positiveColor);
    if (v >= 40) return _HealthSignal('Normal', AppTheme.warningColor);
    return _HealthSignal('Low', AppTheme.dangerColor);
  }

  _HealthSignal _tgSignal(double v) {
    if (v < 150) return _HealthSignal('Normal', AppTheme.positiveColor);
    if (v < 200) return _HealthSignal('Borderline', AppTheme.warningColor);
    if (v < 500) return _HealthSignal('High', AppTheme.dangerColor);
    return _HealthSignal('Very High', AppTheme.dangerColor);
  }

  _HealthSignal _totalSignal(double v) {
    if (v < 200) return _HealthSignal('Optimal', AppTheme.positiveColor);
    if (v < 240) return _HealthSignal('Borderline', AppTheme.warningColor);
    return _HealthSignal('High', AppTheme.dangerColor);
  }
}

class _HealthSignal {
  final String label;
  final Color color;
  const _HealthSignal(this.label, this.color);
}

class _LabValueWithSignal extends StatelessWidget {
  final String label;
  final double value;
  final _HealthSignal signal;
  final String target;
  final bool higherIsBetter;

  const _LabValueWithSignal({
    required this.label,
    required this.value,
    required this.signal,
    required this.target,
    this.higherIsBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: signal.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            signal.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: signal.color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Target $target',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
        ),
      ],
    );
  }
}
