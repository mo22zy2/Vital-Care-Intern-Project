import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AdminProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _labTests = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _feedback = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = '';
  String _search = '';

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get appointments => _appointments;
  List<Map<String, dynamic>> get doctors => _doctors;
  List<Map<String, dynamic>> get medicines => _medicines;
  List<Map<String, dynamic>> get labTests => _labTests;
  List<Map<String, dynamic>> get invoices => _invoices;
  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get feedback => _feedback;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboard = await ApiClient.get(ApiConstants.adminDashboard);
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
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  Map<String, String> get _queryParams {
    final params = <String, String>{};
    if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
    if (_search.isNotEmpty) params['q'] = _search;
    return params;
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminUsers, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _users = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.adminUsers, body: body);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> body) async {
    try {
      await ApiClient.patch('${ApiConstants.adminUsers}/$id', body: body);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.adminUsers}/$id');
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminAppointments, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _appointments = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctors() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminDoctors, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _doctors = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDoctor(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.adminDoctors, body: body);
      await loadDoctors();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDoctor(String id, Map<String, dynamic> body) async {
    try {
      await ApiClient.patch('${ApiConstants.adminDoctors}/$id', body: body);
      await loadDoctors();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDoctor(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.adminDoctors}/$id');
      await loadDoctors();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminMedicines, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _medicines = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMedicine(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.adminMedicines, body: body);
      await loadMedicines();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedicine(String id, Map<String, dynamic> body) async {
    try {
      await ApiClient.patch('${ApiConstants.adminMedicines}/$id', body: body);
      await loadMedicines();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.adminMedicines}/$id');
      await loadMedicines();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadLabTests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminLabTests, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _labTests = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLabTest(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.adminLabTests, body: body);
      await loadLabTests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLabTest(String id, Map<String, dynamic> body) async {
    try {
      await ApiClient.patch('${ApiConstants.adminLabTests}/$id', body: body);
      await loadLabTests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLabTest(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.adminLabTests}/$id');
      await loadLabTests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminInvoices, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _invoices = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminPharmacyOrders, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _orders = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeedback() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.adminFeedback, queryParams: _queryParams.isNotEmpty ? _queryParams : null);
      _feedback = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();
    try {
      _dashboard = await ApiClient.get(ApiConstants.adminReports);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteFeedback(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.adminFeedback}/$id');
      await loadFeedback();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      await ApiClient.patch('${ApiConstants.adminPharmacyOrders}/$id', body: {'status': status});
      await loadOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInvoiceStatus(String id, String status) async {
    try {
      await ApiClient.patch('${ApiConstants.adminInvoices}/$id', body: {'status': status});
      await loadInvoices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
