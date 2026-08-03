import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
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

  Future<void> _requestRefill(String itemId) async {
    final prov = context.read<PrescriptionsProvider>();
    final ok = await prov.requestRefill(itemId);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refill requested — pending pharmacy approval')),
      );
    }
  }

  void _showRefills() {
    final prov = context.read<PrescriptionsProvider>();
    prov.loadRefills();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Consumer<PrescriptionsProvider>(
          builder: (context, p, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text('Refill History', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: p.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : p.refills.isEmpty
                        ? const EmptyState(icon: Icons.refresh, title: 'No refill requests yet')
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: p.refills.length,
                            itemBuilder: (context, i) {
                              final r = p.refills[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Requested: ${r['requested_at']?.toString().substring(0, 10) ?? ''}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            if (r['fulfilled_at'] != null)
                                              Text('Fulfilled: ${r['fulfilled_at'].toString().substring(0, 10)}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      AppBadge(label: r['status']?.toString() ?? ''),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<PrescriptionsProvider>();
      p.load();
      p.loadRefills();
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
              Flexible(
                child: Text('Prescriptions',
                    style: Theme.of(context).textTheme.displayMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showRefills,
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Refills', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    items: ['', 'ACTIVE', 'COMPLETED', 'CANCELLED']
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
                                          child: Text('${item['medicine_name'] ?? ''} — ${item['dosage'] ?? ''}',
                                              style: const TextStyle(fontSize: 12)),
                                        ),
                                        Text('${item['quantity']}  x  ${item['duration_days']}d',
                                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        if (p['status']?.toString() == 'ACTIVE')
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: SizedBox(
                                              height: 28,
                                              child: AppButton.primary('Refill', expanded: false,
                                                  onPressed: () => _requestRefill(item['id'].toString())),
                                            ),
                                          ),
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
