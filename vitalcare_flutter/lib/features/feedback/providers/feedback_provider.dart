import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class FeedbackProvider extends BaseProvider {
  List<Map<String, dynamic>> _feedbackList = [];
  List<Map<String, dynamic>> _doctors = [];

  List<Map<String, dynamic>> get feedbackList => _feedbackList;
  List<Map<String, dynamic>> get doctors => _doctors;

  Future<void> load() async {
    setLoading(true);
    try {
      _feedbackList = unwrapList(await ApiClient.get(ApiConstants.feedback));
    } catch (_) {
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadDoctors() async {
    try {
      _doctors = unwrapList(await ApiClient.get(ApiConstants.doctors));
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> submit(Map<String, dynamic> body) => guard(() async {
        await ApiClient.post(ApiConstants.feedback, body: body);
        await load();
      });
}
