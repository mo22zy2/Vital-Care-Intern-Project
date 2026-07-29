import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDoctors();
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
              : prov.doctors.isEmpty
                  ? const EmptyState(icon: Icons.medical_services, title: 'No doctors found')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prov.doctors.length,
                      itemBuilder: (_, i) => _card(prov.doctors[i], prov),
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
              decoration: const InputDecoration(hintText: 'Search doctors...', prefixIcon: Icon(Icons.search, size: 18), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              style: const TextStyle(fontSize: 14),
              onChanged: (q) { prov.setSearch(q); prov.loadDoctors(); },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showDoctorDialog(prov, null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Doctor'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> d, AdminProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text((d['full_name']?.toString() ?? '?')[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['full_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${d['specialties'] ?? ''} · \$${d['consultation_fee'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showDoctorDialog(prov, d);
                if (v == 'delete') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () { Navigator.pop(ctx); prov.deleteDoctor(d['id'].toString()); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white), child: const Text('Delete')),
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

  void _showDoctorDialog(AdminProvider prov, Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final nameCtl = TextEditingController(text: existing?['full_name']?.toString() ?? '');
    final feeCtl = TextEditingController(text: existing?['consultation_fee']?.toString() ?? '');
    final specCtl = TextEditingController(text: existing?['specialties']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Doctor' : 'Add Doctor', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 8),
              TextField(controller: feeCtl, decoration: const InputDecoration(labelText: 'Consultation Fee'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: specCtl, decoration: const InputDecoration(labelText: 'Specialties (comma-separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = isEdit
                  ? await prov.updateDoctor(existing['id'].toString(), {'full_name': nameCtl.text, 'consultation_fee': feeCtl.text, 'specialties': specCtl.text})
                  : await prov.createDoctor({'full_name': nameCtl.text, 'consultation_fee': feeCtl.text, 'specialties': specCtl.text});
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Doctor saved' : 'Failed'), backgroundColor: ok ? AppColors.success : AppColors.danger));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
