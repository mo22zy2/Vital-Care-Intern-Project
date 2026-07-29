import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadOrders();
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
              : prov.orders.isEmpty
                  ? const EmptyState(icon: Icons.inventory, title: 'No orders found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prov.orders.length,
                      itemBuilder: (_, i) => _card(prov.orders[i], prov),
                    ),
        ),
      ],
    );
  }

  Widget _filterBar(AdminProvider prov) {
    final filters = ['', 'pending', 'fulfilled', 'cancelled'];
    final labels = {'': 'All', 'pending': 'Pending', 'fulfilled': 'Fulfilled', 'cancelled': 'Cancelled'};
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
                decoration: const InputDecoration(hintText: 'Search orders...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                style: const TextStyle(fontSize: 14),
                onChanged: (q) { prov.setSearch(q); prov.loadOrders(); },
              ),
            ),
            ...filters.map((f) {
              final active = prov.statusFilter == f;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () { prov.setStatusFilter(f); prov.loadOrders(); },
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

  Widget _card(Map<String, dynamic> o, AdminProvider prov) {
    final status = o['status']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.inventory, color: AppColors.success, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${o['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(o['patient_name']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AppBadge(label: status),
            if (status == 'pending') ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _updateStatus(prov, o['id'].toString(), 'fulfilled'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                child: const Text('Fulfill', style: TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(AdminProvider prov, String id, String status) async {
    final ok = await prov.updateOrderStatus(id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Status updated' : 'Failed'), backgroundColor: ok ? AppColors.success : AppColors.danger),
      );
    }
  }
}
