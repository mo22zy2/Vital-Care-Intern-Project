import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _searchCtl = TextEditingController();
  String _typeFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Notifications', style: Theme.of(context).textTheme.displayMedium),
              const Spacer(),
              if (prov.unreadCount > 0) ...[
                Text('${prov.unreadCount} unread', style: TextStyle(fontSize: 13, color: AppColors.accent)),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: prov.markAllRead,
                  child: const Text('Mark All Read', style: TextStyle(fontSize: 13)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _searchCtl,
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (v) => prov.setSearch(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _typeFilter.isEmpty ? null : _typeFilter,
                            hint: const Text('All Types', style: TextStyle(fontSize: 13)),
                            items: ['', 'APPOINTMENT_REMINDER', 'TEST_RESULT', 'BILLING', 'MEDICATION', 'GENERAL']
                                .map((t) => DropdownMenuItem(
                                      value: t.isEmpty ? null : t,
                                      child: Text(t.isEmpty ? 'All Types' : t.replaceAll('_', ' '), style: const TextStyle(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _typeFilter = v ?? '');
                              prov.setTypeFilter(_typeFilter);
                            },
                            isDense: true,
                            underline: const SizedBox(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                prov.isLoading
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : prov.notifications.isEmpty
                        ? const EmptyState(icon: Icons.notifications_none, title: 'No notifications')
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: prov.notifications.length,
                            separatorBuilder: (_, _a) => Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (context, i) {
                              final n = prov.notifications[i];
                              final isRead = n['is_read'] == true;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: isRead ? null : AppColors.info.withValues(alpha: 0.04),
                                child: Row(
                                  children: [
                                    Icon(
                                      _iconForType(n['notification_type']?.toString() ?? ''),
                                      size: 18,
                                      color: isRead ? AppColors.textMuted : AppColors.info,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(n['title']?.toString() ?? '',
                                              style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(n['message']?.toString() ?? '',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppBadge(label: n['notification_type']?.toString().replaceAll('_', ' ') ?? ''),
                                    if (!isRead) ...[
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 28,
                                        child: TextButton(
                                          onPressed: () => prov.markRead(n['id'].toString()),
                                          child: const Text('Mark Read', style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
          if (prov.healthTips.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Health Tips', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            ...prov.healthTips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppStatCard(
                icon: Icons.lightbulb,
                label: t['title']?.toString() ?? '',
                value: '',
                color: AppColors.info,
                subtitle: t['content']?.toString(),
              ),
            )),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'APPOINTMENT_REMINDER': return Icons.calendar_today;
      case 'TEST_RESULT': return Icons.science;
      case 'BILLING': return Icons.receipt;
      case 'MEDICATION': return Icons.medication;
      default: return Icons.notifications;
    }
  }
}
