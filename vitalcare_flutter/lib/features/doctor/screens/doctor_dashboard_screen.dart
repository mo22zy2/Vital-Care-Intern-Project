import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/network/api_client.dart';
import '../providers/doctor_provider.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DoctorProvider>();

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());
    if (prov.error != null) return Center(child: Text(prov.error!, style: const TextStyle(color: AppColors.danger)));

    final d = prov.dashboard ?? {};

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
                    Text('Doctor Dashboard', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Welcome, Dr. ${ApiClient.userFirstName}', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/doctor/prescription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Write Prescription', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoPerRow = constraints.maxWidth < 720;
              final w = twoPerRow ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4;
              final cards = [
                AppStatCard(label: 'Today\'s Appointments', value: '${d['total_today'] ?? 0}', icon: Icons.calendar_today, color: AppColors.accent),
                AppStatCard(label: 'Completed', value: '${d['total_completed'] ?? 0}', icon: Icons.check_circle, color: AppColors.primary),
                AppStatCard(label: 'Pending', value: '${d['total_pending'] ?? 0}', icon: Icons.pending, color: AppColors.warning),
                AppStatCard(label: 'Upcoming', value: '${(d['upcoming'] as List? ?? []).length}', icon: Icons.schedule, color: AppColors.success),
              ];
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final c in cards) SizedBox(width: w, child: c),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _todayAppointments((d['upcoming'] as List? ?? []).cast<Map<String, dynamic>>()),
        ],
      ),
    );
  }

  Widget _todayAppointments(List<Map<String, dynamic>> items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Appointments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(icon: Icons.event_busy, title: 'No appointments today')
          else
            ...items.map((a) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.person, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['patient_name']?.toString() ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        Text('${a['time']} - ${a['reason'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  AppBadge(label: a['status']?.toString() ?? ''),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
