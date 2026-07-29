import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/prescriptions_provider.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PrescriptionsProvider>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Text('Prescriptions', style: Theme.of(context).textTheme.displayMedium),
              const Spacer(),
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
                    items: ['', 'ACTIVE', 'COMPLETED', 'DISCONTINUED']
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
        const SizedBox(height: 16),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.prescriptions.isEmpty
                  ? const EmptyState(icon: Icons.description, title: 'No prescriptions')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      itemCount: prov.prescriptions.length,
                      itemBuilder: (context, i) {
                        final p = prov.prescriptions[i];
                        final items = (p['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(p['date_prescribed']?.toString() ?? '',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    const Spacer(),
                                    AppBadge(label: p['status']?.toString() ?? ''),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Dr. ${p['doctor_name'] ?? ''}',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                if (p['notes']?.toString().isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Text(p['notes'].toString(), style: const TextStyle(fontSize: 12)),
                                ],
                                if (items.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...items.map((item) => Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.medication, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text('${item['medicine'] ?? ''} — ${item['dosage'] ?? ''}',
                                              style: const TextStyle(fontSize: 12)),
                                        ),
                                        Text('${item['quantity']}  x  ${item['duration_days']}d',
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  )),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
