import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class LaboratoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get tests => _tests;
  List<Map<String, dynamic>> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.labTests);
      _tests = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load lab tests';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.labBookings);
      _bookings = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load bookings';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bookTest(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.labBookings, body: body);
      await loadBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
