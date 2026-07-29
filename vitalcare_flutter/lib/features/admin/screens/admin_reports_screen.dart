import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../providers/admin_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
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
          Text('Reports', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  SizedBox(width: w, child: AppStatCard(label: 'Total Users', value: '${d['total_users'] ?? 0}', icon: Icons.people, color: AppColors.primary)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Total Doctors', value: '${d['total_doctors'] ?? 0}', icon: Icons.medical_services, color: AppColors.info)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Total Patients', value: '${d['total_patients'] ?? 0}', icon: Icons.person, color: AppColors.accent)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Total Appointments', value: '${d['total_appointments'] ?? 0}', icon: Icons.calendar_month, color: AppColors.warning)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  SizedBox(width: w, child: AppStatCard(label: 'Total Revenue', value: '\$${d['total_revenue'] ?? 0}', icon: Icons.monetization_on, color: AppColors.success)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Avg Rating', value: (d['avg_rating'] ?? 0.0).toStringAsFixed(1), icon: Icons.star, color: AppColors.warning)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Pending Orders', value: '${d['pending_orders'] ?? 0}', icon: Icons.inventory, color: AppColors.danger)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Lab Tests', value: '${d['total_lab_tests'] ?? 0}', icon: Icons.biotech, color: AppColors.info)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _summaryCard('Recent Activity', d['recent_activity'] as List? ?? []),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, List items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No activity', style: TextStyle(color: AppColors.textMuted)))
          else
            ...items.map((a) => Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a['description']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                  Text(a['timestamp']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
