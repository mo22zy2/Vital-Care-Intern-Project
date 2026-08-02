import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/billing_provider.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _searchCtl = TextEditingController();
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillingProvider>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Text('Billing', style: Theme.of(context).textTheme.displayMedium),
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
                    items: ['', 'PAID', 'UNPAID', 'OVERDUE', 'CANCELLED']
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
              const SizedBox(width: 8),
              SizedBox(
                width: 200,
                height: 38,
                child: TextField(
                  controller: _searchCtl,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => prov.setSearch(v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.invoices.isEmpty
                  ? const EmptyState(icon: Icons.receipt_long, title: 'No invoices found')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      itemCount: prov.invoices.length,
                      itemBuilder: (context, i) {
                        final inv = prov.invoices[i];
                        final items = (inv['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                        final isOverdue = inv['status']?.toString() == 'OVERDUE';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AppCard(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isOverdue ? AppColors.danger.withValues(alpha: 0.04) : null,
                                    border: isOverdue ? Border.all(color: AppColors.danger.withValues(alpha: 0.2), width: 0) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(inv['invoice_number']?.toString() ?? '',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'JetBrains Mono')),
                                      const SizedBox(width: 8),
                                      Text('${inv['issue_date']}  →  ${inv['due_date']}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      const Spacer(),
                                      AppBadge(label: inv['status']?.toString() ?? ''),
                                    ],
                                  ),
                                ),
                                ...items.map((item) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderLight))),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(item['description']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 12))),
                                      Text('x${item['quantity']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      const SizedBox(width: 12),
                                      Text('\$${item['line_total']}', style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'JetBrains Mono', color: AppColors.text,
                                      )),
                                    ],
                                  ),
                                )),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: AppColors.borderLight)),
                                    color: AppColors.bg,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('Total: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                                      const SizedBox(width: 8),
                                      Text('\$${inv['total_amount'] ?? inv['subtotal'] ?? '0'}',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                              color: isOverdue ? AppColors.danger : AppColors.primary,
                                              fontFamily: 'JetBrains Mono')),
                                    ],
                                  ),
                                ),
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
