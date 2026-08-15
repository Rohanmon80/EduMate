import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF0B111A)
        : const Color(0xFFF5F7FB);

    final cardColor = isDark
        ? const Color(0xFF151D28)
        : Colors.white;

    final primaryColor = isDark
        ? const Color(0xFF64B5F6)
        : const Color(0xFF1565C0);

    final textColor = isDark
        ? Colors.white
        : const Color(0xFF172033);

    final secondaryTextColor = isDark
        ? Colors.white70
        : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            30,
          ),
          child: Column(
            children: [

              // -------------------------------------------------
              // HEADER
              // -------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        size: 34,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'EduMate Privacy & Security',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Important information about using EduMate safely, '
                          'protecting your account, and handling college data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------
              // ACCOUNT SECURITY
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.lock_outline_rounded,
                iconColor: primaryColor,
                title: 'Account Security',
                children: [
                  _bullet(
                    'Keep your EduMate password private.',
                    textColor,
                  ),
                  _bullet(
                    'Do not share your login credentials with another person.',
                    textColor,
                  ),
                  _bullet(
                    'Log out when using EduMate on a shared device.',
                    textColor,
                  ),
                  _bullet(
                    'Use biometric authentication when available on your device.',
                    textColor,
                  ),
                  _bullet(
                    'Contact the college administrator if you suspect '
                        'unauthorized access to your account.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // PRIVACY
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.privacy_tip_outlined,
                iconColor: primaryColor,
                title: 'Privacy & App Usage',
                children: [
                  _bullet(
                    'EduMate is intended for authorized college-related activities.',
                    textColor,
                  ),
                  _bullet(
                    'Do not attempt to access another user\'s account or information.',
                    textColor,
                  ),
                  _bullet(
                    'Do not share another person\'s private academic information '
                        'without permission.',
                    textColor,
                  ),
                  _bullet(
                    'Use information available in EduMate only for its intended '
                        'academic or administrative purpose.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // ACADEMIC INFORMATION
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.school_outlined,
                iconColor: primaryColor,
                title: 'Academic Information',
                children: [
                  _description(
                    'EduMate may display college-related information such as:',
                    textColor,
                  ),

                  _bullet('Attendance', textColor),
                  _bullet('Timetable', textColor),
                  _bullet('Subjects', textColor),
                  _bullet('Examination information', textColor),
                  _bullet('Marks and academic results', textColor),
                  _bullet('Fees information', textColor),
                  _bullet('Notices and study materials', textColor),
                  _bullet('Academic profile information', textColor),

                  const SizedBox(height: 8),

                  _description(
                    'For important academic matters, users should verify '
                        'information with the appropriate college authority when required.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // PROFILE INFORMATION
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.person_outline_rounded,
                iconColor: primaryColor,
                title: 'Profile Information',
                children: [
                  _description(
                    'Depending on your role, EduMate may display information such as:',
                    textColor,
                  ),

                  _bullet('Name', textColor),
                  _bullet('Email address', textColor),
                  _bullet('Phone number', textColor),
                  _bullet('Roll number or Teacher ID', textColor),
                  _bullet('Department', textColor),
                  _bullet('Year and semester', textColor),
                  _bullet('Section', textColor),
                  _bullet('Profile photo', textColor),

                  const SizedBox(height: 8),

                  _description(
                    'Keep your profile information accurate and do not intentionally '
                        'enter another person\'s information.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // FILES
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.folder_outlined,
                iconColor: primaryColor,
                title: 'Uploaded Files',
                children: [
                  _bullet(
                    'Upload only legitimate college-related documents.',
                    textColor,
                  ),
                  _bullet(
                    'Do not upload passwords, API keys, authentication tokens, '
                        'or other confidential credentials.',
                    textColor,
                  ),
                  _bullet(
                    'Avoid uploading unnecessary personal information.',
                    textColor,
                  ),
                  _bullet(
                    'Keep downloaded college documents secure on your device.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // RESPONSIBLE USE
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
                title: 'Responsible Use',
                children: [
                  _description(
                    'Users must not attempt to:',
                    textColor,
                  ),

                  _bullet(
                    'Bypass authentication or application security.',
                    textColor,
                  ),
                  _bullet(
                    'Access another user\'s private information.',
                    textColor,
                  ),
                  _bullet(
                    'Modify attendance or marks without authorization.',
                    textColor,
                  ),
                  _bullet(
                    'Interfere with the normal operation of EduMate.',
                    textColor,
                  ),
                  _bullet(
                    'Use college information for unauthorized purposes.',
                    textColor,
                  ),

                  const SizedBox(height: 8),

                  _description(
                    'Only authorized users should perform attendance, marks, '
                        'timetable, fee, and administrative operations.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // APP INSTRUCTIONS
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.menu_book_outlined,
                iconColor: primaryColor,
                title: 'How to Use EduMate',
                children: [
                  _numbered(
                    '1',
                    'Sign in using your authorized college account.',
                    textColor,
                  ),
                  _numbered(
                    '2',
                    'Check your profile information after signing in.',
                    textColor,
                  ),
                  _numbered(
                    '3',
                    'Use the Dashboard to access features available for your role.',
                    textColor,
                  ),
                  _numbered(
                    '4',
                    'Students can view attendance, timetable, examinations, '
                        'materials, fees, notices and other permitted information.',
                    textColor,
                  ),
                  _numbered(
                    '5',
                    'Teachers can access their assigned timetable and '
                        'attendance-related functions.',
                    textColor,
                  ),
                  _numbered(
                    '6',
                    'Administrators can manage authorized college data '
                        'and application functions.',
                    textColor,
                  ),
                  _numbered(
                    '7',
                    'Keep your device protected with a secure screen lock.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // SECURITY ISSUE
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.report_problem_outlined,
                iconColor: Colors.orange,
                title: 'If You Notice a Problem',
                children: [
                  _description(
                    'Contact the appropriate college administrator if you notice:',
                    textColor,
                  ),

                  _bullet('Incorrect attendance', textColor),
                  _bullet('Incorrect marks', textColor),
                  _bullet('Incorrect profile information', textColor),
                  _bullet('Unauthorized account activity', textColor),
                  _bullet('Suspicious application behavior', textColor),

                  const SizedBox(height: 8),

                  _description(
                    'Do not attempt to modify or bypass the system yourself.',
                    textColor,
                  ),
                ],
              ),

              // -------------------------------------------------
              // ROLE BASED ACCESS
              // -------------------------------------------------

              _section(
                context: context,
                isDark: isDark,
                cardColor: cardColor,
                icon: Icons.admin_panel_settings_outlined,
                iconColor: primaryColor,
                title: 'Role-Based Access',
                children: [
                  _description(
                    'EduMate provides different features depending on the '
                        'user role. Students, teachers and administrators may '
                        'have different permissions.',
                    textColor,
                  ),

                  const SizedBox(height: 8),

                  _bullet(
                    'Student accounts access student-related features.',
                    textColor,
                  ),
                  _bullet(
                    'Teacher accounts access teacher-related features.',
                    textColor,
                  ),
                  _bullet(
                    'Admin accounts access authorized management features.',
                    textColor,
                  ),

                  const SizedBox(height: 8),

                  _description(
                    'Do not attempt to access features that are not intended '
                        'for your account.',
                    textColor,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------
              // DEVELOPER
              // -------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 28,
                      color: primaryColor,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Developed by',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Rohan Mondal',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'EduMate College Management Application',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '© EduMate',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _section({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    final textColor = isDark
        ? Colors.white
        : const Color(0xFF172033);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            18,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  // ============================================================
  // BULLET
  // ============================================================

  Widget _bullet(
      String text,
      Color textColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 7,
              right: 10,
            ),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: textColor.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _description(
      String text,
      Color textColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: textColor.withOpacity(0.82),
        ),
      ),
    );
  }

  // ============================================================
  // NUMBERED ITEM
  // ============================================================

  Widget _numbered(
      String number,
      String text,
      Color textColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: textColor.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}