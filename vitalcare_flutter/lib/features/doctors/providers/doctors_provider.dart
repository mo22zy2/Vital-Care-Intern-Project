import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class DoctorsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _specialties = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';
  String _specialtyId = '';

  List<Map<String, dynamic>> get doctors => _filtered;
  List<Map<String, dynamic>> get specialties => _specialties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final specs = await ApiClient.get(ApiConstants.doctorSpecialties);
      _specialties = (specs['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final params = <String, String>{};
      if (_specialtyId.isNotEmpty) params['specialty_id'] = _specialtyId;
      final res = await ApiClient.get(ApiConstants.doctors, queryParams: params.isNotEmpty ? params : null);
      _allDoctors = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load doctors';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    _search = q.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void setSpecialty(String id) {
    _specialtyId = id;
    load();
  }

  void _applyFilter() {
    _filtered = _allDoctors.where((d) {
      final name = (d['full_name']?.toString() ?? '').toLowerCase();
      final matchesSearch = _search.isEmpty || name.contains(_search);
      return matchesSearch;
    }).toList();
  }
}
