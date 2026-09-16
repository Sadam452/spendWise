import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../providers/security_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

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

            // Space for future settings...
            const Spacer(),

            // 4. Footer Placeholder
            Divider(color: AppColors.border(context), height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Version ${AppConstants.version}",
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
