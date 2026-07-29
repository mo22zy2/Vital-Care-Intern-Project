import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AppointmentsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _specialties = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';
  String _search = '';

  List<Map<String, dynamic>> get appointments => _appointments;
  List<Map<String, dynamic>> get doctors => _doctors;
  List<Map<String, dynamic>> get specialties => _specialties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
      if (_search.isNotEmpty) params['q'] = _search;
      final res = await ApiClient.get(ApiConstants.appointments, queryParams: params.isNotEmpty ? params : null);
      _appointments = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load appointments';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctorsAndSpecialties() async {
    try {
      final specs = await ApiClient.get(ApiConstants.doctorSpecialties);
      _specialties = (specs['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final docs = await ApiClient.get(ApiConstants.doctors);
      _doctors = (docs['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      notifyListeners();
    } catch (_) {}
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    loadAppointments();
  }

  void setSearch(String q) {
    _search = q;
    loadAppointments();
  }

  Future<bool> bookAppointment(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.appointments, body: body);
      await loadAppointments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelAppointment(String id, String reason) async {
    try {
      await ApiClient.patch('${ApiConstants.appointments}/$id/cancel', body: {'cancellation_reason': reason});
      await loadAppointments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
