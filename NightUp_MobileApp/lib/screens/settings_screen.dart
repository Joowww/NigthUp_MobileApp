import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../models/user.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/image_with_fallback.dart';
import 'login_screen.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'support_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _settingsController.user.value;
      if (user != null) {
        _bioController.text = user.bio ?? '';
        _locationController.text = user.location != null
            ? user.location as String
            : '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() {
                  if (_settingsController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final user = _settingsController.user.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Profile'),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _settingsController.updateAvatar,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: ImageWithFallback(
                                            imageUrl:
                                                user?.safeProfilePictureUrl,
                                            width: 80,
                                            height: 80,
                                            isCircle: true,
                                            fallbackAsset:
                                                'assets/images/default-avatar.png',
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.username ?? 'Username',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          user?.email ?? 'email@example.com',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: _settingsController
                                              .updateCoverPhoto,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppColors.primary,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Change Cover Photo',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _bioController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Bio',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              GradientButton(
                                onPressed: () {
                                  _settingsController.updateProfile({
                                    'bio': _bioController.text,
                                    'location': _locationController.text,
                                  });
                                },
                                text: 'Save Profile',
                                isLoading: _settingsController.isUpdating.value,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Security'),
                      _buildSettingItem(
                        icon: Icons.lock,
                        title: 'Change Password',
                        subtitle: 'Update your security credentials',
                        color: AppColors.secondary,
                        onTap: _showChangePasswordDialog,
                      ),
                      _buildSettingItem(
                        icon: Icons.security,
                        title: 'Privacy Settings',
                        subtitle: 'Control your privacy options',
                        color: Colors.green,
                        onTap: _showPrivacySettingsDialog,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('General'),
                      GlassCard(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.language,
                              color: Colors.purple,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Language',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            LocalizedApp.of(
                              context,
                            ).delegate.currentLocale.languageCode.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                          onTap: () => _showLanguageDialog(context),
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Support'),
                      _buildSettingItem(
                        icon: Icons.help,
                        title: 'Help & Support',
                        subtitle: 'Get help with the app',
                        color: Colors.blue,
                        onTap: () {
                          Get.to(
                            () => const SupportScreen(
                              title: 'Help & Support',
                              content:
                                  'If you need assistance, please contact our support team at support@nightup.com. We are available 24/7 to help you with any issues you may encounter while using the app.',
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.description,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms and conditions',
                        color: Colors.grey,
                        onTap: () {
                          Get.to(
                            () => const SupportScreen(
                              title: 'Terms of Service',
                              content:
                                  'By using NightUp, you agree to our Terms of Service. These terms govern your use of the app and provide information about your rights and responsibilities. Please read them carefully.',
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.security,
                        title: 'Privacy Policy',
                        subtitle: 'Learn about our privacy practices',
                        color: Colors.green,
                        onTap: () {
                          Get.to(
                            () => const SupportScreen(
                              title: 'Privacy Policy',
                              content:
                                  'Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information. We are committed to ensuring your data is secure.',
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.bug_report,
                        title: 'Report a Problem',
                        subtitle: 'Found a bug? Let us know',
                        color: Colors.red,
                        onTap: () {
                          Get.to(
                            () => const SupportScreen(
                              title: 'Report a Problem',
                              content:
                                  'If you encounter a bug or have feedback, please email us at bugs@nightup.com. Your feedback helps us improve the app for everyone.',
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('About'),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildAboutItem('Version', '2.0.0'),
                              _buildAboutItem('Build', '2025.11.17'),
                              _buildAboutItem('Last Updated', 'November 2025'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      GradientButton(
                        onPressed: () async {
                          await Get.find<AuthController>().logout();

                          Get.offAll(
                            () => LoginScreen(
                              onLogin: () {},
                              onRegister: () {},
                              onForgotPassword: () {},
                            ),
                          );
                        },
                        text: 'Log Out',
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    Get.dialog(
      GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          Get.snackbar('Error', 'Passwords do not match');
                          return;
                        }
                        if (newPasswordController.text.length < 6) {
                          Get.snackbar(
                            'Error',
                            'Password must be at least 6 characters',
                          );
                          return;
                        }
                        _settingsController.changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                        Get.back();
                      },
                      text: 'Update',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySettingsDialog() {
    Get.dialog(
      Material(
        type: MaterialType.transparency,
        child: Center(
          child: SingleChildScrollView(
            child: Obx(
              () => GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Privacy Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPrivacySwitch(
                        'Visible on Map',
                        'Allow friends to see your location on the map',
                        _settingsController.isVisibleOnMap.value,
                        (value) {
                          _settingsController.updateLocationVisibility(value);
                        },
                      ),
                      _buildPrivacySwitch(
                        'Push Notifications',
                        'Receive event updates and messages',
                        _settingsController.notificationsEnabled.value,
                        (value) {
                          _settingsController.notificationsEnabled.value =
                              value;
                          _settingsController.saveSettings();
                        },
                      ),
                      _buildPrivacySwitch(
                        'Location Services',
                        'Share your location for better recommendations',
                        _settingsController.locationEnabled.value,
                        (value) {
                          _settingsController.locationEnabled.value = value;
                          _settingsController.saveSettings();
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              onPressed: () {
                                _settingsController.saveSettings();
                                Get.back();
                              },
                              text: 'Save',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    Get.dialog(
      Material(
        type: MaterialType.transparency,
        child: Center(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Language',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageOption(context, 'English', 'en'),
                  _buildLanguageOption(context, 'Español', 'es'),
                  _buildLanguageOption(context, 'Français', 'fr'),
                  _buildLanguageOption(context, 'Deutsch', 'de'),
                  _buildLanguageOption(context, 'Italiano', 'it'),
                  const SizedBox(height: 24),
                  GradientButton(onPressed: () => Get.back(), text: 'Cancel'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, String code) {
    final isSelected =
        LocalizedApp.of(context).delegate.currentLocale.languageCode == code;
    return InkWell(
      onTap: () {
        _settingsController.changeLanguage(context, code);
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white70,
            size: 16,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
