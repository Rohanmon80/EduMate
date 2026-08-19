import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherPptViewPage extends StatelessWidget {
  const TeacherPptViewPage({super.key});

  Future<void> _openPpt(
      BuildContext context,
      String fileUrl,
      ) async {
    if (fileUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PPT file is not available.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(fileUrl);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PPT file URL.'),
        ),
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the PPT file.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open PPT: $e'),
        ),
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Date not available';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final teacherUid =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Student PPT Submissions',
        ),
      ),
      body: teacherUid == null
          ? const Center(
        child: Text(
          'Teacher is not logged in.',
        ),
      )
          : StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ppt_submissions')
            .where(
          'teacherUid',
          isEqualTo: teacherUid,
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load PPT submissions.\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final submissions =
              snapshot.data?.docs.toList() ?? [];

          submissions.sort((a, b) {
            final aTime = a.data()['submittedAt'];
            final bTime = b.data()['submittedAt'];

            final aDate = aTime is Timestamp
                ? aTime.toDate()
                : DateTime(2000);

            final bDate = bTime is Timestamp
                ? bTime.toDate()
                : DateTime(2000);

            return bDate.compareTo(aDate);
          });

          if (submissions.isEmpty) {
            return _emptyState(isDark);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                _summaryCard(
                  isDark,
                  submissions.length,
                ),
                const SizedBox(height: 20),
                ...submissions.map(
                      (doc) => _submissionCard(
                    context,
                    doc,
                    isDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(
      bool isDark,
      int count,
      ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.12),
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.slideshow,
                  color: Colors.red,
                  size: 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PPT Submissions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$count student${count == 1 ? '' : 's'} submitted',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor:
                Colors.green.withOpacity(.12),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _submissionCard(
      BuildContext context,
      QueryDocumentSnapshot<
          Map<String, dynamic>> doc,
      bool isDark,
      ) {
    final data = doc.data();

    final studentName =
    (data['studentName'] ?? 'Student').toString();

    final rollNumber =
    (data['rollNumber'] ?? '-').toString();

    final department =
    (data['department'] ?? '-').toString();

    final year =
    (data['year'] ?? '-').toString();

    final semester =
    (data['semester'] ?? '-').toString();

    final section =
    (data['section'] ?? '-').toString();

    final pptTitle =
    (data['pptTitle'] ?? 'Untitled PPT').toString();

    final fileName =
    (data['fileName'] ?? 'PPT file').toString();

    final fileUrl =
    (data['fileUrl'] ?? '').toString();

    final status =
    (data['status'] ?? 'submitted').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? Colors.white12
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                      Colors.red.withOpacity(.12),
                      child: const Icon(
                        Icons.slideshow,
                        color: Colors.red,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            pptTitle,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withOpacity(.12),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _infoRow(
                  Icons.person,
                  'Student',
                  studentName,
                  isDark,
                ),

                _infoRow(
                  Icons.badge,
                  'Roll Number',
                  rollNumber,
                  isDark,
                ),

                _infoRow(
                  Icons.school,
                  'Class',
                  '$year • Sem $semester • Sec $section',
                  isDark,
                ),

                _infoRow(
                  Icons.account_balance,
                  'Department',
                  department,
                  isDark,
                ),

                _infoRow(
                  Icons.access_time,
                  'Submitted',
                  _formatDate(data['submittedAt']),
                  isDark,
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: fileUrl.isEmpty
                        ? null
                        : () => _openPpt(
                      context,
                      fileUrl,
                    ),
                    icon: const Icon(
                      Icons.visibility,
                    ),
                    label: Text(
                      fileUrl.isEmpty
                          ? 'PPT File Not Available'
                          : 'View PPT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String title,
      String value,
      bool isDark,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white70
                    : Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open,
                size: 55,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'No PPT Submissions Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Student PPTs assigned to you will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
