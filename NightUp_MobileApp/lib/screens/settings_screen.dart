import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../models/user.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

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
    // Inicializar controllers con datos del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _settingsController.user.value;
      if (user != null) {
        _bioController.text = user.bio ?? '';
        _locationController.text = user.location != null ? user.location as String : '';
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
                      // Sección de Perfil
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
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage: user?.profilePictureUrl != null 
                                              ? NetworkImage(user!.profilePictureUrl!)
                                              : null,
                                          child: user?.profilePictureUrl == null
                                              ? const Icon(Icons.person, size: 40, color: Colors.white70)
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          onTap: _settingsController.updateCoverPhoto,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.primary),
                                              borderRadius: BorderRadius.circular(8),
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
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
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
                      _buildSectionTitle('Preferences'),
                      Obx(() => _buildSwitchSetting(
                        icon: Icons.notifications,
                        title: 'Push Notifications',
                        subtitle: 'Receive event updates and messages',
                        value: _settingsController.notificationsEnabled.value,
                        onChanged: (value) {
                          _settingsController.notificationsEnabled.value = value;
                          _settingsController.saveSettings();
                        },
                        color: Colors.orange,
                      )),
                      Obx(() => _buildSwitchSetting(
                        icon: Icons.location_on,
                        title: 'Location Services',
                        subtitle: 'Share your location for better recommendations',
                        value: _settingsController.locationEnabled.value,
                        onChanged: (value) {
                          _settingsController.locationEnabled.value = value;
                          _settingsController.saveSettings();
                        },
                        color: Colors.blue,
                      )),
                      Obx(() => _buildSwitchSetting(
                        icon: Icons.visibility,
                        title: 'Visible on Map',
                        subtitle: 'Allow friends to see your location on the map',
                        value: _settingsController.isVisibleOnMap.value,
                        onChanged: (value) {
                          _settingsController.updateLocationVisibility(value);
                        },
                        color: AppColors.primary,
                      )),
                      Obx(() => _buildSwitchSetting(
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme across the app',
                        value: _settingsController.darkModeEnabled.value,
                        onChanged: (value) {
                          _settingsController.darkModeEnabled.value = value;
                          _settingsController.saveSettings();
                        },
                        color: Colors.indigo,
                      )),
                      
                      const SizedBox(height: 24),
                      _buildSectionTitle('Support'),
                      _buildSettingItem(
                        icon: Icons.help,
                        title: 'Help & Support',
                        subtitle: 'Get help with the app',
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      _buildSettingItem(
                        icon: Icons.description,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms and conditions',
                        color: Colors.grey,
                        onTap: () {},
                      ),
                      _buildSettingItem(
                        icon: Icons.security,
                        title: 'Privacy Policy',
                        subtitle: 'Learn about our privacy practices',
                        color: Colors.green,
                        onTap: () {},
                      ),
                      _buildSettingItem(
                        icon: Icons.bug_report,
                        title: 'Report a Problem',
                        subtitle: 'Found a bug? Let us know',
                        color: Colors.red,
                        onTap: () {},
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
                        onPressed: () {
                          Get.find<AuthController>().logout();
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
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

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
                        if (newPasswordController.text != confirmPasswordController.text) {
                          Get.snackbar('Error', 'Passwords do not match');
                          return;
                        }
                        if (newPasswordController.text.length < 6) {
                          Get.snackbar('Error', 'Password must be at least 6 characters');
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
      Obx(() => GlassCard(
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
                  _settingsController.notificationsEnabled.value = value;
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
      )),
    );
  }

  Widget _buildPrivacySwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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