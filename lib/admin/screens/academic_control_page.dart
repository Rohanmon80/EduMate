import 'package:flutter/material.dart';
import 'semester_change_page.dart';
import 'result_release_page.dart';
import 'semester_change_page.dart';
import 'result_release_page.dart';

class AcademicControlPage extends StatelessWidget {
  const AcademicControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        title: const Text("Academic Control"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Academic Management",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Manage student semesters and release examination results.",
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [

                Expanded(
                  child: _controlCard(
                    context,
                    isDark: isDark,
                    icon: Icons.school,
                    title: "Semester Management",
                    description:
                    "Change the current semester and academic year of students.",
                    buttonText: "Manage Semester",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const SemesterChangePage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: _controlCard(
                    context,
                    isDark: isDark,
                    icon: Icons.publish,
                    title: "Result Release",
                    description:
                    "Check uploaded marks and release results to students.",
                    buttonText: "Manage Results",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ResultReleasePage(),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlCard(
      BuildContext context, {
        required bool isDark,
        required IconData icon,
        required String title,
        required String description,
        required String buttonText,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      color: isDark
          ? const Color(0xFF1E293B)
          : Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),

      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            CircleAvatar(
              radius: 30,
              child: Icon(
                icon,
                size: 30,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(icon),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}