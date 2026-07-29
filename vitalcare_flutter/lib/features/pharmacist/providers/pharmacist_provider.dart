import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PharmacistProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _lowStockMedicines = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get pendingOrders => _pendingOrders;
  List<Map<String, dynamic>> get lowStockMedicines => _lowStockMedicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboard = await ApiClient.get(ApiConstants.pharmacyDashboard);
      final ordersRes = await ApiClient.get(ApiConstants.pharmacyOrders, queryParams: {'status': 'pending'});
      _pendingOrders = (ordersRes['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final medsRes = await ApiClient.get(ApiConstants.medicines, queryParams: {'low_stock': 'true'});
      _lowStockMedicines = (medsRes['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dashboard';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fulfillOrder(String id) async {
    try {
      await ApiClient.patch('${ApiConstants.pharmacyOrders}/$id', body: {'status': 'fulfilled'});
      await loadDashboard();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
