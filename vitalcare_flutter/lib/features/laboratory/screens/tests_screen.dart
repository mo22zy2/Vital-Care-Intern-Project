import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/laboratory_provider.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<LaboratoryProvider>();
      p.loadTests();
      p.loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LaboratoryProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Tests', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 16),
                prov.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.tests.isEmpty
                        ? const EmptyState(icon: Icons.science, title: 'No tests available')
                        : AppCard(
                            padding: const EdgeInsets.all(0),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: prov.tests.length,
                              separatorBuilder: (_, _a) => Divider(height: 1, color: AppColors.borderLight),
                              itemBuilder: (context, i) {
                                final t = prov.tests[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                            const SizedBox(height: 2),
                                            Text(t['description']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1),
                                          ],
                                        ),
                                      ),
                                      Text('\$${t['price']}', style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        fontFamily: 'JetBrains Mono', color: AppColors.primary,
                                      )),
                                      const SizedBox(width: 8),
                                      AppBadge(label: '${t['turnaround_time_hours']}h', color: AppColors.info),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 32,
                                        child: AppButton.primary('Book', onPressed: () => context.push('/laboratory/book', extra: t)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Bookings', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 16),
                prov.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : prov.bookings.isEmpty
                        ? const EmptyState(icon: Icons.event_busy, title: 'No bookings yet')
                        : AppCard(
                            padding: const EdgeInsets.all(0),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: prov.bookings.length,
                              separatorBuilder: (_, _a) => Divider(height: 1, color: AppColors.borderLight),
                              itemBuilder: (context, i) {
                                final b = prov.bookings[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(b['test_name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                                            const SizedBox(height: 2),
                                            Text(b['scheduled_date']?.toString() ?? '', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      AppBadge(label: b['status']?.toString() ?? ''),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
