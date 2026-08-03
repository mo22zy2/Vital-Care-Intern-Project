import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';

class LabResultScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const LabResultScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final summary = booking['result_summary']?.toString() ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: AppCard(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Lab Result', style: Theme.of(context).textTheme.displayMedium),
                  const Spacer(),
                  AppBadge(label: booking['status']?.toString() ?? ''),
                ],
              ),
              const SizedBox(height: 8),
              Text(booking['test_name']?.toString() ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('${booking['scheduled_date']} at ${booking['scheduled_time']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Text('Result Summary',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.hover,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary,
                  style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.text),
                ),
              ),
              if (booking['released_at'] != null) ...[
                const SizedBox(height: 12),
                Text('Released: ${booking['released_at']?.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
