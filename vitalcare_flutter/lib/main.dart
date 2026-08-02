import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/doctors/providers/doctors_provider.dart';
import 'features/appointments/providers/appointments_provider.dart';
import 'features/pharmacy/providers/pharmacy_provider.dart';
import 'features/laboratory/providers/laboratory_provider.dart';
import 'features/billing/providers/billing_provider.dart';
import 'features/medical_records/providers/medical_records_provider.dart';
import 'features/prescriptions/providers/prescriptions_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/timeline/providers/timeline_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/feedback/providers/feedback_provider.dart';
import 'features/doctor/providers/doctor_provider.dart';
import 'features/pharmacist/providers/pharmacist_provider.dart';
import 'features/labtech/providers/labtech_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();
  runApp(const VitalCareApp());
}

class VitalCareApp extends StatelessWidget {
  const VitalCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => DoctorsProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => PharmacyProvider()),
        ChangeNotifierProvider(create: (_) => LaboratoryProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => MedicalRecordsProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => TimelineProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => PharmacistProvider()),
        ChangeNotifierProvider(create: (_) => LabtechProvider()),
      ],
      child: MaterialApp.router(
        title: 'VitalCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
