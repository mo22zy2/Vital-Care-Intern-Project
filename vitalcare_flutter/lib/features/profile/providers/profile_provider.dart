import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get profile => _profile;
  List<Map<String, dynamic>> get emergencyContacts => _emergencyContacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.get(ApiConstants.profile);
      _profile = res;
      final ec = await ApiClient.get(ApiConstants.emergencyContacts);
      _emergencyContacts = (ec['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load profile';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> body) async {
    try {
      await ApiClient.patch(ApiConstants.profile, body: body);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addEmergencyContact(Map<String, dynamic> body) async {
    try {
      await ApiClient.post(ApiConstants.emergencyContacts, body: body);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmergencyContact(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.emergencyContacts}/$id');
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }
}
