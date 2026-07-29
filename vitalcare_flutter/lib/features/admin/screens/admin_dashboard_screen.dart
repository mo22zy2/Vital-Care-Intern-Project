import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());
    if (prov.error != null) return Center(child: Text(prov.error!, style: const TextStyle(color: AppColors.danger)));

    final d = prov.dashboard ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Dashboard', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('System overview and statistics', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  SizedBox(width: w, child: AppStatCard(label: 'Total Users', value: '${d['total_users'] ?? 0}', icon: Icons.people, color: AppColors.primary)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Appointments', value: '${d['total_appointments'] ?? 0}', icon: Icons.calendar_month, color: AppColors.accent)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Doctors', value: '${d['total_doctors'] ?? 0}', icon: Icons.medical_services, color: AppColors.info)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Revenue', value: '\$${d['total_revenue'] ?? 0}', icon: Icons.monetization_on, color: AppColors.success)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _recentUsers(d['recent_users'] as List? ?? [])),
              const SizedBox(width: 20),
              Expanded(child: _recentAppointments(d['recent_appointments'] as List? ?? [])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentUsers(List items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Users', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 12),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No users', style: TextStyle(color: AppColors.textMuted)))
          else ...items.take(5).map((u) => Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
            child: Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text((u['first_name']?.toString() ?? '?')[0], style: TextStyle(color: AppColors.primary, fontSize: 12))),
                const SizedBox(width: 10),
                Expanded(child: Text('${u['first_name']} ${u['last_name']}', style: const TextStyle(fontSize: 13))),
                Text(u['role']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _recentAppointments(List items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Appointments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 12),
          if (items.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No appointments', style: TextStyle(color: AppColors.textMuted)))
          else ...items.take(5).map((a) => Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(child: Text(a['patient_name']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                Text(a['status']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
