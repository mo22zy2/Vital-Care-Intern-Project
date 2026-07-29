import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PharmacyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';
  String _rxFilter = '';

  List<Map<String, dynamic>> get medicines => _medicines;
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (_search.isNotEmpty) params['search'] = _search;
      final res = await ApiClient.get(ApiConstants.medicines, queryParams: params.isNotEmpty ? params : null);
      _medicines = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load medicines';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.pharmacyOrders);
      _orders = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load orders';
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<String?> createOrder(List<MapEntry<String, int>> items) async {
    try {
      final body = {
        'items': items.map((e) => {'medicine_id': e.key, 'quantity': e.value}).toList(),
      };
      final res = await ApiClient.post(ApiConstants.pharmacyOrders, body: body);
      await loadOrders();
      return res['id']?.toString();
    } catch (e) {
      return e.toString();
    }
  }
}
