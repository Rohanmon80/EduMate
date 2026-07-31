import 'dart:ui';

import 'package:flutter/material.dart';
import 'student/screens/student_login_page.dart';
import 'teacher/screens/teacher_login_page.dart';
import 'admin/screens/admin_login_page.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleSelectionPage extends StatelessWidget {

  const RoleSelectionPage({
    super.key,
  });

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

        child: Padding(

          padding:
          const EdgeInsets.all(24),

          child: Column(

            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              /// TITLE
              Text(
                "Choose Your Role",

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

              const SizedBox(height: 14),

              Text(
                "Select how you want to continue",

                style: TextStyle(
                  fontSize: 16,

                  color:
                  isDark
                      ? Colors.white70
                      : Colors.grey,
                ),
              ),

              const SizedBox(height: 50),

              /// STUDENT
              roleCard(
                context: context,
                title: "Student",
                icon: Icons.school,
                color: Colors.blue,
                page:
                const StudentLoginPage(),
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              /// TEACHER
              roleCard(
                context: context,
                title: "Teacher",
                icon: Icons.person,
                color: Colors.green,
                page:
                const TeacherLoginPage(),
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              /// ADMIN
              roleCard(
                context: context,
                title: "Admin",
                icon:
                Icons.admin_panel_settings,
                color: Colors.orange,
                page:
                const AdminLoginPage(),
                isDark: isDark,
              ),

              const SizedBox(height: 40),

              /// THEME BUTTON
              GestureDetector(

                onTap: () {

                  EduMateApp.of(context)
                      ?.toggleTheme();
                },

                child: Container(

                  width: 60,
                  height: 60,

                  decoration:
                  BoxDecoration(

                    color:
                    isDark
                        ? Colors.white
                        .withOpacity(0.08)
                        : Colors.white,

                    shape: BoxShape.circle,
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
        ),
      ),
    );
  }

  Widget roleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
    required bool isDark,
  }) {

    return GestureDetector(

      onTap: () async {

        SharedPreferences prefs =

        await SharedPreferences
            .getInstance();

        if(
        title ==
            "Student"
        ){

          await prefs.setString(
            "userRole",
            "student",
          );
        }

        else if(
        title ==
            "Teacher"
        ){

          await prefs.setString(
            "userRole",
            "teacher",
          );
        }

        else{

          await prefs.setString(
            "userRole",
            "admin",
          );
        }

        Navigator.push(

          context,

          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },

      child: ClipRRect(

        borderRadius:
        BorderRadius.circular(30),

        child: BackdropFilter(

          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),

          child: Container(

            padding:
            const EdgeInsets.all(24),

            decoration: BoxDecoration(

              color:
              isDark
                  ? Colors.white
                  .withOpacity(0.08)
                  : Colors.white
                  .withOpacity(0.35),

              borderRadius:
              BorderRadius.circular(
                30,
              ),

              border: Border.all(
                color:
                Colors.white
                    .withOpacity(0.2),
              ),
            ),

            child: Row(

              children: [

                Container(

                  width: 70,
                  height: 70,

                  decoration:
                  BoxDecoration(
                    color:
                    color.withOpacity(
                      0.15,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),
                  ),

                  child: Icon(
                    icon,
                    color: color,
                    size: 38,
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Text(
                    title,

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,

                      color:
                      isDark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,

                  color:
                  isDark
                      ? Colors.white70
                      : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}