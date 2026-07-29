import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';
import '../providers/admin_provider.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadFeedback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    if (prov.isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: prov.feedback.length,
      itemBuilder: (_, i) => _card(prov.feedback[i], prov),
    );
  }

  Widget _card(Map<String, dynamic> f, AdminProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppBadge(label: f['target_type']?.toString() ?? ''),
                const Spacer(),
                ...List.generate(5, (j) => Icon(
                  j < (f['rating'] ?? 0) ? Icons.star : Icons.star_outline,
                  size: 14, color: AppColors.warning,
                )),
              ],
            ),
            if (f['comment']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(f['comment'].toString(), style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(f['user_name']?.toString() ?? 'Anonymous', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Feedback'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () { Navigator.pop(ctx); prov.deleteFeedback(f['id'].toString()); },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
