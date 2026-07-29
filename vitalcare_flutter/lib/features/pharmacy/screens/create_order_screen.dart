import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/pharmacy_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _items = <_OrderItemRow>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addItem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacyProvider>().loadMedicines();
    });
  }

  void _addItem() {
    setState(() => _items.add(_OrderItemRow(medicineId: null, quantity: 1, key: UniqueKey())));
  }

  void _removeItem(int index) {
    if (_items.length > 1) setState(() => _items.removeAt(index));
  }

  Future<void> _submit() async {
    final entries = <MapEntry<String, int>>[];
    for (final item in _items) {
      if (item.medicineId == null) {
        setState(() => _error = 'Please select a medicine for all items');
        return;
      }
      entries.add(MapEntry(item.medicineId!, item.quantity));
    }
    setState(() => _loading = true);
    final prov = context.read<PharmacyProvider>();
    final result = await prov.createOrder(entries);
    setState(() => _loading = false);
    if (result != null && mounted) {
      context.pop();
      context.push('/pharmacy/orders');
    } else if (mounted) {
      setState(() => _error = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PharmacyProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: AppCard(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('New Pharmacy Order', style: Theme.of(context).textTheme.displayMedium),
                  const Spacer(),
                  TextButton(onPressed: () => context.pop(), child: const Text('← Back to Pharmacy')),
                ],
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              ..._items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: item.medicineId,
                          decoration: const InputDecoration(labelText: 'Medicine'),
                          items: prov.medicines.map((m) => DropdownMenuItem(
                            value: m['id'].toString(),
                            child: Text('${m['name']}  (Stock: ${m['stock_quantity']})', style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (v) => item.medicineId = v,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: item.quantity.toString(),
                          decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => item.quantity = int.tryParse(v) ?? 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                        onPressed: () => _removeItem(i),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Another Medicine'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: AppButton.primary('Place Order', isLoading: _loading, onPressed: _submit)),
                  const SizedBox(width: 12),
                  Expanded(child: AppButton.outline('Cancel', onPressed: () => context.pop())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItemRow {
  String? medicineId;
  int quantity;
  final Key key;

  _OrderItemRow({this.medicineId, this.quantity = 1, required this.key});
}
