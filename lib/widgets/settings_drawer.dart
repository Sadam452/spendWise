import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../providers/expense_provider.dart';
import '../providers/income_provider.dart';
import '../providers/lending_provider.dart';
import '../providers/security_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  bool _dataBackupExpanded = false;

  Future<void> _exportBackup() async {
    Scaffold.of(context).closeDrawer();
    try {
      await context.read<ExpenseProvider>().exportBackup();
      if (mounted) AppUtils.showToast(context, 'Backup exported!');
    } catch (error) {
      if (mounted) AppUtils.showToast(context, 'Export failed: $error');
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text(
          'Restore Backup?',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          'This replaces all current data and cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    Scaffold.of(context).closeDrawer();
    final result = await context.read<ExpenseProvider>().importBackup();
    if (!mounted) return;

    if (result == 'success') {
      await Future.wait([
        context.read<LendingProvider>().loadAll(),
        context.read<IncomeProvider>().load(),
      ]);
    }

    if (mounted) {
      AppUtils.showToast(
        context,
        result == 'success'
            ? 'Data restored successfully!'
            : result == 'cancelled'
            ? 'Import cancelled'
            : 'Invalid backup file',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Restricts the drawer to 60% of the screen width
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.60,
      backgroundColor: AppColors.background(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header / App Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.border(context), height: 1),

            const SizedBox(height: 10),

            // 2. Settings Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "PREFERENCES",
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // 3. Biometric Security Toggle
            Consumer<SecurityProvider>(
              builder: (context, security, _) {
                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    "App Lock",
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Require PIN/Bio",
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                  activeColor: AppColors.primary,
                  value: security.isSecure,
                  onChanged: (value) async {
                    if (value) {
                      final auth = LocalAuthentication();
                      try {
                        // Stripped down here as well
                        final didAuth = await auth.authenticate(
                          localizedReason: 'Verify to enable App Lock',
                        );
                        if (didAuth) security.toggleSecurity(true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to setup biometrics'),
                          ),
                        );
                      }
                    } else {
                      security.toggleSecurity(false);
                    }
                  },
                );
              },
            ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.backup_outlined, color: AppColors.info),
              title: Text(
                'Data & Backup',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                _dataBackupExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textSecondary(context),
              ),
              onTap: () =>
                  setState(() => _dataBackupExpanded = !_dataBackupExpanded),
            ),
            if (_dataBackupExpanded) ...[
              _backupAction(
                icon: Icons.upload_outlined,
                title: 'Export Backup',
                onTap: _exportBackup,
              ),
              _backupAction(
                icon: Icons.download_outlined,
                title: 'Restore Backup',
                onTap: _restoreBackup,
              ),
            ],

            // Space for future settings...
            const Spacer(),

            // About/app details
            Divider(color: AppColors.border(context), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About SpendWise',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Private, offline personal finance tracking',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Version ${AppConstants.version}',
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 11,
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

  Widget _backupAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(icon, color: AppColors.textSecondary(context), size: 20),
        title: Text(
          title,
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
        ),
        onTap: onTap,
      ),
    );
  }
}
