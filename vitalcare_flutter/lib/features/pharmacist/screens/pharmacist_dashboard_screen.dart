import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/pharmacist_provider.dart';

class PharmacistDashboardScreen extends StatefulWidget {
  const PharmacistDashboardScreen({super.key});

  @override
  State<PharmacistDashboardScreen> createState() => _PharmacistDashboardScreenState();
}

class _PharmacistDashboardScreenState extends State<PharmacistDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacistProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PharmacistProvider>();

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());
    if (prov.error != null) return Center(child: Text(prov.error!, style: const TextStyle(color: AppColors.danger)));

    final d = prov.dashboard ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pharmacy Dashboard', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text('Manage orders and inventory', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = (constraints.maxWidth - 48) / 4;
              return Row(
                children: [
                  SizedBox(width: w, child: AppStatCard(label: 'Pending Orders', value: '${prov.pendingOrders.length}', icon: Icons.receipt_long, color: AppColors.warning)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Total Medicines', value: '${d['total_medicines'] ?? 0}', icon: Icons.medication, color: AppColors.primary)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Low Stock', value: '${prov.lowStockMedicines.length}', icon: Icons.inventory, color: AppColors.danger)),
                  const SizedBox(width: 16),
                  SizedBox(width: w, child: AppStatCard(label: 'Total Orders', value: '${d['total_orders'] ?? 0}', icon: Icons.check_circle, color: AppColors.success)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _pendingOrdersSection(prov),
          const SizedBox(height: 24),
          _lowStockSection(prov),
        ],
      ),
    );
  }

  Widget _pendingOrdersSection(PharmacistProvider prov) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Pending Orders', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
              const Spacer(),
              Text('${prov.pendingOrders.length} orders', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          if (prov.pendingOrders.isEmpty)
            const EmptyState(icon: Icons.checklist, title: 'No pending orders')
          else
            ...prov.pendingOrders.take(5).map((o) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.receipt, color: AppColors.warning, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${o['patient_name']?.toString() ?? 'Patient'}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        Text('${o['items'] is List ? (o['items'] as List).map((i) => '${i['medicine']} x${i['quantity']}').join(', ') : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  AppBadge(label: o['status']?.toString() ?? ''),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _fulfillOrder(prov, o['id'].toString()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Fulfill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _lowStockSection(PharmacistProvider prov) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Low Stock Alerts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
              const Spacer(),
              Text('${prov.lowStockMedicines.length} items', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          if (prov.lowStockMedicines.isEmpty)
            const EmptyState(icon: Icons.check_circle, title: 'All medicines in stock')
          else
            ...prov.lowStockMedicines.map((m) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.warning, color: AppColors.danger, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        Text('Stock: ${m['stock_quantity'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                      ],
                    ),
                  ),
                  Text('Reorder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: AppColors.accent),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Future<void> _fulfillOrder(PharmacistProvider prov, String id) async {
    final ok = await prov.fulfillOrder(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Order fulfilled' : 'Failed: ${prov.error}'),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }
}
