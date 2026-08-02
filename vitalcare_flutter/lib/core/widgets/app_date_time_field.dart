import 'package:flutter/material.dart';

class AppDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onChanged;

  const AppDateField({
    super.key,
    required this.controller,
    required this.label,
    this.firstDate,
    this.lastDate,
    this.validator,
    this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text) ?? now;
    final minDate = firstDate ?? DateTime(now.year - 120);
    final maxDate = lastDate ?? DateTime(now.year + 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(minDate) ? minDate : (initial.isAfter(maxDate) ? maxDate : initial),
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) {
      controller.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pick(context),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
      ),
      validator: validator,
    );
  }
}

class AppTimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onChanged;

  const AppTimeField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pick(context),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time, size: 16),
      ),
      validator: validator,
    );
  }
}
