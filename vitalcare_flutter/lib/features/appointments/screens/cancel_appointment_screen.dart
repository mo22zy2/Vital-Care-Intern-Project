import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/appointments_provider.dart';

class CancelAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const CancelAppointmentScreen({super.key, required this.appointment});

  @override
  State<CancelAppointmentScreen> createState() => _CancelAppointmentScreenState();
}

class _CancelAppointmentScreenState extends State<CancelAppointmentScreen> {
  final _reasonCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: AppCard(
          maxWidth: 540,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancel Appointment', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doctor: ${a['doctor_name'] ?? 'N/A'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Date: ${a['date']} at ${a['time']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Reason: ${a['reason'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Cancellation Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonCtl,
                decoration: const InputDecoration(hintText: 'Tell us why you\'re cancelling...'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton.danger('Confirm Cancellation',
                        isLoading: _loading,
                        onPressed: _submit),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.outline('Keep Appointment',
                        onPressed: () => Navigator.pop(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok = await context.read<AppointmentsProvider>()
        .cancelAppointment(widget.appointment['id'].toString(), _reasonCtl.text);
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      context.read<AppointmentsProvider>().loadAppointments();
    }
  }
}
