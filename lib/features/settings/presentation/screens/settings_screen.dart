import 'package:flutter/material.dart';
import 'package:dialer_app_poc/core/services/call_screening_service.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _isRoleHeld = false;
  bool _isOverlayGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatuses();
    }
  }

  Future<void> _checkStatuses() async {
    if (!Platform.isAndroid) return;
    
    final role = await CallScreeningService.isCallerIdRoleHeld();
    final overlay = await CallScreeningService.isOverlayPermissionGranted();
    
    if (mounted) {
      setState(() {
        _isRoleHeld = role;
        _isOverlayGranted = overlay;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Permissions & Services'),
                const SizedBox(height: 12),
                _buildSettingTile(
                  title: 'Default Caller ID & Spam',
                  subtitle: _isRoleHeld 
                      ? 'Swift Call is active' 
                      : 'Required to identify incoming calls',
                  icon: Icons.shield_outlined,
                  isGranted: _isRoleHeld,
                  onTap: () async {
                    if (!_isRoleHeld) {
                      await CallScreeningService.requestCallerIdRole();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingTile(
                  title: 'Display Over Other Apps',
                  subtitle: _isOverlayGranted 
                      ? 'Permission granted' 
                      : 'Required to show the CRM popup',
                  icon: Icons.layers_outlined,
                  isGranted: _isOverlayGranted,
                  onTap: () async {
                    if (!_isOverlayGranted) {
                      await CallScreeningService.requestOverlayPermission();
                    }
                  },
                ),
                const SizedBox(height: 40),
                _buildHelpSection(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted ? Colors.transparent : const Color(0xFFFCA5A5).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGranted ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFFFEF2F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted ? const Color(0xFF6366F1) : const Color(0xFFFCA5A5),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isGranted ? const Color(0xFF94A3B8) : const Color(0xFFFCA5A5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (!isGranted)
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFFCA5A5))
            else
              const Icon(Icons.check_circle_rounded, size: 24, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                'Troubleshooting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'If the popup still doesn\'t appear after enabling the settings above, please check your device manufacturer settings:',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildHelpBullet('Enable "Auto-Launch" for Swift Call.'),
          _buildHelpBullet('Set Battery Optimization to "Unrestricted".'),
          _buildHelpBullet('Ensure the app is not "Quietly Dismissed" by the OS.'),
        ],
      ),
    );
  }

  Widget _buildHelpBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF6366F1))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
