import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class PharmacistProvider extends BaseProvider {
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _lowStockMedicines = [];

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get pendingOrders => _pendingOrders;
  List<Map<String, dynamic>> get lowStockMedicines => _lowStockMedicines;

  Map<String, dynamic> get dash => _dashboard ?? {};

  Future<void> loadDashboard() => guard(() async {
        _dashboard = await ApiClient.get(ApiConstants.pharmacyDashboard);
        _pendingOrders = (dash['pending_orders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _lowStockMedicines = (dash['low_stock'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }, errorMessage: 'Failed to load dashboard');

  Future<bool> fulfillOrder(String id) => guard(() async {
        await ApiClient.patch('${ApiConstants.pharmacyOrders}/$id/status', body: {'status': 'DELIVERED'});
        await loadDashboard();
      });
}
