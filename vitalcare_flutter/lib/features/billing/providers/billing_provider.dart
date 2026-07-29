import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class BillingProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';
  String _search = '';

  List<Map<String, dynamic>> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
      if (_search.isNotEmpty) params['q'] = _search;
      final res = await ApiClient.get(ApiConstants.invoices, queryParams: params.isNotEmpty ? params : null);
      _invoices = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load invoices';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    load();
  }

  void setSearch(String q) {
    _search = q;
    load();
  }
}
