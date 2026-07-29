import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class LabtechProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboard = await ApiClient.get(ApiConstants.labDashboard);
      final params = <String, String>{};
      if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
      final res = await ApiClient.get(ApiConstants.labBookings, queryParams: params.isNotEmpty ? params : null);
      _bookings = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dashboard';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    loadDashboard();
  }

  Future<bool> updateBookingStatus(String id, String status, {Map<String, dynamic>? resultData}) async {
    try {
      await ApiClient.patch('${ApiConstants.labBookings}/$id', body: {'status': status, if (resultData != null) ...resultData});
      await loadDashboard();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
