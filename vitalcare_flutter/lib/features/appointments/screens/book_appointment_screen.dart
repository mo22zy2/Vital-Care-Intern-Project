import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/appointments_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? preselectedDoctor;

  const BookAppointmentScreen({super.key, this.preselectedDoctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _specialtyId;
  String? _doctorId;
  final _dateCtl = TextEditingController();
  final _timeCtl = TextEditingController();
  String _reason = 'CONSULTATION';
  final _notesCtl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AppointmentsProvider>();
      prov.loadDoctorsAndSpecialties();
    });
  }

  @override
  void dispose() {
    _dateCtl.dispose();
    _timeCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppointmentsProvider>();
    final filteredDocs = prov.doctors.where((d) {
      final specs = (d['specialties'] as List?)?.cast<String>() ?? [];
      return _specialtyId == null || specs.contains(_getSpecialtyName(prov, _specialtyId!));
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: AppCard(
          maxWidth: 640,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book Appointment', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Specialty'),
                  items: prov.specialties.map((s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text(s['name']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setState(() {
                    _specialtyId = v;
                    _doctorId = null;
                  }),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Doctor *'),
                  value: _doctorId,
                  items: filteredDocs.map((d) => DropdownMenuItem(
                    value: d['id'].toString(),
                    child: Text(d['full_name']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setState(() => _doctorId = v),
                  validator: (v) => v == null ? 'Required' : null,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtl,
                        decoration: const InputDecoration(labelText: 'Date *', hintText: 'YYYY-MM-DD'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _timeCtl,
                        decoration: const InputDecoration(labelText: 'Time *', hintText: 'HH:MM'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Reason'),
                  value: _reason,
                  items: ['CONSULTATION', 'FOLLOW_UP', 'ROUTINE_CHECKUP', 'EMERGENCY', 'OTHER']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (v) => _reason = v ?? 'CONSULTATION',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtl,
                  decoration: const InputDecoration(labelText: 'Notes', hintText: 'Optional notes...'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary('Book Appointment',
                          isLoading: _loading,
                          onPressed: _submit),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.outline('Cancel', onPressed: () => context.pop()),
                    ),
                  ],
                ),
                if (prov.error != null) ...[
                  const SizedBox(height: 12),
                  Text(prov.error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await context.read<AppointmentsProvider>().bookAppointment({
      'doctor_id': _doctorId,
      'appointment_date': _dateCtl.text.trim(),
      'appointment_time': _timeCtl.text.trim(),
      'reason': _reason,
      'notes': _notesCtl.text.trim(),
    });

    setState(() => _loading = false);
    if (ok && mounted) {
      context.pop();
      context.read<AppointmentsProvider>().loadAppointments();
    }
  }

  String _getSpecialtyName(AppointmentsProvider prov, String id) {
    for (final s in prov.specialties) {
      if (s['id'].toString() == id) return s['name']?.toString() ?? '';
    }
    return '';
  }
}
