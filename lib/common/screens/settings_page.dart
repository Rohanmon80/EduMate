import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  bool biometric = false;
  bool autoLogin = true;

  String role = "";
  String selectedLanguage = "English";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> loadSettings() async {
    final prefs =
    await SharedPreferences.getInstance();

    final savedRole =
        prefs.getString("userRole") ?? "";

    final savedAutoLogin =
        prefs.getBool("autoLogin") ?? true;

    bool biometricEnabled = false;

    if (savedRole == "student") {
      biometricEnabled =
          prefs.getBool("studentBiometric") ?? false;
    } else if (savedRole == "teacher") {
      biometricEnabled =
          prefs.getBool("teacherBiometric") ?? false;
    } else if (savedRole == "admin") {
      biometricEnabled =
          prefs.getBool("adminBiometric") ?? false;
    }

    if (!mounted) return;

    setState(() {
      role = savedRole;
      autoLogin = savedAutoLogin;
      biometric = biometricEnabled;
      isLoading = false;
    });
  }

  // ============================================================
  // GET CURRENT BIOMETRIC KEY
  // ============================================================

  String? get biometricKey {
    switch (role) {
      case "student":
        return "studentBiometric";

      case "teacher":
        return "teacherBiometric";

      case "admin":
        return "adminBiometric";

      default:
        return null;
    }
  }

  // ============================================================
  // CHANGE BIOMETRIC
  // ============================================================

  Future<void> changeBiometric(bool value) async {
    final prefs =
    await SharedPreferences.getInstance();

    final key = biometricKey;

    if (key == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "User role could not be identified.",
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // ENABLE
    // ----------------------------------------------------------

    if (value) {
      await prefs.setBool(
        key,
        true,
      );

      // Mark biometric setup as configured.
      if (role == "student") {
        await prefs.setBool(
          "studentBiometricConfigured",
          true,
        );
      } else if (role == "teacher") {
        await prefs.setBool(
          "teacherBiometricConfigured",
          true,
        );
      } else if (role == "admin") {
        await prefs.setBool(
          "adminBiometricConfigured",
          true,
        );
      }

      if (!mounted) return;

      setState(() {
        biometric = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Biometric login enabled.",
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // DISABLE
    // ----------------------------------------------------------

    await prefs.setBool(
      key,
      false,
    );

    if (!mounted) return;

    setState(() {
      biometric = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Biometric login disabled.",
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE AUTO LOGIN
  // ============================================================

  Future<void> changeAutoLogin(bool value) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      "autoLogin",
      value,
    );

    if (!mounted) return;

    setState(() {
      autoLogin = value;
    });

    /*
     IMPORTANT:
     Do NOT remove studentBiometric,
     teacherBiometric or adminBiometric here.

     Auto Login and Biometric Login are separate settings.
    */

    if (!value) {
      await prefs.remove("savedEmail");
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    final prefs =
    await SharedPreferences.getInstance();

    /*
     Do not remove biometric settings here.

     The user selected whether biometric login is enabled
     in Settings. Keeping the setting allows it to work
     again after the next normal login.
    */

    await prefs.remove("savedEmail");
    await prefs.remove("savedPassword");
    await prefs.remove("userRole");

    if (!mounted) return;

    Navigator.popUntil(
      context,
          (route) => route.isFirst,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF081120)
            : const Color(0xFFF4F8FC),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // ==================================================
              // TITLE
              // ==================================================

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
                          fontSize: 34,
                          fontWeight:
                          FontWeight.bold,

                          color: isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        role == "student"
                            ? "Student preferences"
                            : role == "teacher"
                            ? "Faculty preferences"
                            : role == "admin"
                            ? "Admin preferences"
                            : "Manage app preferences",

                        style: TextStyle(
                          fontSize: 16,

                          color: isDark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Theme button
                  GestureDetector(
                    onTap: () {
                      EduMateApp.of(context)
                          ?.toggleTheme();
                    },

                    child: Container(
                      width: 52,
                      height: 52,

                      decoration:
                      BoxDecoration(
                        color: isDark
                            ? Colors.white
                            .withOpacity(0.08)
                            : Colors.white,

                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                      ),

                      child: Icon(
                        isDark
                            ? Icons.light_mode
                            : Icons.dark_mode,

                        color: isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 35,
              ),

              // ==================================================
              // NOTIFICATIONS
              // ==================================================

              settingTile(
                isDark: isDark,

                title: "Notifications",

                subtitle:
                "Enable app alerts",

                icon:
                Icons.notifications,

                value: notifications,

                onChanged: (value) {
                  setState(() {
                    notifications =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // BIOMETRIC
              // ==================================================

              settingTile(
                isDark: isDark,

                title: "Biometric Login",

                subtitle: biometric
                    ? "Fingerprint login is enabled"
                    : "Fingerprint login is disabled",

                icon:
                Icons.fingerprint,

                value: biometric,

                onChanged:
                changeBiometric,
              ),

              const SizedBox(
                height: 10,
              ),

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                ),

                child: Text(
                  role == "student"
                      ? "Applies to Student login"
                      : role == "teacher"
                      ? "Applies to Teacher login"
                      : role == "admin"
                      ? "Applies to Admin login"
                      : "Biometric login",

                  style: TextStyle(
                    fontSize: 12,

                    color: isDark
                        ? Colors.white54
                        : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // AUTO LOGIN
              // ==================================================

              settingTile(
                isDark: isDark,

                title: "Auto Login",

                subtitle:
                "Remember login session",

                icon: Icons.login,

                value: autoLogin,

                onChanged:
                changeAutoLogin,
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // LANGUAGE
              // ==================================================

              glassCard(
                isDark: isDark,

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Row(
                      children: [

                        Container(
                          width: 60,
                          height: 60,

                          decoration:
                          BoxDecoration(
                            color: Colors.blue
                                .withOpacity(
                              0.15,
                            ),

                            borderRadius:
                            BorderRadius.circular(
                              18,
                            ),
                          ),

                          child:
                          const Icon(
                            Icons.language,
                            color:
                            Colors.blue,
                          ),
                        ),

                        const SizedBox(
                          width: 18,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                                "Language",

                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.bold,

                                  color: isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                "Choose app language",

                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    DropdownButtonFormField<String>(
                      isExpanded: true,

                      value:
                      selectedLanguage,

                      dropdownColor:
                      isDark
                          ? const Color(
                        0xFF102038,
                      )
                          : Colors.white,

                      items: const [
                        "English",
                        "Hindi",
                        "Bengali",
                        "Tamil",
                        "Telugu",
                      ].map(
                            (language) {
                          return DropdownMenuItem<
                              String>(
                            value: language,

                            child: Text(
                              language,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                            ),
                          );
                        },
                      ).toList(),

                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedLanguage =
                              value;
                        });
                      },

                      decoration:
                      InputDecoration(
                        filled: true,

                        fillColor: isDark
                            ? Colors.white
                            .withOpacity(
                          0.08,
                        )
                            : Colors.white,

                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),

                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 35,
              ),

              // ==================================================
              // LOGOUT
              // ==================================================

              SizedBox(
                width:
                double.infinity,

                height: 60,

                child:
                ElevatedButton(
                  onPressed:
                  logout,

                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    Colors.redAccent,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  child:
                  const Text(
                    "Logout",

                    style:
                    TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SETTING TILE
  // ============================================================

  Widget settingTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return glassCard(
      isDark: isDark,

      child: Row(
        children: [

          Container(
            width: 60,
            height: 60,

            decoration:
            BoxDecoration(
              color: Colors.blue
                  .withOpacity(
                0.15,
              ),

              borderRadius:
              BorderRadius.circular(
                18,
              ),
            ),

            child: Icon(
              icon,
              color: Colors.blue,
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,

                    color: isDark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  subtitle,

                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GLASS CARD
  // ============================================================

  Widget glassCard({
    required bool isDark,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(
        28,
      ),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(
          padding:
          const EdgeInsets.all(
            20,
          ),

          decoration:
          BoxDecoration(
            color: isDark
                ? Colors.white
                .withOpacity(0.08)
                : Colors.white
                .withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(
              28,
            ),

            border: Border.all(
              color: Colors.white
                  .withOpacity(
                0.2,
              ),
            ),
          ),

          child: child,
        ),
      ),
    );
  }
}