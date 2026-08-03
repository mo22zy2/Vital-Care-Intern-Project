import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/billing_provider.dart';

class PayInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const PayInvoiceScreen({super.key, required this.invoice});

  @override
  State<PayInvoiceScreen> createState() => _PayInvoiceScreenState();
}

class _PayInvoiceScreenState extends State<PayInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  String _method = 'CREDIT_CARD';
  bool _loading = false;

  static const _methods = {
    'CREDIT_CARD': 'Credit Card',
    'DEBIT_CARD': 'Debit Card',
    'BANK_TRANSFER': 'Bank Transfer',
    'CASH': 'Cash',
    'INSURANCE': 'Insurance',
  };

  @override
  void initState() {
    super.initState();
    _amountCtl.text = widget.invoice['total_amount']?.toString() ?? '';
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: AppCard(
          maxWidth: 480,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pay Invoice', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(inv['invoice_number']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'JetBrains Mono')),
                    const Spacer(),
                    Text('Status: ${inv['status'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total due: E£${inv['total_amount'] ?? inv['subtotal'] ?? '0'}',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary,
                        fontFamily: 'JetBrains Mono')),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (E£) *'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final amt = double.tryParse(v.trim());
                    if (amt == null || amt <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Payment Method *'),
                  items: _methods.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (v) => _method = v ?? _method,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: AppButton.primary('Pay Now', isLoading: _loading, onPressed: _submit)),
                    const SizedBox(width: 12),
                    Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.pop(context))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await context.read<BillingProvider>().payInvoice(
          widget.invoice['id'].toString(),
          _method,
          _amountCtl.text.trim(),
        );
    setState(() => _loading = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful')),
      );
      Navigator.pop(context);
    }
  }
}
