import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_date_time_field.dart';
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
  final _phoneCtl = TextEditingController();
  String _reason = 'CONSULTATION';
  final _notesCtl = TextEditingController();
  bool _loading = false;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final savedPhone = ApiClient.currentUser?['phone']?.toString() ?? '';
    if (savedPhone.isNotEmpty) _phoneCtl.text = savedPhone;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<AppointmentsProvider>();
      await prov.loadDoctorsAndSpecialties();
      if (!mounted) return;
      final pre = widget.preselectedDoctor;
      if (pre != null) {
        final id = pre['id'].toString();
        final inList = prov.doctors.any((d) => d['id'].toString() == id);
        if (inList && _doctorId == null) {
          setState(() => _doctorId = id);
        }
      }
    });
  }

  @override
  void dispose() {
    _dateCtl.dispose();
    _timeCtl.dispose();
    _phoneCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _selectedDoctor() {
    if (_doctorId == null) return widget.preselectedDoctor;
    for (final d in context.read<AppointmentsProvider>().doctors) {
      if (d['id'].toString() == _doctorId) return d;
    }
    return null;
  }

  List<Map<String, dynamic>> _slots() {
    final raw = _selectedDoctor()?['availability'] as List? ?? const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String _workingHours() {
    final slots = _slots();
    if (slots.isEmpty) return 'No working hours set yet';
    return slots
        .map((s) => '${s['weekday_name']} ${s['start_time']}\u2013${s['end_time']}')
        .join(' · ');
  }

  int? _toMinutes(Object? v) {
    final parts = v?.toString().split(':');
    if (parts == null || parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  String? _availabilityError() {
    final slots = _slots();
    if (slots.isEmpty) return null;
    final date = DateTime.tryParse(_dateCtl.text);
    final timeStr = _timeCtl.text.trim();
    if (date == null || timeStr.isEmpty) return null;
    final t = _toMinutes(timeStr);
    if (t == null) return null;
    for (final s in slots) {
      if (s['weekday'] == date.weekday - 1) {
        final st = _toMinutes(s['start_time']);
        final en = _toMinutes(s['end_time']);
        if (st != null && en != null && t >= st && t <= en) return null;
      }
    }
    final name = _selectedDoctor()?['full_name']?.toString() ?? 'the doctor';
    return '$name is not available at $timeStr on this day. Working hours: ${_workingHours()}';
  }

  void _recheckTime() {
    if (!mounted) return;
    setState(() {
      _timeError = _availabilityError();
    });
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
                    _timeError = null;
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
                  onChanged: (v) => setState(() {
                    _doctorId = v;
                    _timeError = null;
                  }),
                  validator: (v) => v == null ? 'Required' : null,
                  style: const TextStyle(fontSize: 14),
                ),
                if (_doctorId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.schedule, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Working hours: ${_workingHours()}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppDateField(
                        controller: _dateCtl,
                        label: 'Date *',
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onChanged: _recheckTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTimeField(
                        controller: _timeCtl,
                        label: 'Time *',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onChanged: _recheckTime,
                      ),
                    ),
                  ],
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _timeError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: "We'll call you to confirm your appointment",
                    prefixIcon: Icon(Icons.phone, size: 16),
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length < 8 || digits.length > 15) {
                      return 'Enter a valid phone number (8 to 15 digits)';
                    }
                    return null;
                  },
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
    setState(() => _timeError = _availabilityError());
    if (_timeError != null) return;
    setState(() => _loading = true);

    final ok = await context.read<AppointmentsProvider>().bookAppointment({
      'doctor_id': _doctorId,
      'appointment_date': _dateCtl.text.trim(),
      'appointment_time': _timeCtl.text.trim(),
      'reason': _reason,
      'notes': _notesCtl.text.trim(),
      'contact_phone': _phoneCtl.text.trim(),
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
