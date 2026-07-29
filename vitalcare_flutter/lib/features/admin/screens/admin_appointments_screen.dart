import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAppointments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    return Column(
      children: [
        _filterBar(prov),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.appointments.isEmpty
                  ? const EmptyState(icon: Icons.event_busy, title: 'No appointments')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prov.appointments.length,
                      itemBuilder: (_, i) => _card(prov.appointments[i], prov),
                    ),
        ),
      ],
    );
  }

  Widget _filterBar(AdminProvider prov) {
    final filters = ['', 'scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled'];
    final labels = {'': 'All', 'scheduled': 'Scheduled', 'confirmed': 'Confirmed', 'in_progress': 'In Progress', 'completed': 'Completed', 'cancelled': 'Cancelled'};
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                style: const TextStyle(fontSize: 14),
                onChanged: (q) { prov.setSearch(q); prov.loadAppointments(); },
              ),
            ),
            ...filters.map((f) {
              final active = prov.statusFilter == f;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () { prov.setStatusFilter(f); prov.loadAppointments(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: active ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? AppColors.primary : AppColors.border)),
                    child: Text(labels[f] ?? f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> a, AdminProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, color: AppColors.accent, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['patient_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('Dr. ${a['doctor_name'] ?? ''} - ${a['date']} ${a['time'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AppBadge(label: a['status']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }
}
