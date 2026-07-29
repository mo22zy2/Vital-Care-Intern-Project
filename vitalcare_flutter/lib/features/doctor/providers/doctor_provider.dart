import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class DoctorProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';
  String _search = '';

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get appointments => _appointments;
  List<Map<String, dynamic>> get availability => _availability;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboard = await ApiClient.get(ApiConstants.doctorDashboard);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dashboard';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
      if (_search.isNotEmpty) params['q'] = _search;
      final res = await ApiClient.get(ApiConstants.doctorAppointments, queryParams: params.isNotEmpty ? params : null);
      _appointments = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load appointments';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailability() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.doctorAvailability);
      _availability = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load availability';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    loadAppointments();
  }

  void setSearch(String q) {
    _search = q;
    loadAppointments();
  }

  Future<bool> updateAppointmentStatus(String id, String status) async {
    try {
      await ApiClient.patch('${ApiConstants.doctorAppointments}/$id', body: {'status': status});
      await loadAppointments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveAvailability(List<Map<String, dynamic>> slots) async {
    try {
      await ApiClient.post(ApiConstants.doctorAvailability, body: {'slots': slots});
      await loadAvailability();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAvailabilitySlot(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.doctorAvailability}/$id');
      await loadAvailability();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
