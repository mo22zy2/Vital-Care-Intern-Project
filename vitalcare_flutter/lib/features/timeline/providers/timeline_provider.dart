import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class TimelineProvider extends BaseProvider {
  List<Map<String, dynamic>> _events = [];

  List<Map<String, dynamic>> get events => _events;

  Future<void> load() async {
    setLoading(true);
    try {
      _events = unwrapList(await ApiClient.get(ApiConstants.patientTimeline));
    } catch (_) {
    } finally {
      setLoading(false);
    }
  }
}
