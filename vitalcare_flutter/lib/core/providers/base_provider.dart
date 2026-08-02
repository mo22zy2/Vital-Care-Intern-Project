import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> guard(Future<void> Function() action, {String? errorMessage}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ApiException ? e.message : (errorMessage ?? e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Map<String, dynamic>> unwrapList(dynamic response) {
    final data = response is Map ? response['data'] : null;
    return data is List ? data.cast<Map<String, dynamic>>() : const [];
  }
}
