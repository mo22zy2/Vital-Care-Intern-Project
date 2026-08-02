import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_drawer.dart';
import 'app_topbar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final title = _titleForRoute(location);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          AppTopbar(title: title),
          Expanded(child: child),
        ],
      ),
    );
  }

  String _titleForRoute(String uri) {
    if (uri.startsWith('/dashboard')) return 'Dashboard';
    if (uri.startsWith('/doctors')) return 'Doctors';
    if (uri.startsWith('/appointments')) return 'Appointments';
    if (uri.startsWith('/pharmacy')) return 'Pharmacy';
    if (uri.startsWith('/billing')) return 'Billing';
    if (uri.startsWith('/laboratory')) return 'Lab Tests';
    if (uri.startsWith('/medical-records')) return 'Medical Records';
    if (uri.startsWith('/prescriptions')) return 'Prescriptions';
    if (uri.startsWith('/notifications')) return 'Notifications';
    if (uri.startsWith('/timeline')) return 'Timeline';
    if (uri.startsWith('/feedback')) return 'Feedback';
    if (uri.startsWith('/profile')) return 'Profile';
    if (uri.startsWith('/search')) return 'Search';
    if (uri.startsWith('/doctor')) return 'Doctor Panel';
    if (uri.startsWith('/pharmacist')) return 'Pharmacy Panel';
    if (uri.startsWith('/labtech')) return 'Lab Panel';
    return 'VitalCare';
  }
}
