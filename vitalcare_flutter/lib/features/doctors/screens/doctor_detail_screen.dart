import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class DoctorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final name = doctor['full_name']?.toString() ?? 'Dr. Unknown';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    final specialties = (doctor['specialties'] as List?)?.cast<String>() ?? [];
    final bio = doctor['bio']?.toString() ?? '';
    final fee = doctor['consultation_fee']?.toString() ?? '';
    final exp = doctor['years_of_experience']?.toString() ?? '';
    final license = doctor['license_number']?.toString() ?? '';
    final location = doctor['office_location']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 720;
              final infoCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Professional Info', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text,
                    )),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(initials, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 24)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: specialties.map((s) => AppBadge(label: s, color: AppColors.info)).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _infoRow(Icons.badge, 'License', license),
                    _infoRow(Icons.school, 'Experience', '$exp years'),
                    _infoRow(Icons.attach_money, 'Consultation Fee', 'E£$fee'),
                    _infoRow(Icons.location_on, 'Location', location),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const SizedBox(height: 6),
                      Text(bio, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                    ],
                  ],
                ),
              );
              final bookingCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Appointments', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text,
                    )),
                    const SizedBox(height: 20),
                    Text('Working Hours', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._workingHours(),
                    const SizedBox(height: 16),
                    AppButton.accent('Book Appointment', onPressed: () => context.push('/appointments/book', extra: doctor)),
                  ],
                ),
              );
              if (stack) {
                return Column(
                  children: [
                    infoCard,
                    const SizedBox(height: 20),
                    bookingCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: infoCard),
                  const SizedBox(width: 20),
                  Expanded(child: bookingCard),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _workingHours() {
    final avail = (doctor['availability'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (avail.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.hover, borderRadius: BorderRadius.circular(8)),
          child: const Text('No working hours configured',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      ];
    }
    return avail.map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text('${s['weekday_name'] ?? ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text('${s['start_time'] ?? ''} – ${s['end_time'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    )).toList();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
