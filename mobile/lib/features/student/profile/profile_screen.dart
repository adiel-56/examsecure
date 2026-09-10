import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../devices/devices_screen.dart';
import '../unlock_requests/unlock_requests_screen.dart';

/// Reproduit l'écran « Profil & sécurité » de la maquette : carte
/// d'en-tête (avatar + badges ÉTUDIANT·E / filière), liste de réglages
/// (Mon appareil, Notifications avec interrupteur, Sécurité locale,
/// Paramètres), puis un bouton « Se déconnecter » en bordure rouge.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const Text(
            'Profil',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user != null && user.firstName.isNotEmpty
                        ? user.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: AppColors.faint, fontSize: 11),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 7,
                  children: [
                    _Pill(
                      label: 'ÉTUDIANT·E',
                      bg: AppColors.primarySoft,
                      fg: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.phonelink_outlined,
                  label: 'Mon appareil',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.faint,
                    size: 18,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DevicesScreen()),
                  ),
                ),
                _divider(),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ),
                _divider(),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  label: 'Sécurité locale',
                  subtitle: 'Clés AES en Keystore / Keychain',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.faint,
                    size: 18,
                  ),
                  onTap: () {},
                ),
                _divider(),
                _SettingsTile(
                  icon: Icons.lock_open_outlined,
                  label: 'Mes demandes de déblocage',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.faint,
                    size: 18,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UnlockRequestsScreen(),
                    ),
                  ),
                ),
                _divider(),
                _SettingsTile(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.faint,
                    size: 18,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 16, color: AppColors.danger),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.dangerSoft, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    color: Color(0xFFF0F3F9),
    indent: 14,
    endIndent: 14,
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.faint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
