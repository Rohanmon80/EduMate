import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import 'admin_signup_page.dart';
import 'admin_main_navigation.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  bool obscurePassword = true;

  final TextEditingController adminIdController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

  // ============================================================
  // BIOMETRIC LOGIN
  // ============================================================

  Future<void> loginWithBiometric() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      final bool biometricEnabled =
          prefs.getBool("adminBiometric") ?? false;

      if (!biometricEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Biometric login is disabled. Enable it from Settings.",
            ),
          ),
        );

        return;
      }

      final bool canCheckBiometrics =
      await auth.canCheckBiometrics;

      final bool isDeviceSupported =
      await auth.isDeviceSupported();

      if (!canCheckBiometrics &&
          !isDeviceSupported) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Biometric authentication is not available on this device.",
            ),
          ),
        );

        return;
      }

      final bool authenticated =
      await auth.authenticate(
        localizedReason:
        "Authenticate to login as Admin",

        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!authenticated || !mounted) {
        return;
      }

      final String? email =
      prefs.getString("adminEmail");

      final String? password =
      prefs.getString("savedPassword");

      if (email == null ||
          password == null ||
          email.isEmpty ||
          password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please login normally once before using biometric login.",
            ),
          ),
        );

        return;
      }

      final UserCredential user =
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final DocumentSnapshot adminDoc =
      await FirebaseFirestore.instance
          .collection("admins")
          .doc(user.user!.uid)
          .get();

      if (!adminDoc.exists ||
          adminDoc["role"] != "admin") {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This account is not an admin account.",
            ),
          ),
        );

        return;
      }

      await prefs.setString(
        "adminUid",
        user.user!.uid,
      );

      await prefs.setString(
        "userRole",
        "admin",
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const AdminMainNavigation(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Biometric login failed: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // NORMAL ADMIN LOGIN
  // ============================================================

  Future<void> loginNormally() async {
    final email =
    adminIdController.text.trim();

    final password =
    passwordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter Admin ID and password.",
          ),
        ),
      );

      return;
    }

    try {
      final UserCredential user =
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid =
          user.user!.uid;

      final DocumentSnapshot adminDoc =
      await FirebaseFirestore.instance
          .collection("admins")
          .doc(uid)
          .get();

      if (!adminDoc.exists ||
          adminDoc["role"] != "admin") {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This account is not an admin account.",
            ),
          ),
        );

        return;
      }

      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      // Save login information for biometric login.
      await prefs.setString(
        "adminUid",
        uid,
      );

      await prefs.setString(
        "adminEmail",
        user.user!.email ?? email,
      );

      await prefs.setString(
        "savedPassword",
        password,
      );

      await prefs.setString(
        "userRole",
        "admin",
      );

      // --------------------------------------------------------
      // Check whether biometric setting already exists.
      // --------------------------------------------------------

      final bool biometricConfigured =
      prefs.containsKey(
        "adminBiometric",
      );

      if (!biometricConfigured) {
        await _showBiometricSetupDialog(
          prefs,
        );

        return;
      }

      // Already configured.
      // Go directly to Admin dashboard.
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const AdminMainNavigation(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login failed: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // BIOMETRIC SETUP DIALOG
  // ============================================================

  Future<void> _showBiometricSetupDialog(
      SharedPreferences prefs,
      ) async {
    if (!mounted) return;

    final bool? enable =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Enable Biometric Login?",
          ),

          content: const Text(
            "You can use fingerprint or device authentication "
                "for faster login next time.",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                "Not Now",
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  final bool available =
                      await auth.canCheckBiometrics ||
                          await auth.isDeviceSupported();

                  if (!available) {
                    if (!dialogContext.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Biometric authentication is not available.",
                        ),
                      ),
                    );

                    return;
                  }

                  final bool authenticated =
                  await auth.authenticate(
                    localizedReason:
                    "Confirm biometric login",

                    options:
                    const AuthenticationOptions(
                      biometricOnly: false,
                      stickyAuth: true,
                    ),
                  );

                  if (!authenticated) {
                    return;
                  }

                  await prefs.setBool(
                    "adminBiometric",
                    true,
                  );

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Could not enable biometric: $e",
                      ),
                    ),
                  );
                }
              },

              child: const Text(
                "Enable",
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AdminMainNavigation(),
      ),
    );
  }

  @override
  void dispose() {
    adminIdController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1736)
          : const Color(0xFFF4F8FC),

      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // TOP BLUE SECTION
            // ==================================================

            Container(
              height: 320,

              decoration:
              const BoxDecoration(
                gradient:
                LinearGradient(
                  colors: [
                    Color(0xFF005BEA),
                    Color(0xFF00C6FB),
                  ],
                ),

                borderRadius:
                BorderRadius.only(
                  bottomLeft:
                  Radius.circular(45),
                  bottomRight:
                  Radius.circular(45),
                ),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 18,
                  ),

                  // --------------------------------------------
                  // TOP BUTTONS
                  // --------------------------------------------

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),

                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(
                              context,
                            );
                          },

                          child:
                          CircleAvatar(
                            backgroundColor:
                            Colors.white
                                .withOpacity(
                              0.15,
                            ),

                            child:
                            const Icon(
                              Icons.arrow_back,
                              color:
                              Colors.white,
                            ),
                          ),
                        ),

                        CircleAvatar(
                          backgroundColor:
                          Colors.white
                              .withOpacity(
                            0.15,
                          ),

                          child:
                          IconButton(
                            onPressed: () {
                              EduMateApp.of(
                                context,
                              )?.toggleTheme();
                            },

                            icon: Icon(
                              isDark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,

                              color:
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // --------------------------------------------
                  // TITLE
                  // --------------------------------------------

                  const Padding(
                    padding:
                    EdgeInsets.symmetric(
                      horizontal: 25,
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Admin Login",

                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize: 42,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        SizedBox(
                          height: 8,
                        ),

                        Text(
                          "Welcome back, Admin",

                          style:
                          TextStyle(
                            color:
                            Colors.white70,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 80,
                  ),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================

                  Container(
                    margin:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),

                    padding:
                    const EdgeInsets.all(
                      25,
                    ),

                    decoration:
                    BoxDecoration(
                      color: isDark
                          ? const Color(
                        0xFF16213E,
                      )
                          : const Color(
                        0xFFEFF7FD,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        38,
                      ),
                    ),

                    child: Column(
                      children: [
                        // --------------------------------------------
                        // LOGO
                        // --------------------------------------------

                        CircleAvatar(
                          radius: 42,

                          backgroundColor:
                          Colors.white,

                          child:
                          ClipRRect(
                            borderRadius:
                            BorderRadius
                                .circular(
                              40,
                            ),

                            child:
                            Image.asset(
                              "assets/images/college_logo.png",

                              width: 75,
                              height: 75,

                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // --------------------------------------------
                        // ADMIN ID
                        // --------------------------------------------

                        Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            "Admin Email",

                            style:
                            TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w600,

                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Container(
                          decoration:
                          BoxDecoration(
                            color: isDark
                                ? const Color(
                              0xFF1E2A47,
                            )
                                : Colors.white,

                            borderRadius:
                            BorderRadius
                                .circular(
                              22,
                            ),
                          ),

                          child:
                          TextField(
                            controller:
                            adminIdController,

                            keyboardType:
                            TextInputType
                                .emailAddress,

                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),

                            decoration:
                            const InputDecoration(
                              hintText:
                              "admin@gmail.com",

                              prefixIcon:
                              Icon(
                                Icons
                                    .mail_outline,
                                color:
                                Colors.blue,
                              ),

                              border:
                              InputBorder.none,

                              contentPadding:
                              EdgeInsets
                                  .symmetric(
                                vertical: 20,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // --------------------------------------------
                        // PASSWORD
                        // --------------------------------------------

                        Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            "Password",

                            style:
                            TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w600,

                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Container(
                          decoration:
                          BoxDecoration(
                            color: isDark
                                ? const Color(
                              0xFF1E2A47,
                            )
                                : Colors.white,

                            borderRadius:
                            BorderRadius
                                .circular(
                              22,
                            ),
                          ),

                          child:
                          TextField(
                            controller:
                            passwordController,

                            obscureText:
                            obscurePassword,

                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),

                            decoration:
                            InputDecoration(
                              hintText:
                              "Password",

                              prefixIcon:
                              const Icon(
                                Icons.key,
                                color:
                                Colors.blue,
                              ),

                              suffixIcon:
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword =
                                    !obscurePassword;
                                  });
                                },

                                icon: Icon(
                                  obscurePassword
                                      ? Icons
                                      .visibility_off
                                      : Icons
                                      .visibility,
                                ),
                              ),

                              border:
                              InputBorder.none,

                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 20,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 35,
                        ),

                        // --------------------------------------------
                        // SIGN IN
                        // --------------------------------------------

                        SizedBox(
                          width:
                          double.infinity,

                          height: 65,

                          child:
                          ElevatedButton(
                            onPressed:
                            loginNormally,

                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              const Color(
                                0xFF008CFF,
                              ),

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  22,
                                ),
                              ),
                            ),

                            child:
                            const Text(
                              "Sign in",

                              style:
                              TextStyle(
                                fontSize: 24,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // --------------------------------------------
                        // CREATE ACCOUNT
                        // --------------------------------------------

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AdminSignupPage(),
                              ),
                            );
                          },

                          child:
                          Container(
                            width:
                            double.infinity,

                            height: 62,

                            alignment:
                            Alignment.center,

                            child:
                            const Text(
                              "Create new account",

                              style:
                              TextStyle(
                                color:
                                Colors.blue,
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // --------------------------------------------
                        // BIOMETRIC
                        // --------------------------------------------

                        GestureDetector(
                          onTap:
                          loginWithBiometric,

                          child:
                          Container(
                            width:
                            double.infinity,

                            height: 62,

                            decoration:
                            BoxDecoration(
                              color: isDark
                                  ? const Color(
                                0xFF1E2A47,
                              )
                                  : Colors.white,

                              borderRadius:
                              BorderRadius
                                  .circular(
                                22,
                              ),
                            ),

                            child:
                            const Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                              children: [
                                Icon(
                                  Icons
                                      .fingerprint,
                                  color:
                                  Colors.blue,
                                ),

                                SizedBox(
                                  width: 10,
                                ),

                                Text(
                                  "Use Biometric",

                                  style:
                                  TextStyle(
                                    fontSize:
                                    16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}