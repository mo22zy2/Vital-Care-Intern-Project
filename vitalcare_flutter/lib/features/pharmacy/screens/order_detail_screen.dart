import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final id = order['id']?.toString() ?? '';
    final status = order['status']?.toString() ?? '';
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Order Detail', style: Theme.of(context).textTheme.displayMedium),
              const Spacer(),
              AppBadge(label: status, color: AppBadge.colorFor(status)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Order #$id', style: TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono', color: AppColors.textMuted)),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.bg, border: Border(bottom: BorderSide(color: AppColors.borderLight))),
                  child: Row(
                    children: [
                      Expanded(child: _th('Medicine')),
                      _th('Price', width: 80),
                      _th('Qty', width: 60),
                      _th('Subtotal', width: 80, align: TextAlign.right),
                    ],
                  ),
                ),
                ...items.map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
                  child: Row(
                    children: [
                      Expanded(child: Text(item['medicine']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                      _td(money(item['unit_price']), width: 80, mono: true),
                      _td('${item['quantity']}', width: 60),
                      _td(money(item['line_total']), width: 80, align: TextAlign.right, mono: true),
                    ],
                  ),
                )),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Total: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const SizedBox(width: 8),
                      Text(money(order['total']), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'JetBrains Mono')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _th(String label, {double? width, TextAlign align = TextAlign.start}) => SizedBox(
        width: width,
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted), textAlign: align),
      );

  Widget _td(String text, {double? width, TextAlign align = TextAlign.start, bool mono = false}) => SizedBox(
        width: width,
        child: Text(text, style: TextStyle(fontSize: 13, fontFamily: mono ? 'JetBrains Mono' : null), textAlign: align),
      );
}
