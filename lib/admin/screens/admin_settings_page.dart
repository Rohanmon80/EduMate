import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() =>
      _AdminSettingsPageState();
}

class _AdminSettingsPageState
    extends State<AdminSettingsPage> {

  bool notifications = true;
  bool biometric = false;
  bool autoBackup = true;

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              /// TOP BAR
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Settings",

                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : const Color(0xFF0B1736),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Manage application preferences",

                        style: TextStyle(
                          fontSize: 16,

                          color:
                          isDark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  glassIcon(
                    icon:
                    isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,

                    onTap: () {

                      EduMateApp.of(context)
                          ?.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// ADMIN PROFILE
              glassCard(

                isDark: isDark,

                child: Row(

                  children: [

                    Container(
                      width: 85,
                      height: 85,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF005BEA),
                            Color(0xFF00C6FB),
                          ],
                        ),
                      ),

                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Admin User",

                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,

                              color:
                              isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "admin@edumate.com",

                            style: TextStyle(
                              color:
                              isDark
                                  ? Colors.white70
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              Text(
                "Preferences",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              settingsTile(
                isDark: isDark,
                icon: Icons.notifications,
                title: "Notifications",
                subtitle:
                "Enable push notifications",
                value: notifications,
                onChanged: (v) {

                  setState(() {

                    notifications = v;
                  });
                },
              ),

              settingsTile(
                isDark: isDark,
                icon: Icons.fingerprint,
                title: "Biometric Security",
                subtitle:
                "Enable fingerprint login",
                value: biometric,
                onChanged: (v) {

                  setState(() {

                    biometric = v;
                  });
                },
              ),

              settingsTile(
                isDark: isDark,
                icon: Icons.backup,
                title: "Auto Backup",
                subtitle:
                "Backup data automatically",
                value: autoBackup,
                onChanged: (v) {

                  setState(() {

                    autoBackup = v;
                  });
                },
              ),

              const SizedBox(height: 35),

              Text(
                "System",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              menuTile(
                isDark: isDark,
                icon: Icons.storage,
                title: "Database Backup",
                color: Colors.blue,
              ),

              menuTile(
                isDark: isDark,
                icon: Icons.restore,
                title: "Restore System",
                color: Colors.green,
              ),

              menuTile(
                isDark: isDark,
                icon: Icons.security,
                title: "Security Logs",
                color: Colors.orange,
              ),

              menuTile(
                isDark: isDark,
                icon: Icons.info,
                title: "About EduMate",
                color: Colors.purple,
              ),

              const SizedBox(height: 35),

              /// LOGOUT
              SizedBox(
                width: double.infinity,
                height: 62,

                child: ElevatedButton(

                  onPressed: () {},

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.redAccent,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(22),
                    ),
                  ),

                  child: const Text(
                    "Logout",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget settingsTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: glassCard(

        isDark: isDark,

        child: Row(

          children: [

            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color:
                Colors.blue.withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Icon(
                icon,
                color: Colors.blue,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    title,

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,

                      color:
                      isDark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    subtitle,

                    style: TextStyle(
                      color:
                      isDark
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Switch(
              value: value,
              activeColor: Colors.blue,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget menuTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required Color color,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: glassCard(

        isDark: isDark,

        child: Row(

          children: [

            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color:
                color.withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Text(
                title,

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget glassCard({
    required bool isDark,
    required Widget child,
  }) {

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(30),

      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(30),

            border: Border.all(
              color:
              Colors.white.withOpacity(0.2),
            ),
          ),

          child: child,
        ),
      ),
    );
  }

  Widget glassIcon({
    required IconData icon,
    VoidCallback? onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: ClipRRect(

        borderRadius:
        BorderRadius.circular(18),

        child: BackdropFilter(

          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ),

          child: Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(

              color: Colors.white.withOpacity(0.12),

              borderRadius:
              BorderRadius.circular(18),

              border: Border.all(
                color: Colors.white24,
              ),
            ),

            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}