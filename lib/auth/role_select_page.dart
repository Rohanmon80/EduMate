import 'package:flutter/material.dart';
import '../student/screens/student_login_page.dart';
import '../teacher/screens/teacher_login_page.dart';
import '../admin/screens/admin_login_page.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  Widget roleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),

          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
            ),
          ],
        ),

        child: Row(
          children: [

            CircleAvatar(
              radius: 30,
              backgroundColor: color,

              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,

                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F8FC),

      body: SafeArea(

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(

            children: [

              const SizedBox(height: 40),

              Image.asset(
                'assets/images/logo.png',
                height: 90,
              ),

              const SizedBox(height: 20),

              const Text(
                'EduMate',

                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007BFF),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Choose your role',
                style: TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 40),

              roleCard(
                context: context,
                title: 'Student',
                subtitle: 'Attendance, exams and notes',
                icon: Icons.school,
                color: Colors.blue,
                page: const StudentLoginPage(),
              ),

              roleCard(
                context: context,
                title: 'Teacher',
                subtitle: 'Manage classes and attendance',
                icon: Icons.person,
                color: Colors.teal,
                page: const TeacherLoginPage(),
              ),

              roleCard(
                context: context,
                title: 'Admin',
                subtitle: 'Fees and reports management',
                icon: Icons.admin_panel_settings,
                color: Colors.deepPurple,
                page: const AdminLoginPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}