import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';

class AdminLabTestsScreen extends StatefulWidget {
  const AdminLabTestsScreen({super.key});

  @override
  State<AdminLabTestsScreen> createState() => _AdminLabTestsScreenState();
}

class _AdminLabTestsScreenState extends State<AdminLabTestsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadLabTests();
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
              : prov.labTests.isEmpty
                  ? const EmptyState(icon: Icons.biotech, title: 'No lab tests found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prov.labTests.length,
                      itemBuilder: (_, i) => _card(prov.labTests[i], prov),
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
              decoration: const InputDecoration(hintText: 'Search lab tests...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              style: const TextStyle(fontSize: 14),
              onChanged: (q) { prov.setSearch(q); prov.loadLabTests(); },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showDialog(prov, null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Test'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> t, AdminProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.biotech, color: AppColors.info, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('\$${t['price'] ?? 0} · ${t['turnaround_hours'] ?? 0}h turnaround', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showDialog(prov, t);
                if (v == 'delete') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () { Navigator.pop(ctx); prov.deleteLabTest(t['id'].toString()); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), child: const Text('Delete')),
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

  void _showDialog(AdminProvider prov, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final priceCtl = TextEditingController(text: existing?['price']?.toString() ?? '');
    final turnaroundCtl = TextEditingController(text: existing?['turnaround_hours']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Lab Test' : 'Add Lab Test', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Test Name')),
              const SizedBox(height: 8),
              TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: turnaroundCtl, decoration: const InputDecoration(labelText: 'Turnaround (hours)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final body = {'name': nameCtl.text, 'price': priceCtl.text, 'turnaround_hours': turnaroundCtl.text};
              final ok = isEdit ? await prov.updateLabTest(existing['id'].toString(), body) : await prov.createLabTest(body);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Test saved' : 'Failed'), backgroundColor: ok ? AppColors.success : AppColors.danger));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
