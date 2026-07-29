import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';

class AdminMedicinesScreen extends StatefulWidget {
  const AdminMedicinesScreen({super.key});

  @override
  State<AdminMedicinesScreen> createState() => _AdminMedicinesScreenState();
}

class _AdminMedicinesScreenState extends State<AdminMedicinesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadMedicines();
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
        _toolbar(prov),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.medicines.isEmpty
                  ? const EmptyState(icon: Icons.medication, title: 'No medicines found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prov.medicines.length,
                      itemBuilder: (_, i) => _card(prov.medicines[i], prov),
                    ),
        ),
      ],
    );
  }

  Widget _toolbar(AdminProvider prov) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search medicines...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              style: const TextStyle(fontSize: 14),
              onChanged: (q) { prov.setSearch(q); prov.loadMedicines(); },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showMedicineDialog(prov, null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Medicine'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> m, AdminProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.medication, color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${m['dosage_form'] ?? ''} ${m['strength'] ?? ''} · Stock: ${m['stock_quantity'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AppBadge(label: (m['is_prescription_required'] == true) ? 'Rx' : 'OTC'),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showMedicineDialog(prov, m);
                if (v == 'delete') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () { Navigator.pop(ctx); prov.deleteMedicine(m['id'].toString()); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), child: const Text('Delete')),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicineDialog(AdminProvider prov, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final formCtl = TextEditingController(text: existing?['dosage_form']?.toString() ?? '');
    final strengthCtl = TextEditingController(text: existing?['strength']?.toString() ?? '');
    final stockCtl = TextEditingController(text: existing?['stock_quantity']?.toString() ?? '');
    final priceCtl = TextEditingController(text: existing?['price']?.toString() ?? '');
    bool rx = existing?['is_prescription_required'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Medicine' : 'Add Medicine', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: formCtl, decoration: const InputDecoration(labelText: 'Form', hintText: 'Tablet'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: strengthCtl, decoration: const InputDecoration(labelText: 'Strength', hintText: '500mg'))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: stockCtl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Prescription Required'),
                  value: rx,
                  onChanged: (v) => setDialogState(() => rx = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final body = {'name': nameCtl.text, 'dosage_form': formCtl.text, 'strength': strengthCtl.text, 'stock_quantity': stockCtl.text, 'price': priceCtl.text, 'is_prescription_required': rx};
                final ok = isEdit ? await prov.updateMedicine(existing['id'].toString(), body) : await prov.createMedicine(body);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Medicine saved' : 'Failed'), backgroundColor: ok ? AppColors.success : AppColors.danger));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
