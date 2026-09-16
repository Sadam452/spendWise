import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/theme.dart';
import 'main_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
try {
      // Stripped down to the universally accepted parameter
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock SpendWise to view your finances',
      );

      if (didAuthenticate && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text("App Locked", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text("Verify your identity to proceed", style: TextStyle(color: AppColors.textSecondary(context))),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint, size: 24),
              label: const Text("Tap to Unlock", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}