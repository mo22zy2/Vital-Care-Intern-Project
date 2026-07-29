import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PrescriptionsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';

  List<Map<String, dynamic>> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
      final res = await ApiClient.get(ApiConstants.prescriptions, queryParams: params.isNotEmpty ? params : null);
      _prescriptions = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load prescriptions';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    load();
  }
}
