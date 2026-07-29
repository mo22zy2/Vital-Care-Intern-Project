import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class NotificationsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _healthTips = [];
  bool _isLoading = false;
  String? _error;
  String _typeFilter = '';
  String _search = '';

  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get healthTips => _healthTips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => n['is_read'] != true).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (_typeFilter.isNotEmpty) params['type'] = _typeFilter;
      if (_search.isNotEmpty) params['q'] = _search;
      final res = await ApiClient.get(ApiConstants.notifications, queryParams: params.isNotEmpty ? params : null);
      _notifications = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _healthTips = (res['health_tips'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load notifications';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    load();
  }

  void setSearch(String q) {
    _search = q;
    load();
  }

  Future<void> markRead(String id) async {
    try {
      await ApiClient.post('${ApiConstants.notifications}/mark-read', body: {'ids': [id]});
      await load();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.post('${ApiConstants.notifications}/mark-all-read');
      await load();
    } catch (_) {}
  }
}
