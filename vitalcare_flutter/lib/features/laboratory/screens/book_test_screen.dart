import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../providers/laboratory_provider.dart';

class BookTestScreen extends StatefulWidget {
  final Map<String, dynamic>? preselectedTest;

  const BookTestScreen({super.key, this.preselectedTest});

  @override
  State<BookTestScreen> createState() => _BookTestScreenState();
}

class _BookTestScreenState extends State<BookTestScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _testId;
  final _dateCtl = TextEditingController();
  final _timeCtl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _testId = widget.preselectedTest?['id']?.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LaboratoryProvider>().loadTests();
    });
  }

  @override
  void dispose() {
    _dateCtl.dispose();
    _timeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LaboratoryProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: AppCard(
          maxWidth: 540,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book Lab Test', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Test *'),
                  value: _testId,
                  items: prov.tests.map((t) => DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text('${t['name']}  (\$${t['price']})', style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => _testId = v,
                  validator: (v) => v == null ? 'Required' : null,
                  style: const TextStyle(fontSize: 14),
                ),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTimeField(
                        controller: _timeCtl,
                        label: 'Time *',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: AppButton.primary('Book Test', isLoading: _loading, onPressed: _submit)),
                    const SizedBox(width: 12),
                    Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.pop(context))),
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
    final ok = await context.read<LaboratoryProvider>().bookTest({
      'lab_test_id': _testId,
      'scheduled_date': _dateCtl.text.trim(),
      'scheduled_time': _timeCtl.text.trim(),
    });
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pop(context);
    }
  }
}
