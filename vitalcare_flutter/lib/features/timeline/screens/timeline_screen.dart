import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/timeline_provider.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimelineProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TimelineProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient Timeline', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.events.isEmpty
                  ? const EmptyState(icon: Icons.timeline, title: 'No timeline events')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prov.events.length,
                      itemBuilder: (context, i) {
                        final e = prov.events[i];
                        final type = e['type']?.toString() ?? '';
                        final color = _colorForType(type);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 40,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 14, height: 14,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
                                      ),
                                    ),
                                    if (i < prov.events.length - 1)
                                      Container(width: 2, height: 60, color: AppColors.borderLight),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(e['date']?.toString() ?? '',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                                          const Spacer(),
                                          AppBadge(label: type, color: color),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(e['description']?.toString() ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      if (e['status']?.toString().isNotEmpty == true) ...[
                                        const SizedBox(height: 4),
                                        Text(e['status'].toString(),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'APPOINTMENT': return AppColors.primary;
      case 'RECORD': return AppColors.accent;
      case 'PRESCRIPTION': return AppColors.success;
      case 'LAB_TEST': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }
}
