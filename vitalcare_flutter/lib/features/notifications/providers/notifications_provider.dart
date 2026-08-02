import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class NotificationsProvider extends BaseProvider {
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _healthTips = [];
  String _typeFilter = '';
  String _search = '';

  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get healthTips => _healthTips;

  List<Map<String, dynamic>> get filteredNotifications {
    return _notifications.where((n) {
      if (_typeFilter.isNotEmpty && n['notification_type'] != _typeFilter) return false;
      if (_search.isNotEmpty) {
        final text = '${n['title']} ${n['message']}'.toLowerCase();
        if (!text.contains(_search.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  int get unreadCount => _notifications.where((n) => n['is_read'] != true).length;

  Future<void> load() => guard(() async {
        _notifications = unwrapList(await ApiClient.get(ApiConstants.notifications));
        _healthTips = unwrapList(await ApiClient.get('${ApiConstants.notifications}/health-tips'));
      }, errorMessage: 'Failed to load notifications');

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    try {
      await ApiClient.patch('${ApiConstants.notifications}/$id/read');
      await load();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.patch('${ApiConstants.notifications}/read-all');
      await load();
    } catch (_) {}
  }
}
