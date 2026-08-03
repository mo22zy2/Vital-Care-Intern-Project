import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class InsuranceProvider extends BaseProvider {
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _policies = [];
  List<Map<String, dynamic>> _claims = [];
  List<Map<String, dynamic>> _invoices = [];

  List<Map<String, dynamic>> get providers => _providers;
  List<Map<String, dynamic>> get policies => _policies;
  List<Map<String, dynamic>> get claims => _claims;
  List<Map<String, dynamic>> get invoices => _invoices;

  Future<void> load() => guard(() async {
        _providers = unwrapList(await ApiClient.get(ApiConstants.insuranceProviders));
        _policies = unwrapList(await ApiClient.get(ApiConstants.insurancePolicies));
        _claims = unwrapList(await ApiClient.get(ApiConstants.insuranceClaims));
      }, errorMessage: 'Failed to load insurance data');

  Future<void> loadInvoices() => guard(() async {
        _invoices = unwrapList(await ApiClient.get(ApiConstants.invoices));
      }, errorMessage: 'Failed to load invoices');

  Future<bool> addPolicy(Map<String, dynamic> body) => guard(() async {
        await ApiClient.post(ApiConstants.insurancePolicies, body: body);
        await load();
      });

  Future<bool> submitClaim(Map<String, dynamic> body) => guard(() async {
        await ApiClient.post(ApiConstants.insuranceClaims, body: body);
        await load();
      });
}
