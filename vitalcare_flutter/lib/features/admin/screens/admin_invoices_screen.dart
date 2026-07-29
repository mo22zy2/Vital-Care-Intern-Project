import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';

class AdminInvoicesScreen extends StatefulWidget {
  const AdminInvoicesScreen({super.key});

  @override
  State<AdminInvoicesScreen> createState() => _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    return Column(
      children: [
        _filterBar(prov),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.invoices.isEmpty
                  ? const EmptyState(icon: Icons.receipt_long, title: 'No invoices found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prov.invoices.length,
                      itemBuilder: (_, i) => _card(prov.invoices[i], prov),
                    ),
        ),
      ],
    );
  }

  Widget _filterBar(AdminProvider prov) {
    final filters = ['', 'paid', 'unpaid', 'overdue', 'cancelled'];
    final labels = {'': 'All', 'paid': 'Paid', 'unpaid': 'Unpaid', 'overdue': 'Overdue', 'cancelled': 'Cancelled'};
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Search invoices...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                style: const TextStyle(fontSize: 14),
                onChanged: (q) { prov.setSearch(q); prov.loadInvoices(); },
              ),
            ),
            ...filters.map((f) {
              final active = prov.statusFilter == f;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () { prov.setStatusFilter(f); prov.loadInvoices(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: active ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? AppColors.primary : AppColors.border)),
                    child: Text(labels[f] ?? f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> inv, AdminProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.receipt, color: AppColors.warning, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice #${inv['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('\$${inv['total_amount'] ?? 0} · ${inv['patient_name'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AppBadge(label: inv['status']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }
}
