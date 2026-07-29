import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/pharmacy_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacyProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PharmacyProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order History', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 16),
          prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.orders.isEmpty
                  ? const EmptyState(icon: Icons.receipt_long, title: 'No orders yet', description: 'Place your first pharmacy order')
                  : AppCard(
                      padding: const EdgeInsets.all(0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prov.orders.length,
                        separatorBuilder: (_, _a) => Divider(height: 1, color: AppColors.borderLight),
                        itemBuilder: (context, i) {
                          final o = prov.orders[i];
                          final id = o['id']?.toString() ?? '';
                          final status = o['status']?.toString() ?? '';
                          final total = o['total']?.toString() ?? '';
                          final items = (o['items'] as List?) ?? [];
                          return ListTile(
                            onTap: () => context.push('/pharmacy/order/${id}', extra: o),
                            title: Text('#${id.substring(0, 8)}...', style: TextStyle(
                              fontSize: 13, fontFamily: 'JetBrains Mono', color: AppColors.text,
                            )),
                            subtitle: Text('${items.length} items', style: const TextStyle(fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\$$total', style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  fontFamily: 'JetBrains Mono',
                                )),
                                const SizedBox(width: 8),
                                AppBadge(label: status),
                                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
