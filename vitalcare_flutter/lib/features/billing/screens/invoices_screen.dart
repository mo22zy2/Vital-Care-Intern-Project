import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
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

  void _showPayments() {
    final prov = context.read<BillingProvider>();
    prov.loadPayments();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Consumer<BillingProvider>(
          builder: (context, p, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text('Payment History', style: Theme.of(context).textTheme.titleLarge),
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
                    : p.payments.isEmpty
                        ? const EmptyState(icon: Icons.payments, title: 'No payments yet')
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: p.payments.length,
                            itemBuilder: (context, i) => _paymentRow(p.payments[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentRow(Map<String, dynamic> pm) {
    final paidAt = pm['paid_at']?.toString() ?? '';
    final paidDate = paidAt.length >= 10 ? paidAt.substring(0, 10) : paidAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18,
                color: pm['status'] == 'SUCCESS' ? AppColors.success : AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pm['invoice_number']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${pm['method']} · $paidDate',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text('E£${pm['amount']}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'JetBrains Mono')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillingProvider>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Billing', style: Theme.of(context).textTheme.displayMedium),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showPayments(),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Payments', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
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
                  Expanded(
                    child: SizedBox(
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
                  ),
                ],
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
                                      Flexible(
                                        child: Text('${inv['issue_date']}  →  ${inv['due_date']}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ),
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
                                      Text('E£${item['line_total']}', style: TextStyle(
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
                                      if (inv['status']?.toString() != 'PAID' && inv['status']?.toString() != 'CANCELLED') ...[
                                        AppButton.primary('Pay', expanded: false, onPressed: () {
                                          context.push('/billing/pay', extra: inv).then((_) => prov.load());
                                        }),
                                        const SizedBox(width: 12),
                                      ],
                                      Text('Total: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
                                      const SizedBox(width: 8),
                                      Text('E£${inv['total_amount'] ?? inv['subtotal'] ?? '0'}',
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
