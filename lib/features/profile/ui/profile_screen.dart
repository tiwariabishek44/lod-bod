import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_providers.dart';
import 'widgets/profile_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    return AccountScreen(
      displayName: user?.name ?? 'Aarav Shrestha',
      contact: user?.email ?? user?.phone,
      onSignOut: () => ref.read(authStateProvider.notifier).signOut(),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.displayName,
    required this.onSignOut,
    this.contact,
    super.key,
  });

  final String displayName;
  final String? contact;
  final VoidCallback onSignOut;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F5F7),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.height(9),
                AppSpacing.pageHorizontal,
                AppSpacing.height(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Account',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE7E6E9)),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0818274D),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.ink,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  0,
                  AppSpacing.pageHorizontal,
                  AppSpacing.height(24),
                ),
                children: [
                  ProfileCard(
                    onTap: () {},
                    displayName: widget.displayName,
                    contact: widget.contact,
                  ),
                  const SizedBox(height: 16),
                  const ProfileSectionLabel('ACCOUNT'),
                  ProfileSettingsGroup(
                    rows: const [
                      ProfileSettingRowData(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile & company',
                      ),
                      ProfileSettingRowData(
                        icon: Icons.groups_outlined,
                        label: 'Team access',
                      ),
                      ProfileSettingRowData(
                        icon: Icons.favorite_border_rounded,
                        label: 'Favorite carriers',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ProfileSectionLabel('PREFERENCES'),
                  ProfileSettingsGroup(
                    rows: [
                      const ProfileSettingRowData(
                        icon: Icons.translate_rounded,
                        label: 'Language',
                        trailingText: 'English',
                      ),
                      const ProfileSettingRowData(
                        icon: Icons.brightness_6_outlined,
                        label: 'Appearance',
                        trailingText: 'System',
                      ),
                      ProfileSettingRowData(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        trailing: Switch.adaptive(
                          value: _notificationsEnabled,
                          activeThumbColor: AppColors.orange,
                          onChanged: (value) =>
                              setState(() => _notificationsEnabled = value),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const ProfileSettingRowData(
                        icon: Icons.extension_outlined,
                        label: 'Integrations',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ProfileSectionLabel('SUPPORT & FEEDBACK'),
                  const ProfileSettingsGroup(
                    rows: [
                      ProfileSettingRowData(
                        icon: Icons.help_outline_rounded,
                        label: 'Help center',
                      ),
                      ProfileSettingRowData(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Request a feature',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ProfileSectionLabel('LEGAL & SECURITY'),
                  const ProfileSettingsGroup(
                    rows: [
                      ProfileSettingRowData(
                        icon: Icons.lock_outline_rounded,
                        label: 'Security & password',
                      ),
                      ProfileSettingRowData(
                        icon: Icons.description_outlined,
                        label: 'Terms · Privacy policy',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onSignOut,
                          icon: const Icon(Icons.logout_rounded, size: 17),
                          label: const Text('Sign out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.orange,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            minimumSize: const Size.fromHeight(44),
                            textStyle: TextStyle(
                              fontSize: AppTextStyles.bodySize,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                          ),
                          label: const Text('Delete account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.muted,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            minimumSize: const Size.fromHeight(44),
                            textStyle: TextStyle(
                              fontSize: AppTextStyles.bodySize,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
