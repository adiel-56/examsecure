import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../exams/manage_exams_screen.dart';
import '../users/manage_users_screen.dart';
import '../unlock_requests/admin_unlock_requests_screen.dart';
import '../statistics/statistics_screen.dart';
import 'admin_home_tab.dart';

/// Conteneur du dashboard administrateur (section 8), dans la même
/// application Flutter que l'espace étudiant (section 5).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _tabs = const [
    AdminHomeTab(),
    ManageExamsScreen(),
    ManageUsersScreen(),
    AdminUnlockRequestsScreen(),
    StatisticsScreen(),
  ];

  final _labels = const ['Tableau', 'Documents', 'Utilisateurs', 'Demandes', 'Stats'];
  final _icons = const [
    Icons.dashboard_outlined,
    Icons.description_outlined,
    Icons.people_outline,
    Icons.report_gmailerrorred_outlined,
    Icons.bar_chart_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.admin,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          selectedItemColor: AppColors.navy,
          items: List.generate(
            _tabs.length,
            (i) => BottomNavigationBarItem(icon: Icon(_icons[i]), label: _labels[i]),
          ),
        ),
      ),
    );
  }
}
