import 'package:flutter/material.dart';
import 'mid_marks_page.dart';
import 'lab_marks_page.dart';
import 'memo_page.dart';
import 'results_page.dart';

class MarksDetailsPage extends StatelessWidget {
  const MarksDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Marks Details",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            28,
            18,
            30,
          ),
          children: [

            // ==================================================
            // MID MARKS
            // ==================================================

            _marksCard(
              context: context,
              title: "Mid Marks",
              icon: Icons.assignment,
              iconBackground:
              const Color(0xFFFFE9BF),
              iconColor:
              const Color(0xFFFFA000),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const MidMarksPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // LAB MARKS
            // ==================================================

            _marksCard(
              context: context,
              title: "Lab Marks",
              icon: Icons.science,
              iconBackground:
              const Color(0xFFDFF4E3),
              iconColor:
              const Color(0xFF43A047),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const LabMarksPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // RESULTS
            // ==================================================

            _marksCard(
              context: context,
              title: "Results",
              icon: Icons.bar_chart,
              iconBackground:
              const Color(0xFFDCEFFF),
              iconColor:
              const Color(0xFF2196F3),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SemesterResultsPage()
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // MEMOS
            // ==================================================

            _marksCard(
              context: context,
              title: "Memos",
              icon: Icons.description,
              iconBackground:
              const Color(0xFFE9DDF8),
              iconColor:
              const Color(0xFF673AB7),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemoPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MARKS CARD
  // ============================================================

  Widget _marksCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius:
        BorderRadius.circular(28),

        child: Container(
          height: 190,

          padding:
          const EdgeInsets.symmetric(
            horizontal: 28,
          ),

          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF182536)
                : Colors.white,

            borderRadius:
            BorderRadius.circular(28),

            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 6),
                color: Colors.black
                    .withValues(alpha: 0.08),
              ),
            ],
          ),

          child: Row(
            children: [

              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 100,
                height: 100,

                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  size: 52,
                  color: iconColor,
                ),
              ),

              const SizedBox(width: 34),

              // ==================================================
              // TITLE
              // ==================================================

              Expanded(
                child: Text(
                  title,

                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF171717),
                  ),
                ),
              ),

              // ==================================================
              // ARROW
              // ==================================================

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 30,
                color: isDark
                    ? Colors.white70
                    : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

