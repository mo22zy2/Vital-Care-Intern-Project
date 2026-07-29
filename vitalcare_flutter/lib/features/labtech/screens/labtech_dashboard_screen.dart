import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/labtech_provider.dart';

class LabtechDashboardScreen extends StatefulWidget {
  const LabtechDashboardScreen({super.key});

  @override
  State<LabtechDashboardScreen> createState() => _LabtechDashboardScreenState();
}

class _LabtechDashboardScreenState extends State<LabtechDashboardScreen> {
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LabtechProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LabtechProvider>();

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());
    if (prov.error != null) return Center(child: Text(prov.error!, style: const TextStyle(color: AppColors.danger)));

    final d = prov.dashboard ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lab Dashboard', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Manage test bookings and results', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  SizedBox(width: w, child: AppStatCard(label: 'Pending', value: '${d['pending_count'] ?? 0}', icon: Icons.pending, color: AppColors.warning)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'In Progress', value: '${d['in_progress_count'] ?? 0}', icon: Icons.science, color: AppColors.info)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Completed Today', value: '${d['completed_today'] ?? 0}', icon: Icons.check_circle, color: AppColors.success)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Total Tests', value: '${d['total_tests'] ?? 0}', icon: Icons.biotech, color: AppColors.primary)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _filterBar(prov),
          const SizedBox(height: 16),
          _pipelineSection(prov),
        ],
      ),
    );
  }

  Widget _filterBar(LabtechProvider prov) {
    final filters = ['', 'booked', 'sample_collected', 'in_progress', 'completed', 'cancelled'];
    final labels = {'': 'All', 'booked': 'Booked', 'sample_collected': 'Sample Collected', 'in_progress': 'In Progress', 'completed': 'Completed', 'cancelled': 'Cancelled'};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final active = _statusFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _statusFilter = f);
                prov.setStatusFilter(f);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: active ? AppColors.primary : AppColors.border),
                ),
                child: Text(labels[f] ?? f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _pipelineSection(LabtechProvider prov) {
    if (prov.bookings.isEmpty) {
      return const EmptyState(icon: Icons.biotech, title: 'No bookings found');
    }

    return Column(
      children: prov.bookings.map((b) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.biotech, color: AppColors.info, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['test_name']?.toString() ?? 'Lab Test', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Patient: ${b['patient_name'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  AppBadge(label: b['status']?.toString() ?? ''),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _actionsFor(b, prov),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  List<Widget> _actionsFor(Map<String, dynamic> b, LabtechProvider prov) {
    final status = b['status']?.toString() ?? '';
    final id = b['id'].toString();

    switch (status) {
      case 'booked':
        return [
          _actionBtn('Collect Sample', AppColors.info, () => _updateStatus(prov, id, 'sample_collected')),
        ];
      case 'sample_collected':
        return [
          _actionBtn('Start Test', AppColors.warning, () => _updateStatus(prov, id, 'in_progress')),
        ];
      case 'in_progress':
        return [
          _actionBtn('Release Result', AppColors.success, () => _showResultDialog(prov, id)),
        ];
      default:
        return [];
    }
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _updateStatus(LabtechProvider prov, String id, String status) async {
    final ok = await prov.updateBookingStatus(id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Status updated' : 'Failed: ${prov.error}'), backgroundColor: ok ? AppColors.success : AppColors.danger),
      );
    }
  }

  void _showResultDialog(LabtechProvider prov, String id) {
    final resultController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: resultController, decoration: const InputDecoration(labelText: 'Result', hintText: 'e.g. Positive / 5.2 mg/dL'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (resultController.text.isEmpty) return;
              final ok = await prov.updateBookingStatus(id, 'completed', resultData: {
                'result': resultController.text,
                'notes': notesController.text,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Result released' : 'Failed'), backgroundColor: ok ? AppColors.success : AppColors.danger),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }
}
