import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class FeedbackProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _feedbackList = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get feedbackList => _feedbackList;
  List<Map<String, dynamic>> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.feedback);
      _feedbackList = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctors() async {
    try {
      final res = await ApiClient.get(ApiConstants.doctors);
      _doctors = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> submit(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.feedback, body: body);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
