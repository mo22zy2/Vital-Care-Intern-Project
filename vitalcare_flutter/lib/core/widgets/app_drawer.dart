import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/network/api_client.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final role = ApiClient.userRole;
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('V', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const Spacer(),
                  Text('VitalCare', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                    fontFamily: 'InterTight',
                  )),
                  const Text('Hospital Management', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _navItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
                  _navItem(context, Icons.medical_services, 'Doctors', '/doctors'),
                  _navItem(context, Icons.calendar_month, 'Appointments', '/appointments'),
                  _navItem(context, Icons.medication, 'Pharmacy', '/pharmacy'),
                  _navItem(context, Icons.receipt_long, 'Billing', '/billing'),
                  _navItem(context, Icons.science, 'Lab Tests', '/laboratory'),
                  _navItem(context, Icons.folder, 'Medical Records', '/medical-records'),
                  _navItem(context, Icons.description, 'Prescriptions', '/prescriptions'),
                  _navItem(context, Icons.notifications, 'Notifications', '/notifications'),
                  _navItem(context, Icons.timeline, 'Timeline', '/timeline'),
                  _navItem(context, Icons.feedback, 'Feedback', '/feedback'),
                  _navItem(context, Icons.health_and_safety, 'Insurance', '/insurance'),
                  if (role == 'DOCTOR') ...[
                    const Divider(color: Colors.white24, height: 1),
                    _sectionHeader('Doctor Panel'),
                    _navItem(context, Icons.dashboard, 'Doctor Dashboard', '/doctor/dashboard'),
                    _navItem(context, Icons.list_alt, 'My Appointments', '/doctor/appointments'),
                    _navItem(context, Icons.schedule, 'Availability', '/doctor/availability'),
                  ],
                  if (role == 'PHARMACIST') ...[
                    const Divider(color: Colors.white24, height: 1),
                    _sectionHeader('Pharmacy Panel'),
                    _navItem(context, Icons.dashboard, 'Dashboard', '/pharmacist/dashboard'),
                  ],
                  if (role == 'LAB_TECH') ...[
                    const Divider(color: Colors.white24, height: 1),
                    _sectionHeader('Lab Panel'),
                    _navItem(context, Icons.dashboard, 'Dashboard', '/labtech/dashboard'),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryDark),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      (ApiClient.userFirstName.isNotEmpty ? ApiClient.userFirstName[0] : 'U').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ApiClient.userFullName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(ApiClient.userRole, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route) {
    final active = GoRouterState.of(context).uri.toString().startsWith(route);
    return Container(
      decoration: BoxDecoration(
        color: active ? Colors.white.withValues(alpha: 0.1) : null,
        border: active ? const Border(left: BorderSide(color: AppColors.accent, width: 3)) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        leading: Icon(icon, color: active ? Colors.white : Colors.white60, size: 20),
        title: Text(label, style: TextStyle(
          color: active ? Colors.white : Colors.white70,
          fontSize: 14,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        )),
        dense: true,
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      ),
      ),
    );
  }
}
