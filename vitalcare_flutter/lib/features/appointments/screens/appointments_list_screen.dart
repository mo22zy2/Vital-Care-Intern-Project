import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/network/api_client.dart';
import '../providers/appointments_provider.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final _searchCtl = TextEditingController();
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentsProvider>().loadAppointments();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppointmentsProvider>();
    final role = ApiClient.userRole;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Text('Appointments', style: Theme.of(context).textTheme.displayMedium),
              const Spacer(),
              if (role == 'PATIENT')
                AppButton.accent('+ Book Appointment', onPressed: () => context.push('/appointments/book')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AppCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _searchCtl,
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (v) => prov.setSearch(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusFilter.isEmpty ? null : _statusFilter,
                            hint: const Text('All Status', style: TextStyle(fontSize: 13)),
                            items: ['', 'PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'NO_SHOW']
                                .map((s) => DropdownMenuItem(
                                      value: s.isEmpty ? null : s,
                                      child: Text(s.isEmpty ? 'All Status' : s, style: const TextStyle(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _statusFilter = v ?? '');
                              prov.setStatusFilter(_statusFilter);
                            },
                            isDense: true,
                            underline: const SizedBox(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                prov.isLoading
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : prov.appointments.isEmpty
                        ? const EmptyState(icon: Icons.event_busy, title: 'No appointments found')
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: prov.appointments.length,
                            separatorBuilder: (_, _a) => Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (context, i) {
                              final a = prov.appointments[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    if (role != 'PATIENT')
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Text(a['patient_name']?.toString() ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a['doctor_name']?.toString() ?? 'Doctor',
                                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text('${a['appointment_date']} at ${a['appointment_time']}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    AppBadge(label: a['status']?.toString() ?? ''),
                                    const SizedBox(width: 12),
                                    if (a['status'] == 'PENDING' || a['status'] == 'CONFIRMED')
                                      SizedBox(
                                        height: 30,
                                        child: TextButton(
                                          onPressed: () => context.push('/appointments/cancel', extra: a),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            foregroundColor: AppColors.danger,
                                          ),
                                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
