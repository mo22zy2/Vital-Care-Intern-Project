import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const AppBadge({super.key, required this.label, this.color});

  static Color colorFor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'DELIVERED':
      case 'ACTIVE':
      case 'PAID':
      case 'SUCCESS':
      case 'VERIFIED':
      case 'APPROVED':
      case 'FULFILLED':
      case 'CONFIRMED':
      case 'YES':
        return AppColors.success;
      case 'PENDING':
      case 'BOOKED':
      case 'REQUESTED':
      case 'SUBMITTED':
      case 'UNPAID':
      case 'PROCESSING':
        return AppColors.warning;
      case 'CANCELLED':
      case 'NO_SHOW':
      case 'REJECTED':
      case 'DENIED':
      case 'DISCONTINUED':
      case 'EXPIRED':
      case 'OVERDUE':
      case 'NO':
        return AppColors.danger;
      case 'IN_PROGRESS':
      case 'SAMPLE_COLLECTED':
      case 'READY_FOR_PICKUP':
      case 'UNDER_REVIEW':
      case 'RESULT_READY':
        return AppColors.info;
      case 'DOCTOR':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? colorFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
      ),
    );
  }
}
