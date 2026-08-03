import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/medical_records_provider.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalRecordsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MedicalRecordsProvider>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Flexible(
                child: Text('Medical Records', style: Theme.of(context).textTheme.displayMedium, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchCtl,
                  decoration: const InputDecoration(
                    hintText: 'Search diagnosis, doctor...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              : prov.records.isEmpty
                  ? const EmptyState(icon: Icons.folder_open, title: 'No medical records')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      itemCount: prov.records.length,
                      itemBuilder: (context, i) {
                        final r = prov.records[i];
                        final tests = (r['test_results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(r['record_date']?.toString() ?? '',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Dr. ${r['doctor_name'] ?? ''}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (r['diagnosis']?.toString().isNotEmpty == true) ...[
                                  Text('Diagnosis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                                  Text(r['diagnosis'].toString(), style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 8),
                                ],
                                if (r['treatment_plan']?.toString().isNotEmpty == true) ...[
                                  Text('Treatment Plan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                                  Text(r['treatment_plan'].toString(), style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 8),
                                ],
                                if (tests.isNotEmpty) ...[
                                  Text('${tests.length} Test(s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                                  ...tests.map((t) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.science, size: 14, color: AppColors.info),
                                        const SizedBox(width: 6),
                                        Text(t['test_name']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                                        const Spacer(),
                                        AppBadge(label: 'Ready', color: AppColors.success),
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
