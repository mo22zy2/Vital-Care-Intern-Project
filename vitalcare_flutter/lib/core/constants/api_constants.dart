import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const String _definedApiBase = String.fromEnvironment('API_BASE_URL');
  static const String _definedRagBase = String.fromEnvironment('RAG_BASE_URL');

  static String get baseUrl {
    if (_definedApiBase.isNotEmpty) return _definedApiBase;
    return kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8081';
  }

  static String get ragBaseUrl {
    if (_definedRagBase.isNotEmpty) return _definedRagBase;
    return kIsWeb ? 'http://localhost:9000' : 'http://10.0.2.2:9000';
  }

  static const int ragProjectId = 21;
  static String get ragAnswer => '/api/v1/nlp/index/answer/$ragProjectId';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String patientDashboard = '/accounts/dashboard';
  static const String patientTimeline = '/accounts/timeline';
  static const String profile = '/accounts/me';
  static const String changePassword = '/accounts/me/password';
  static const String requestOtp = '/accounts/request-otp';
  static const String verifyOtp = '/accounts/verify-otp';

  static const String doctors = '/doctors';
  static const String doctorSpecialties = '/doctors/specialties';
  static const String doctorDashboard = '/doctors/me/dashboard';
  static const String doctorAppointments = '/doctors/me/appointments';
  static const String doctorAvailability = '/doctors/me/availability';

  static const String appointments = '/appointments';

  static const String medicines = '/pharmacy/medicines';
  static const String pharmacyOrders = '/pharmacy/orders';
  static const String pharmacyDashboard = '/pharmacy/dashboard';

  static const String labTests = '/laboratory/tests';
  static const String labBookings = '/laboratory/bookings';
  static const String labDashboard = '/laboratory/dashboard';

  static const String invoices = '/billing/invoices';
  static const String payments = '/payments/payments';
  static const String chatAsk = '/chat/ask';
  static const String medicalRecords = '/medical-records';
  static const String prescriptions = '/prescriptions';
  static const String notifications = '/notifications';
  static const String feedback = '/feedback';
  static const String insuranceProviders = '/insurance/providers';
  static const String insurancePolicies = '/insurance/policies';
  static const String insuranceClaims = '/insurance/claims';
  static const String emergencyContacts = '/emergency-contacts';
  static const String search = '/search';

  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminAppointments = '/admin/appointments';
  static const String adminDoctors = '/admin/doctors';
  static const String adminMedicines = '/admin/medicines';
  static const String adminLabTests = '/admin/lab-tests';
  static const String adminInvoices = '/admin/invoices';
  static const String adminPharmacyOrders = '/admin/pharmacy-orders';
  static const String adminFeedback = '/admin/feedback';
  static const String adminReports = '/admin/reports';
}
