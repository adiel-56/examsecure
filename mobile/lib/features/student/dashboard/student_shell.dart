import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/notification_provider.dart';
import '../catalogue/catalogue_screen.dart';
import '../purchases/purchases_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'home_tab.dart';

/// Conteneur du dashboard étudiant (section 7).
/// Onglets identiques à la maquette : Accueil · Catalogue · Achats · Alertes · Profil.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  final _tabs = const [
    HomeTab(),
    CatalogueScreen(),
    PurchasesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  final _labels = const ['Accueil', 'Catalogue', 'Achats', 'Alertes', 'Profil'];
  final _icons = const [
    Icons.home_outlined,
    Icons.menu_book_outlined,
    Icons.shopping_cart_outlined,
    Icons.notifications_outlined,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: List.generate(_tabs.length, (i) {
          final icon = Icon(_icons[i]);
          return BottomNavigationBarItem(
            icon: (i == 3 && unread > 0)
                ? Badge(
                    smallSize: 8,
                    backgroundColor: AppColors.danger,
                    child: icon,
                  )
                : icon,
            label: _labels[i],
          );
        }),
      ),
    );
  }
}
