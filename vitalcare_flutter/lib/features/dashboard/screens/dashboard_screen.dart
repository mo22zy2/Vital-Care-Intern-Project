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

    final data = prov.data;
    final upcoming = (data?['upcoming_appointments'] as List? ?? []).cast<Map<String, dynamic>>();
    final activities = (data?['recent_activities'] as List? ?? []).cast<Map<String, dynamic>>();

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
                    Text('Welcome back, ${ApiClient.userFirstName}. Here\'s your hospital overview.',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (role == 'PATIENT')
                AppButton.accent('+ New Appointment', onPressed: () => context.push('/appointments/book')),
            ],
          ),
          const SizedBox(height: 24),
          _buildStats(data),
          const SizedBox(height: 24),
          if (data != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final leftWidth = constraints.maxWidth * 2 / 3;
                final rightWidth = constraints.maxWidth * 1 / 3 - 16;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: leftWidth, child: _upcomingAppointments(upcoming)),
                    const SizedBox(width: 16),
                    SizedBox(width: rightWidth, child: _recentActivity(activities)),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic>? data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 48) / 4;
        return Row(
          children: [
            SizedBox(
              width: w,
              child: AppStatCard(
                label: 'Appointments Today',
                value: '${data?['total_appointments'] ?? 0}',
                icon: Icons.calendar_today,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: w,
              child: AppStatCard(
                label: 'Unread Notifications',
                value: '${data?['unread_notifications'] ?? 0}',
                icon: Icons.notifications,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: w,
              child: AppStatCard(
                label: 'Pending Orders',
                value: '${data?['pending_orders'] ?? 0}',
                icon: Icons.inventory,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: w,
              child: AppStatCard(
                label: 'Total Invoices',
                value: '${data?['total_invoices'] ?? 0}',
                icon: Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _upcomingAppointments(List<Map<String, dynamic>> items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Upcoming Appointments',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
              ),
              InkWell(
                onTap: () => context.push('/appointments'),
                child: const Text('View all →',
                    style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(
                icon: Icons.event_busy,
                title: 'No upcoming appointments',
                description: 'Schedule your first appointment to get started.')
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

  Widget _recentActivity(List<Map<String, dynamic>> items) {
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
                Text(a['date']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
