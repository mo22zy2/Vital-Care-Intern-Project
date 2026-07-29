import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/pharmacy_provider.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacyProvider>().loadMedicines();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PharmacyProvider>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Text('Pharmacy', style: Theme.of(context).textTheme.displayMedium),
              const Spacer(),
              AppButton.accent('+ New Order', onPressed: () => context.push('/pharmacy/order/create')),
              const SizedBox(width: 8),
              AppButton.outline('My Orders', onPressed: () => context.push('/pharmacy/orders')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchCtl,
                  decoration: const InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) => prov.setSearch(v),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Rx Only', style: TextStyle(fontSize: 12)),
                selected: prov.prescriptionFilter,
                onSelected: (_) => prov.toggleRxFilter(),
                selectedColor: AppColors.warning.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('OTC', style: TextStyle(fontSize: 12)),
                selected: prov.otcFilter,
                onSelected: (_) => prov.toggleOtcFilter(),
                selectedColor: AppColors.success.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.medicines.isEmpty
                  ? const EmptyState(icon: Icons.medication, title: 'No medicines found')
                  : RefreshIndicator(
                      onRefresh: prov.loadMedicines,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: prov.medicines.length,
                        itemBuilder: (context, i) => _medicineCard(prov.medicines[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _medicineCard(Map<String, dynamic> m) {
    final name = m['name']?.toString() ?? '';
    final generic = m['generic_name']?.toString() ?? '';
    final dosage = m['dosage_form']?.toString() ?? '';
    final strength = m['strength']?.toString() ?? '';
    final price = m['price'];
    final stock = m['stock_quantity'] ?? 0;
    final rx = m['requires_prescription'] == true;
    final priceStr = price is num ? NumberFormat.currency(symbol: '\$').format(price) : '\$0';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1),
              ),
              AppBadge(label: rx ? 'Rx' : 'OTC', color: rx ? AppColors.warning : AppColors.success),
            ],
          ),
          if (generic.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(generic, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (dosage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(dosage, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
              if (strength.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(strength, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
              ],
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(priceStr, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary,
                fontFamily: 'JetBrains Mono',
              )),
              const Spacer(),
              Text('Stock: $stock', style: TextStyle(fontSize: 11, color: stock < 10 ? AppColors.danger : AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
