import 'package:go_router/go_router.dart';
import 'core/network/api_client.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/doctors/screens/doctors_list_screen.dart';
import 'features/doctors/screens/doctor_detail_screen.dart';
import 'features/appointments/screens/appointments_list_screen.dart';
import 'features/appointments/screens/book_appointment_screen.dart';
import 'features/appointments/screens/cancel_appointment_screen.dart';
import 'features/pharmacy/screens/medicines_screen.dart';
import 'features/pharmacy/screens/create_order_screen.dart';
import 'features/pharmacy/screens/order_history_screen.dart';
import 'features/pharmacy/screens/order_detail_screen.dart';
import 'features/laboratory/screens/tests_screen.dart';
import 'features/laboratory/screens/book_test_screen.dart';
import 'features/billing/screens/invoices_screen.dart';
import 'features/medical_records/screens/records_list_screen.dart';
import 'features/prescriptions/screens/prescriptions_list_screen.dart';
import 'features/notifications/screens/notifications_list_screen.dart';
import 'features/timeline/screens/timeline_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/feedback/screens/feedback_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/doctor/screens/doctor_dashboard_screen.dart';
import 'features/doctor/screens/doctor_appointments_screen.dart';
import 'features/doctor/screens/doctor_availability_screen.dart';
import 'features/doctor/screens/write_prescription_screen.dart';
import 'features/pharmacist/screens/pharmacist_dashboard_screen.dart';
import 'features/labtech/screens/labtech_dashboard_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final loggedIn = ApiClient.isLoggedIn;
    final loginRoute = state.matchedLocation == '/login';
    final registerRoute = state.matchedLocation == '/register';
    if (!loggedIn && !loginRoute && !registerRoute) return '/login';
    if (loggedIn && (loginRoute || registerRoute)) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _a) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _a) => const RegisterScreen()),
    ShellRoute(
      builder: (_, _a, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _a) => const DashboardScreen()),
        GoRoute(path: '/doctors', builder: (_, _a) => const DoctorsListScreen()),
        GoRoute(path: '/doctors/:id', builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DoctorDetailScreen(doctor: extra ?? {});
        }),
        GoRoute(path: '/appointments', builder: (_, _a) => const AppointmentsListScreen()),
        GoRoute(path: '/appointments/book', builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookAppointmentScreen(preselectedDoctor: extra);
        }),
        GoRoute(path: '/appointments/cancel', builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CancelAppointmentScreen(appointment: extra ?? {});
        }),
        GoRoute(path: '/pharmacy', builder: (_, _a) => const MedicinesScreen()),
        GoRoute(path: '/pharmacy/order/create', builder: (_, _a) => const CreateOrderScreen()),
        GoRoute(path: '/pharmacy/orders', builder: (_, _a) => const OrderHistoryScreen()),
        GoRoute(path: '/pharmacy/order/:id', builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OrderDetailScreen(order: extra ?? {});
        }),
        GoRoute(path: '/laboratory', builder: (_, _a) => const TestsScreen()),
        GoRoute(path: '/laboratory/book', builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookTestScreen(preselectedTest: extra);
        }),
        GoRoute(path: '/billing', builder: (_, _a) => const InvoicesScreen()),
        GoRoute(path: '/medical-records', builder: (_, _a) => const MedicalRecordsScreen()),
        GoRoute(path: '/prescriptions', builder: (_, _a) => const PrescriptionsScreen()),
        GoRoute(path: '/notifications', builder: (_, _a) => const NotificationsScreen()),
        GoRoute(path: '/timeline', builder: (_, _a) => const TimelineScreen()),
        GoRoute(path: '/feedback', builder: (_, _a) => const FeedbackScreen()),
        GoRoute(path: '/profile', builder: (_, _a) => const ProfileScreen()),
        GoRoute(path: '/search', builder: (_, state) => SearchScreen(initialQuery: state.extra?.toString() ?? '')),
        GoRoute(path: '/doctor/dashboard', builder: (_, _a) => const DoctorDashboardScreen()),
        GoRoute(path: '/doctor/appointments', builder: (_, _a) => const DoctorAppointmentsScreen()),
        GoRoute(path: '/doctor/availability', builder: (_, _a) => const DoctorAvailabilityScreen()),
        GoRoute(path: '/doctor/prescription', builder: (_, _a) => const WritePrescriptionScreen()),
        GoRoute(path: '/pharmacist/dashboard', builder: (_, _a) => const PharmacistDashboardScreen()),
        GoRoute(path: '/labtech/dashboard', builder: (_, _a) => const LabtechDashboardScreen()),
      ],
    ),
  ],
);


