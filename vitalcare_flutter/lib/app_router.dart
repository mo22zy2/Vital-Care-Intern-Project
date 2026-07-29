import 'package:flutter/material.dart';
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
        GoRoute(path: '/billing', builder: (_, _a) => _placeholder('Billing')),
        GoRoute(path: '/laboratory', builder: (_, _a) => _placeholder('Lab Tests')),
        GoRoute(path: '/medical-records', builder: (_, _a) => _placeholder('Medical Records')),
        GoRoute(path: '/prescriptions', builder: (_, _a) => _placeholder('Prescriptions')),
        GoRoute(path: '/notifications', builder: (_, _a) => _placeholder('Notifications')),
        GoRoute(path: '/timeline', builder: (_, _a) => _placeholder('Timeline')),
        GoRoute(path: '/feedback', builder: (_, _a) => _placeholder('Feedback')),
        GoRoute(path: '/profile', builder: (_, _a) => _placeholder('Profile')),
        GoRoute(path: '/search', builder: (_, state) => _placeholder('Search: ${state.extra ?? ""}')),
        GoRoute(path: '/doctor/dashboard', builder: (_, _a) => _placeholder('Doctor Dashboard')),
        GoRoute(path: '/doctor/appointments', builder: (_, _a) => _placeholder('Doctor Appointments')),
        GoRoute(path: '/doctor/availability', builder: (_, _a) => _placeholder('Availability')),
        GoRoute(path: '/pharmacist/dashboard', builder: (_, _a) => _placeholder('Pharmacist Dashboard')),
        GoRoute(path: '/labtech/dashboard', builder: (_, _a) => _placeholder('Lab Tech Dashboard')),
        GoRoute(path: '/admin/dashboard', builder: (_, _a) => _placeholder('Admin Dashboard')),
        GoRoute(path: '/admin/users', builder: (_, _a) => _placeholder('Admin Users')),
        GoRoute(path: '/admin/appointments', builder: (_, _a) => _placeholder('Admin Appointments')),
        GoRoute(path: '/admin/doctors', builder: (_, _a) => _placeholder('Admin Doctors')),
        GoRoute(path: '/admin/medicines', builder: (_, _a) => _placeholder('Admin Medicines')),
        GoRoute(path: '/admin/lab-tests', builder: (_, _a) => _placeholder('Admin Lab Tests')),
        GoRoute(path: '/admin/invoices', builder: (_, _a) => _placeholder('Admin Invoices')),
        GoRoute(path: '/admin/pharmacy-orders', builder: (_, _a) => _placeholder('Admin Orders')),
        GoRoute(path: '/admin/feedback', builder: (_, _a) => _placeholder('Admin Feedback')),
        GoRoute(path: '/admin/reports', builder: (_, _a) => _placeholder('Admin Reports')),
      ],
    ),
  ],
);

Widget _placeholder(String label) {
  return Center(
    child: Text(label, style: const TextStyle(fontSize: 18, color: Colors.grey)),
  );
}
