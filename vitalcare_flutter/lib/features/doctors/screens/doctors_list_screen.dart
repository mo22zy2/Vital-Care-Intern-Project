import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/doctors_provider.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DoctorsProvider>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtl,
                  decoration: const InputDecoration(
                    hintText: 'Search doctors...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) => prov.setSearch(v),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: null,
                    hint: const Text('All Specialties', style: TextStyle(fontSize: 13)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Specialties', style: TextStyle(fontSize: 13))),
                      ...prov.specialties.map((s) => DropdownMenuItem(
                        value: s['id'].toString(),
                        child: Text(s['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                      )),
                    ],
                    onChanged: (v) => prov.setSpecialty(v ?? ''),
                    isDense: true,
                    underline: const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.error != null
                  ? Center(child: Text(prov.error!, style: const TextStyle(color: AppColors.danger)))
                  : prov.doctors.isEmpty
                      ? const EmptyState(icon: Icons.medical_services, title: 'No doctors found')
                      : RefreshIndicator(
                          onRefresh: prov.load,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth < 560 ? 1 : 2;
                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  childAspectRatio: columns == 1 ? 4.2 : 2.2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: prov.doctors.length,
                                itemBuilder: (context, i) => _doctorCard(prov.doctors[i]),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _doctorCard(Map<String, dynamic> d) {
    final name = d['full_name']?.toString() ?? 'Dr. Unknown';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    final specialties = (d['specialties'] as List?)?.cast<String>() ?? [];
    final fee = d['consultation_fee']?.toString() ?? '';
    final exp = d['years_of_experience']?.toString() ?? '';

    return AppCard(
      child: InkWell(
        onTap: () => context.push('/doctors/${d['id']}', extra: d),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(initials, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: specialties.map((s) => AppBadge(label: s, color: AppColors.info)).toList(),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.school, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('$exp yrs', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        Icon(Icons.attach_money, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('E£$fee', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton.primary('Book', expanded: false, onPressed: () => context.push('/appointments/book', extra: d)),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => context.push('/doctors/${d['id']}', extra: d),
                    child: const Text('Profile', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
