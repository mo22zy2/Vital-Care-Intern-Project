import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/doctor_provider.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadAppointments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DoctorProvider>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search patient...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (q) => prov.setSearch(q),
                  ),
                ),
                const SizedBox(width: 8),
                _filterChip('All', '', prov),
                _filterChip('Scheduled', 'scheduled', prov),
                _filterChip('In Progress', 'in_progress', prov),
                _filterChip('Completed', 'completed', prov),
                _filterChip('Cancelled', 'cancelled', prov),
                _filterChip('No Show', 'no_show', prov),
              ],
            ),
          ),
        ),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.appointments.isEmpty
                  ? const EmptyState(icon: Icons.event_busy, title: 'No appointments')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prov.appointments.length,
                      itemBuilder: (_, i) => _appointmentCard(prov.appointments[i], prov),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, DoctorProvider prov) {
    final active = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _statusFilter = value);
          prov.setStatusFilter(value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> a, DoctorProvider prov) {
    final status = a['status']?.toString() ?? '';
    final actionable = ['scheduled', 'confirmed'].contains(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['patient_name']?.toString() ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${a['date']} at ${a['time']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                AppBadge(label: status, color: _statusColor(status)),
              ],
            ),
            if (a['reason']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Reason: ${a['reason']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
            if (actionable) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionBtn('Accept', AppColors.primary, () => _updateStatus(prov, a['id'].toString(), 'confirmed')),
                  const SizedBox(width: 8),
                  _actionBtn('Cancel', AppColors.danger, () => _updateStatus(prov, a['id'].toString(), 'cancelled')),
                ],
              ),
            ],
            if (status == 'confirmed') ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionBtn('Start', AppColors.warning, () => _updateStatus(prov, a['id'].toString(), 'in_progress')),
                ],
              ),
            ],
            if (status == 'in_progress') ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionBtn('Complete', AppColors.success, () => _updateStatus(prov, a['id'].toString(), 'completed')),
                  const SizedBox(width: 8),
                  _actionBtn('No Show', AppColors.danger, () => _updateStatus(prov, a['id'].toString(), 'no_show')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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

  Color _statusColor(String status) {
    switch (status) {
      case 'scheduled': return AppColors.info;
      case 'confirmed': return AppColors.primary;
      case 'in_progress': return AppColors.warning;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.danger;
      case 'no_show': return AppColors.textMuted;
      default: return AppColors.textSecondary;
    }
  }

  Future<void> _updateStatus(DoctorProvider prov, String id, String status) async {
    final ok = await prov.updateAppointmentStatus(id, status);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${prov.error}'), backgroundColor: AppColors.danger),
      );
    }
  }
}
