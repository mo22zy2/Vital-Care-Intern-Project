import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class PharmacyProvider extends BaseProvider {
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _orders = [];
  String _search = '';
  String _rxFilter = '';

  List<Map<String, dynamic>> get medicines => _medicines;
  List<Map<String, dynamic>> get orders => _orders;

  Future<void> loadMedicines() => guard(() async {
        final params = <String, String>{};
        if (_search.isNotEmpty) params['search'] = _search;
        final res = await ApiClient.get(ApiConstants.medicines, queryParams: params.isNotEmpty ? params : null);
        _medicines = unwrapList(res);
      }, errorMessage: 'Failed to load medicines');

  Future<void> loadOrders() => guard(() async {
        _orders = unwrapList(await ApiClient.get(ApiConstants.pharmacyOrders));
      }, errorMessage: 'Failed to load orders');

  void setSearch(String q) {
    _search = q;
    loadMedicines();
  }

  bool get prescriptionFilter => _rxFilter == 'rx';
  bool get otcFilter => _rxFilter == 'otc';

  void toggleRxFilter() {
    _rxFilter = _rxFilter == 'rx' ? '' : 'rx';
    loadMedicines();
  }

  void toggleOtcFilter() {
    _rxFilter = _rxFilter == 'otc' ? '' : 'otc';
    loadMedicines();
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> createOrder(List<MapEntry<String, int>> items) async {
    try {
      final body = {
        'items': items.map((e) => {'medicine_id': e.key, 'quantity': e.value}).toList(),
      };
      await ApiClient.post(ApiConstants.pharmacyOrders, body: body);
      await loadOrders();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
