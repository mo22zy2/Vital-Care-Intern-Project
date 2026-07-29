import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/feedback_provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String _targetType = 'DOCTOR';
  String? _doctorId;
  int _rating = 5;
  final _commentCtl = TextEditingController();
  bool _anonymous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<FeedbackProvider>();
      p.load();
      p.loadDoctors();
    });
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await context.read<FeedbackProvider>().submit({
      'target_type': _targetType,
      if (_doctorId != null) 'doctor_id': _doctorId,
      'rating': _rating,
      'comment': _commentCtl.text.trim(),
      'is_anonymous': _anonymous,
    });
    setState(() => _submitting = false);
    if (ok && mounted) {
      _commentCtl.clear();
      setState(() => _rating = 5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FeedbackProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppCard(
              maxWidth: 540,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Submit Feedback', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Target Type'),
                      value: _targetType,
                      items: ['DOCTOR', 'SERVICE', 'FACILITY'].map((t) => DropdownMenuItem(
                        value: t, child: Text(t, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (v) => setState(() => _targetType = v ?? 'DOCTOR'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_targetType == 'DOCTOR') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Doctor'),
                        items: prov.doctors.map((d) => DropdownMenuItem(
                          value: d['id'].toString(),
                          child: Text(d['full_name']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (v) => _doctorId = v,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          icon: Icon(
                            star <= _rating ? Icons.star : Icons.star_outline,
                            color: star <= _rating ? AppColors.warning : AppColors.border,
                          ),
                          onPressed: () => setState(() => _rating = star),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commentCtl,
                      decoration: const InputDecoration(labelText: 'Comment', hintText: 'Share your experience...'),
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _anonymous,
                      onChanged: (v) => setState(() => _anonymous = v ?? false),
                      title: const Text('Submit anonymously', style: TextStyle(fontSize: 13)),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    AppButton.primary('Submit Feedback', isLoading: _submitting, onPressed: _submit),
                    if (prov.error != null) ...[
                      const SizedBox(height: 8),
                      Text(prov.error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Feedback', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 16),
                prov.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.feedbackList.isEmpty
                        ? const Center(child: Text('No feedback yet', style: TextStyle(color: AppColors.textSecondary)))
                        : Column(
                            children: prov.feedbackList.map((f) => Container(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        AppBadge(label: f['target_type']?.toString() ?? '', color: AppColors.primary),
                                        const Spacer(),
                                        ...List.generate(5, (i) => Icon(
                                          i < (f['rating'] ?? 0) ? Icons.star : Icons.star_outline,
                                          size: 14, color: AppColors.warning,
                                        )),
                                      ],
                                    ),
                                    if (f['comment']?.toString().isNotEmpty == true) ...[
                                      const SizedBox(height: 8),
                                      Text(f['comment'].toString(), style: const TextStyle(fontSize: 13)),
                                    ],
                                    Text(f['created_at'].toString().substring(0, 10),
                                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
