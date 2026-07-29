import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_card.dart';

class WritePrescriptionScreen extends StatefulWidget {
  const WritePrescriptionScreen({super.key});

  @override
  State<WritePrescriptionScreen> createState() => _WritePrescriptionScreenState();
}

class _WritePrescriptionScreenState extends State<WritePrescriptionScreen> {
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedAppointmentId;
  String? _selectedPatientId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _prescriptionItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final appts = await ApiClient.get(ApiConstants.doctorAppointments, queryParams: {'status': 'in_progress'});
      final meds = await ApiClient.get(ApiConstants.medicines, queryParams: {'limit': '200'});
      setState(() {
        _appointments = (appts['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _medicines = (meds['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Write Prescription', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedAppointmentId,
                  decoration: const InputDecoration(labelText: 'Select active appointment'),
                  items: _appointments.map((a) => DropdownMenuItem(
                    value: a['id']?.toString(),
                    child: Text('${a['patient_name']} - ${a['time']}'),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedAppointmentId = v;
                      final appt = _appointments.firstWhere((a) => a['id'].toString() == v);
                      _selectedPatientId = appt['patient_id']?.toString();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diagnosis & Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(labelText: 'Diagnosis', hintText: 'Enter diagnosis'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes / Instructions', hintText: 'Additional notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Medicines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _showAddMedicineDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('+ Add Medicine', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_prescriptionItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No medicines added yet', style: TextStyle(color: AppColors.textMuted))),
                  )
                else
                  ..._prescriptionItems.asMap().entries.map((e) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value['medicine_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              Text('${e.value['dosage']} - ${e.value['frequency']} for ${e.value['duration']} days',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                          onPressed: () => setState(() => _prescriptionItems.removeAt(e.key)),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedAppointmentId == null ? null : _savePrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Prescription'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog() {
    String? selectedMedicineId;
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final durationController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Medicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Search medicines', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setDialogState(() => searchQuery = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView(
                    children: _medicines
                        .where((m) => m['name']?.toString().toLowerCase().contains(searchQuery) ?? true)
                        .map((m) => RadioListTile<String>(
                          title: Text('${m['name']} (${m['dosage_form'] ?? ''} ${m['strength'] ?? ''})', style: const TextStyle(fontSize: 13)),
                          value: m['id'].toString(),
                          groupValue: selectedMedicineId,
                          onChanged: (v) => setDialogState(() => selectedMedicineId = v),
                          dense: true,
                        ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(controller: dosageController, decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 500mg')),
                const SizedBox(height: 8),
                TextField(controller: frequencyController, decoration: const InputDecoration(labelText: 'Frequency', hintText: 'e.g. Twice daily')),
                const SizedBox(height: 8),
                TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (days)', hintText: 'e.g. 7'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedMedicineId == null || dosageController.text.isEmpty) return;
                final med = _medicines.firstWhere((m) => m['id'].toString() == selectedMedicineId);
                setState(() {
                  _prescriptionItems.add({
                    'medicine': selectedMedicineId,
                    'medicine_name': med['name'],
                    'dosage': dosageController.text,
                    'frequency': frequencyController.text,
                    'duration': int.tryParse(durationController.text) ?? 7,
                  });
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrescription() async {
    try {
      await ApiClient.post(ApiConstants.prescriptions, body: {
        'appointment': _selectedAppointmentId,
        'patient': _selectedPatientId,
        'diagnosis': _diagnosisController.text,
        'notes': _notesController.text,
        'items': _prescriptionItems.map((i) => {
          'medicine': i['medicine'],
          'dosage': i['dosage'],
          'frequency': i['frequency'],
          'duration': i['duration'],
        }).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}
