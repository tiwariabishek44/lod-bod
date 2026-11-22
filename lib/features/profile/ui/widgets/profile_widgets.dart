import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

String _initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final initials = words.take(2).map((word) => word.substring(0, 1)).join();
  return initials.isEmpty ? 'LB' : initials.toUpperCase();
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.onTap,
    required this.displayName,
    this.contact,
  });

  final VoidCallback onTap;
  final String displayName;
  final String? contact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7E6E9)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B18274D),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.orange,
                child: Text(
                  _initials(displayName),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      contact ?? 'Himal Traders · Admin',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: AppTextStyles.bodySize,
                      ),
                    ),
                    SizedBox(height: 8),
                    _VerifiedAccountBadge(),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.muted,
          fontSize: AppTextStyles.labelSize,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _VerifiedAccountBadge extends StatelessWidget {
  const _VerifiedAccountBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF168A4A), size: 13),
          SizedBox(width: 5),
          Text(
            'Verified shipper',
            style: TextStyle(
              color: Color(0xFF168A4A),
              fontSize: AppTextStyles.labelSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingRowData {
  const ProfileSettingRowData({
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final Widget? trailing;
}

class ProfileSettingsGroup extends StatelessWidget {
  const ProfileSettingsGroup({super.key, required this.rows});

  final List<ProfileSettingRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E6E9)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0718274D),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _SettingRow(row: rows[index]),
            if (index != rows.length - 1)
              const Divider(height: 1, color: Color(0xFFF0EFF1)),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.row});

  final ProfileSettingRowData row;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Icon(row.icon, color: AppColors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: AppTextStyles.buttonSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (row.trailing != null)
            row.trailing!
          else if (row.trailingText != null)
            Text(
              row.trailingText!,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: AppTextStyles.bodySize,
              ),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 18,
            ),
        ],
      ),
    );
  }
}
