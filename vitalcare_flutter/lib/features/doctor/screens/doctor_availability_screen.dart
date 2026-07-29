import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/doctor_provider.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadAvailability();
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DoctorProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Availability', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Manage your weekly schedule', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showAddDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('+ Add Slot', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (prov.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (prov.availability.isEmpty)
            const EmptyState(icon: Icons.schedule, title: 'No availability set')
          else
            ...prov.availability.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(s['day']?.toString().substring(0, 3) ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${s['start_time']} - ${s['end_time']}', style: const TextStyle(fontSize: 14)),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                      onPressed: () => prov.deleteAvailabilitySlot(s['id'].toString()),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _startController.clear();
    _endController.clear();
    String selectedDay = 'Monday';
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Availability Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setDialogState(() => selectedDay = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: _startController, decoration: const InputDecoration(labelText: 'Start Time (HH:MM)', hintText: '09:00')),
              const SizedBox(height: 12),
              TextField(controller: _endController, decoration: const InputDecoration(labelText: 'End Time (HH:MM)', hintText: '17:00')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_startController.text.isEmpty || _endController.text.isEmpty) return;
                final prov = context.read<DoctorProvider>();
                await prov.saveAvailability([{
                  'day': selectedDay,
                  'start_time': _startController.text,
                  'end_time': _endController.text,
                }]);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
