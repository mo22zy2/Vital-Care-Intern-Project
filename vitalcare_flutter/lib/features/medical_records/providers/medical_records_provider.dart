import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class MedicalRecordsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';

  List<Map<String, dynamic>> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (_search.isNotEmpty) params['q'] = _search;
      final res = await ApiClient.get(ApiConstants.medicalRecords, queryParams: params.isNotEmpty ? params : null);
      _records = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load records';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    _search = q;
    load();
  }
}
