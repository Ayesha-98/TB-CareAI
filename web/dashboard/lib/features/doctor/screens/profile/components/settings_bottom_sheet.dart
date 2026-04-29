import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class SettingsBottomSheet extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onExportData;
  final VoidCallback onPrivacySettings;
  final VoidCallback onSignOut;

  const SettingsBottomSheet({
    super.key,
    required this.onChangePassword,
    required this.onExportData,
    required this.onPrivacySettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(largeRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: defaultPadding),
          _buildSettingsOption(
            context,
            'Change Password',
            Icons.lock_outline,
            onChangePassword,
          ),
          _buildSettingsOption(
            context,
            'Export Data',
            Icons.download,
            onExportData,
          ),
          _buildSettingsOption(
            context,
            'Privacy Settings',
            Icons.privacy_tip_outlined,
            onPrivacySettings,
          ),
          _buildSettingsOption(
            context,
            'Sign Out',
            Icons.logout,
            onSignOut,
            isDestructive: true,
          ),
          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? errorColor : secondaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? errorColor : secondaryColor,
          fontSize: bodySize,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
      ),
    );
  }
}