import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/network/api_client.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DashboardProvider>();
    final role = ApiClient.userRole;

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());
    if (prov.error != null) return Center(child: Text(prov.error!, style: const TextStyle(color: AppColors.danger)));

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
                    Text('Dashboard', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Welcome back, ${ApiClient.userFirstName}', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (role == 'PATIENT')
                AppButton.accent('+ New Appointment', onPressed: () => context.push('/appointments/book')),
            ],
          ),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          if (prov.data != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _upcomingAppointments(prov.data!['upcoming_appointments'] as List? ?? [])),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _recentActivity(prov.data!['recent_activity'] as List? ?? [])),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 48) / 4;
        return Row(
          children: [
            SizedBox(width: w, child: const AppStatCard(label: 'Appointments Today', value: '3', icon: Icons.calendar_today, color: AppColors.accent)),
            const SizedBox(width: 16),
            SizedBox(width: w, child: const AppStatCard(label: 'Active Doctors', value: '8', icon: Icons.medical_services, color: AppColors.primary)),
            const SizedBox(width: 16),
            SizedBox(width: w, child: const AppStatCard(label: 'Pending Orders', value: '2', icon: Icons.inventory, color: AppColors.success)),
            const SizedBox(width: 16),
            SizedBox(width: w, child: const AppStatCard(label: 'Revenue', value: '\$1,420', icon: Icons.monetization_on, color: AppColors.info)),
          ],
        );
      },
    );
  }

  Widget _upcomingAppointments(List items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming Appointments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(icon: Icons.event_busy, title: 'No upcoming appointments',
                description: 'Book your first appointment to get started')
          else
            ...items.map((a) => _appointmentRow(a)),
        ],
      ),
    );
  }

  Widget _appointmentRow(Map<String, dynamic> a) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['doctor_name']?.toString() ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text('${a['date']} at ${a['time']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          AppBadge(label: a['status']?.toString() ?? ''),
        ],
      ),
    );
  }

  Widget _recentActivity(List items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(icon: Icons.history, title: 'No recent activity')
          else
            ...items.map((a) => _activityRow(a)),
        ],
      ),
    );
  }

  Widget _activityRow(Map<String, dynamic> a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['description']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                Text(a['timestamp']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
