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

class _SettingsPageState
    extends State<SettingsPage> {

  bool notifications = true;

  bool biometric = false;

  bool autoLogin = true;

  String role = "";

  String selectedLanguage =
      "English";

  @override

  void initState(){

    super.initState();

    loadBiometric();
  }

  Future<void>
  loadBiometric()

  async {

    SharedPreferences prefs =

    await SharedPreferences
        .getInstance();

    role =

        prefs.getString(
          "userRole",
        )

            ??

            "";

    autoLogin =

        prefs.getBool(
          "autoLogin",
        )

            ??

            true;

    setState((){

      if(
      role ==
          "student"
      ){

        biometric =

            prefs.getBool(
              "studentBiometric",
            )

                ??

                false;
      }

      else if(
      role ==
          "teacher"
      ){

        biometric =

            prefs.getBool(
              "teacherBiometric",
            )

                ??

                false;
      }

      else if(
      role ==
          "admin"
      ){

        biometric =

            prefs.getBool(
              "adminBiometric",
            )

                ??

                false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(

          icon:
          const Icon(Icons.arrow_back),

          onPressed: () {

            Navigator.pop(context);
          },
        ),
      ),

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              /// TITLE
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

                          color:
                          isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Manage app preferences",

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

                        color:
                        isDark
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

                        color:
                        isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// NOTIFICATIONS
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

              const SizedBox(height: 20),

              /// BIOMETRIC
              settingTile(
                isDark: isDark,
                title:
                "Biometric Login",
                subtitle:
                "Fingerprint unlock",
                icon:
                Icons.fingerprint,
                value: biometric,

                onChanged: (value)

                async {

                  SharedPreferences prefs =

                  await SharedPreferences
                      .getInstance();

                  if(
                  !autoLogin &&
                      value
                  ){

                    ScaffoldMessenger.of(
                      context,
                    )

                        .showSnackBar(

                      const SnackBar(

                        content:
                        Text(
                          "Enable Auto Login first",
                        ),
                      ),
                    );

                    return;
                  }

                  setState((){

                    biometric=value;
                  });

                  if(
                  role ==
                      "student"
                  ){

                    await prefs.setBool(

                      "studentBiometric",

                      value,
                    );
                  }

                  else if(
                  role ==
                      "teacher"
                  ){

                    await prefs.setBool(

                      "teacherBiometric",

                      value,
                    );
                  }

                  else if(
                  role ==
                      "admin"
                  ){

                    await prefs.setBool(

                      "adminBiometric",

                      value,
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              /// AUTO LOGIN
              settingTile(
                isDark: isDark,
                title: "Auto Login",
                subtitle:
                "Remember login session",
                icon: Icons.login,
                value: autoLogin,

                onChanged:
                    (value) async {

                  SharedPreferences prefs =

                  await SharedPreferences
                      .getInstance();

                  setState(() {

                    autoLogin = value;
                  });

                  await prefs.setBool(
                    "autoLogin",
                    value,
                  );

                  if(
                  !value
                  ){

                    await prefs.remove(
                      "savedEmail",
                    );

                    await prefs.remove(
                      "savedPassword",
                    );

                    await prefs.remove(
                      "studentBiometric",
                    );

                    await prefs.remove(
                      "teacherBiometric",
                    );

                    await prefs.remove(
                      "adminBiometric",
                    );

                    setState((){

                      biometric=false;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              /// LANGUAGE
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
                            color:
                            Colors.blue
                                .withOpacity(
                              0.15,
                            ),

                            borderRadius:
                            BorderRadius.circular(
                              18,
                            ),
                          ),

                          child: const Icon(
                            Icons.language,
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
                                "Language",

                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.bold,

                                  color:
                                  isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Choose app language",

                                style: TextStyle(
                                  color:
                                  isDark
                                      ? Colors
                                      .white70
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(

                      value:
                      selectedLanguage,

                      dropdownColor:
                      isDark
                          ? const Color(
                        0xFF102038,
                      )
                          : Colors.white,

                      items: [

                        "English",
                        "Hindi",
                        "Bengali",
                        "Tamil",
                        "Telugu",

                      ].map((language) {

                        return DropdownMenuItem(

                          value: language,

                          child:
                          Text(language),
                        );
                      }).toList(),

                      onChanged: (value) {

                        setState(() {

                          selectedLanguage =
                          value!;
                        });
                      },

                      decoration:
                      InputDecoration(

                        filled: true,

                        fillColor:
                        isDark
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

              const SizedBox(height: 35),

              /// LOGOUT BUTTON
              SizedBox(

                width: double.infinity,
                height: 60,

                child: ElevatedButton(

                  onPressed: () async {

                    await FirebaseAuth
                        .instance
                        .signOut();

                    SharedPreferences prefs =

                    await SharedPreferences
                        .getInstance();

                    await prefs.remove(
                      "savedEmail",
                    );

                    await prefs.remove(
                      "savedPassword",
                    );

                    await prefs.remove(
                      "userRole",
                    );

                    await prefs.remove(
                      "studentBiometric",
                    );

                    await prefs.remove(
                      "teacherBiometric",
                    );

                    await prefs.remove(
                      "adminBiometric",
                    );

                    if(
                    mounted
                    ){

                      Navigator.popUntil(

                        context,

                            (route) =>
                        route.isFirst,
                      );
                    }
                  },

                  style:
                  ElevatedButton.styleFrom(

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

                  child: const Text(
                    "Logout",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
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

  Widget settingTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool)
    onChanged,
  }) {

    return glassCard(

      isDark: isDark,

      child: Row(

        children: [

          Container(

            width: 60,
            height: 60,

            decoration: BoxDecoration(
              color:
              Colors.blue.withOpacity(
                0.15,
              ),

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
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,

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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget glassCard({
    required bool isDark,
    required Widget child,
  }) {

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(28),

      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(

          padding:
          const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white
                .withOpacity(0.08)
                : Colors.white
                .withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(28),

            border: Border.all(
              color:
              Colors.white
                  .withOpacity(0.2),
            ),
          ),

          child: child,
        ),
      ),
    );
  }
}