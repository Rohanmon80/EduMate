import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AttendanceService attendanceService = AttendanceService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool isDark = false;
  bool loading = true;
  bool refreshing = false;

  String studentId = '';
  String studentName = '';

  String academicYear = '';
  String semester = '';

  String studentYear = '';
  String studentDepartment = '';
  String studentSection = '';
  bool attendanceCycleStarted = false;
  String attendanceStatusMessage = '';

  double semesterPercentage = 0;
  double cyclePercentage = 0;

  Map<String, dynamic> semesterSummary = {};
  Map<String, dynamic> cycleSummary = {};

  List<Map<String, dynamic>> subjectSummaries = [];
  List<Map<String, dynamic>> recentHistory = [];

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      attendanceCycleStarted = false;
      attendanceStatusMessage = '';
    });

    try {
      final user = auth.currentUser;

      if (user == null) {
        throw Exception('Student is not logged in.');
      }

      studentId = user.uid;

      final userDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? {};

      studentName =
          data['name']?.toString() ??
              data['fullName']?.toString() ??
              'Student';

      academicYear =
          data['academicYear']?.toString() ??
              data['session']?.toString() ??
              data['batch']?.toString() ??
              '';

      semester =
          data['semester']?.toString() ??
              data['currentSemester']?.toString() ??
              '';

      studentYear = data['year']?.toString() ?? '';
      studentDepartment =
          data['department']?.toString() ??
              data['branch']?.toString() ??
              data['course']?.toString() ??
              '';
      studentSection = data['section']?.toString() ?? '';

      Map<String, dynamic>? config;

      // 1. If the student's profile already contains academicYear + semester,
      //    check the exact attendance_config document first.
      if (academicYear.isNotEmpty && semester.isNotEmpty) {
        final configDoc = await firestore
            .collection('attendance_config')
            .doc('${academicYear}_$semester')
            .get();

        if (configDoc.exists) {
          config = configDoc.data();
        }
      }

      // 2. If the profile does not have the current academic year/semester,
      //    find the configuration belonging to this student's year/department/
      //    section. We intentionally do not use orderBy here, so this does not
      //    require an extra composite index.
      if (config == null && studentYear.isNotEmpty) {
        Query<Map<String, dynamic>> query = firestore
            .collection('attendance_config')
            .where('year', isEqualTo: studentYear);

        if (studentDepartment.isNotEmpty) {
          query = query.where(
            'department',
            isEqualTo: studentDepartment,
          );
        }

        if (studentSection.isNotEmpty) {
          query = query.where(
            'section',
            isEqualTo: studentSection,
          );
        }

        final snapshot = await query.limit(20).get();

        if (snapshot.docs.isNotEmpty) {
          // Prefer an active configuration. If none is active, use the
          // configuration with the latest startedAt value so the UI can
          // still identify the student's current academic year/semester.
          QueryDocumentSnapshot<Map<String, dynamic>>? selected;
          DateTime? selectedStartedAt;

          for (final doc in snapshot.docs) {
            final item = doc.data();

            if (item['active'] == true) {
              selected = doc;
              break;
            }

            final rawStartedAt = item['startedAt'];
            DateTime? startedAt;

            if (rawStartedAt is Timestamp) {
              startedAt = rawStartedAt.toDate();
            } else if (rawStartedAt is DateTime) {
              startedAt = rawStartedAt;
            } else if (rawStartedAt is String) {
              startedAt = DateTime.tryParse(rawStartedAt);
            }

            if (selected == null ||
                (startedAt != null &&
                    (selectedStartedAt == null ||
                        startedAt.isAfter(selectedStartedAt!)))) {
              selected = doc;
              selectedStartedAt = startedAt;
            }
          }

          selected ??= snapshot.docs.first;
          config = selected.data();
        }
      }

      // 3. Last fallback: use the most recent attendance history record.
      //    This only helps identify the year/semester; it does not mean the
      //    attendance cycle is started.
      if ((academicYear.isEmpty || semester.isEmpty) && config == null) {
        final latest = await firestore
            .collection('attendance_history')
            .where(
          'studentId',
          isEqualTo: studentId,
        )
            .orderBy(
          'date',
          descending: true,
        )
            .limit(1)
            .get();

        if (latest.docs.isNotEmpty) {
          final latestData = latest.docs.first.data();

          academicYear = academicYear.isEmpty
              ? latestData['academicYear']?.toString() ?? ''
              : academicYear;

          semester = semester.isEmpty
              ? latestData['semester']?.toString() ?? ''
              : semester;
        }
      }

      // Use the configuration as the source of truth when it contains the
      // academic year and semester.
      if (config != null) {
        final configYear = config['academicYear']?.toString() ?? '';
        final configSemester = config['semester']?.toString() ?? '';

        if (configYear.isNotEmpty) academicYear = configYear;
        if (configSemester.isNotEmpty) semester = configSemester;

        attendanceCycleStarted = config['active'] == true;

        if (!attendanceCycleStarted) {
          final yearText = academicYear.isEmpty
              ? (studentYear.isEmpty ? 'your year' : studentYear)
              : academicYear;

          final semesterText = semester.isEmpty
              ? ''
              : ' (Semester $semester)';

          attendanceStatusMessage =
          'Admin has not started the attendance cycle for '
              '$yearText$semesterText yet.';
        }
      } else if (academicYear.isNotEmpty && semester.isNotEmpty) {
        // The profile knows the student's academic period, but Admin has not
        // created/started a matching attendance configuration yet.
        attendanceCycleStarted = false;
        attendanceStatusMessage =
        'Admin has not started the attendance cycle for '
            '$academicYear (Semester $semester) yet.';
      } else {
        attendanceCycleStarted = false;
        final yearText = studentYear.isEmpty ? 'your year' : studentYear;
        attendanceStatusMessage =
        'Admin has not started the attendance cycle for $yearText yet.';
      }

      // Always keep the page usable. When the cycle is not started, show the
      // normal attendance UI with zero/empty data instead of replacing it
      // with a blocking "configuration pending" screen.
      semesterSummary = {
        'percentage': 0.0,
        'scheduledHours': 0.0,
        'presentHours': 0.0,
        'absentHours': 0.0,
        'isStarted': attendanceCycleStarted,
      };

      cycleSummary = {
        'percentage': 0.0,
        'scheduledHours': 0.0,
        'presentHours': 0.0,
        'absentHours': 0.0,
        'cycleNumber': 0,
      };

      semesterPercentage = 0;
      cyclePercentage = 0;
      subjectSummaries = [];
      recentHistory = [];

      if (attendanceCycleStarted &&
          academicYear.isNotEmpty &&
          semester.isNotEmpty) {
        semesterSummary =
        await attendanceService.getSemesterSummary(
          studentId: studentId,
          academicYear: academicYear,
          semester: semester,
        );

        cycleSummary =
        await attendanceService.getCurrentCycleSummary(
          studentId: studentId,
          academicYear: academicYear,
          semester: semester,
        );

        semesterPercentage =
            _number(semesterSummary['percentage']);

        cyclePercentage =
            _number(cycleSummary['percentage']);

        subjectSummaries =
        await attendanceService.getSubjectSummaries(
          studentId: studentId,
          academicYear: academicYear,
          semester: semester,
        );

        final history =
        await attendanceService.getAttendanceHistory(
          studentId: studentId,
          academicYear: academicYear,
          semester: semester,
        );

        recentHistory = history.reversed.take(5).toList();
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to load attendance: $e',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          refreshing = false;
        });

        if (!attendanceCycleStarted &&
            attendanceStatusMessage.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showWarningMessage(attendanceStatusMessage);
            }
          });
        }
      }
    }
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _hours(dynamic value) {
    final number = _number(value);

    if (number == number.roundToDouble()) {
      return '${number.toInt()} hr';
    }

    return '${number.toStringAsFixed(1)} hr';
  }

  Color _attendanceColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _attendanceMessage(double percentage) {
    if (percentage >= 85) {
      return 'Excellent! Keep maintaining your attendance.';
    }

    if (percentage >= 75) {
      return 'Great! Your attendance is above the target.';
    }

    if (percentage >= 60) {
      return 'Your attendance is below the target. Try to attend more classes.';
    }

    return 'Attendance is low. You need to improve your attendance.';
  }

  String _date(dynamic value) {
    if (value == null) return '--';

    final text = value.toString();

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  void _showWarningMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> refresh() async {
    if (refreshing) return;

    setState(() {
      refreshing = true;
    });

    await loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: isDark
            ? const Color(0xFF0D47A1)
            : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: refreshing ? null : refresh,
            icon: refreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),

              if (!attendanceCycleStarted &&
                  attendanceStatusMessage.isNotEmpty)
                _buildCycleNotStartedNotice(),
              _buildPercentageCards(),
              const SizedBox(height: 18),
              _buildSemesterDetails(),
              const SizedBox(height: 22),
              _buildWeeklyGraph(),
              const SizedBox(height: 25),
              _buildSubjectAttendance(),
              const SizedBox(height: 25),
              _buildRecentAttendance(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16213E)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1565C0),
            child: Text(
              studentName.isEmpty
                  ? 'S'
                  : studentName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF0B1736),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  academicYear.isEmpty
                      ? 'Attendance'
                      : '$academicYear • Semester $semester',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleNotStartedNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16213E)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.orange.withOpacity(.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.orange,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance cycle not started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF6B4E00),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  attendanceStatusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageCards() {
    final cycleColor = _attendanceColor(cyclePercentage);
    final semesterColor = _attendanceColor(semesterPercentage);

    return Row(
      children: [
        Expanded(
          child: _percentageCard(
            title: 'Present Cycle',
            percentage: cyclePercentage,
            color: cycleColor,
            subtitle: cycleSummary['cycleNumber'] == 0
                ? 'No cycle data'
                : 'Cycle ${cycleSummary['cycleNumber']}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _percentageCard(
            title: 'Semester',
            percentage: semesterPercentage,
            color: semesterColor,
            subtitle: 'Semester $semester',
          ),
        ),
      ],
    );
  }

  Widget _percentageCard({
    required String title,
    required double percentage,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16213E)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? Colors.white70
                  : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white60
                  : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterDetails() {
    final scheduled =
    _number(semesterSummary['scheduledHours']);
    final present =
    _number(semesterSummary['presentHours']);
    final absent =
    _number(semesterSummary['absentHours']);

    return _sectionCard(
      title: 'Semester Attendance',
      icon: Icons.school_outlined,
      child: Row(
        children: [
          Expanded(
            child: _stat(
              'Present',
              _hours(present),
              Colors.green,
            ),
          ),
          Expanded(
            child: _stat(
              'Absent',
              _hours(absent),
              Colors.red,
            ),
          ),
          Expanded(
            child: _stat(
              'Total',
              _hours(scheduled),
              const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGraph() {
    return _sectionCard(
      title: 'Weekly Attendance',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 210,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('attendance_history')
              .where(
            'studentId',
            isEqualTo: studentId,
          )
              .where(
            'academicYear',
            isEqualTo: academicYear,
          )
              .where(
            'semester',
            isEqualTo: semester,
          )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // Monday-Saturday. Sunday is deliberately omitted because
            // Sunday is a college-closed day.
            final scheduled = List<double>.filled(6, 0);
            final present = List<double>.filled(6, 0);

            for (final doc in docs) {
              final data = doc.data();
              final date =
              _parseHistoryDate(data);

              if (date == null) continue;

              final index = date.weekday - 1;

              if (index < 0 || index > 5) continue;

              final total =
              _number(data['scheduledHours']);
              final presentHours =
              data.containsKey('presentHours')
                  ? _number(data['presentHours'])
                  : data['present'] == true
                  ? total
                  : 0;

              scheduled[index] += total;
              present[index] += presentHours;
            }

            final values = List<double>.generate(
              6,
                  (index) => scheduled[index] == 0
                  ? 0
                  : (present[index] / scheduled[index])
                  .clamp(0, 1),
            );

            return Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceAround,
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 6; i++)
                  _graphBar(
                    const [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                    ][i],
                    values[i],
                    scheduled[i],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  DateTime? _parseHistoryDate(
      Map<String, dynamic> data,
      ) {
    final timestamp = data['date'];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    final dateKey = data['dateKey']?.toString();

    if (dateKey != null && dateKey.isNotEmpty) {
      return DateTime.tryParse(dateKey);
    }

    return null;
  }

  Widget _graphBar(
      String day,
      double value,
      double totalHours,
      ) {
    final percent = value * 100;
    final color = _attendanceColor(percent);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          totalHours == 0
              ? '--'
              : '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark
                ? Colors.white70
                : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 120,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 28,
            height: totalHours == 0
                ? 5
                : (120 * value).clamp(5, 120),
            decoration: BoxDecoration(
              color: totalHours == 0
                  ? Colors.grey.shade400
                  : color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectAttendance() {
    return _sectionCard(
      title: 'Subject Attendance',
      icon: Icons.menu_book_outlined,
      child: subjectSummaries.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(15),
        child: Text(
          'No attendance has been recorded yet.',
          textAlign: TextAlign.center,
        ),
      )
          : Column(
        children: subjectSummaries.map((item) {
          final subject =
              item['subject']?.toString() ??
                  'Unknown Subject';

          final type =
              item['type']?.toString() ??
                  'Theory';

          final percentage =
          _number(item['percentage']);

          final scheduled =
          _number(item['scheduledHours']);

          final present =
          _number(item['presentHours']);

          return _attendanceTile(
            subject: subject,
            type: type,
            percentage: percentage,
            present: present,
            scheduled: scheduled,
          );
        }).toList(),
      ),
    );
  }

  Widget _attendanceTile({
    required String subject,
    required String type,
    required double percentage,
    required double present,
    required double scheduled,
  }) {
    final color = _attendanceColor(percentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(.05)
            : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type • ${_hours(present)} / ${_hours(scheduled)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white60
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendance() {
    return _sectionCard(
      title: 'Recent Attendance',
      icon: Icons.history,
      child: recentHistory.isEmpty
          ? const Text(
        'No recent attendance records.',
      )
          : Column(
        children: recentHistory.map((record) {
          final present =
              record['present'] == true;

          return ListTile(
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 0,
            ),
            leading: CircleAvatar(
              backgroundColor: present
                  ? Colors.green.withOpacity(.12)
                  : Colors.red.withOpacity(.12),
              child: Icon(
                present
                    ? Icons.check
                    : Icons.close,
                color: present
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            title: Text(
              record['subject']?.toString() ??
                  'Subject',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${_date(record['dateKey'])} • '
                  '${_hours(record['scheduledHours'])}',
            ),
            trailing: Text(
              present ? 'Present' : 'Absent',
              style: TextStyle(
                color: present
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16213E)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF0B1736),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _stat(
      String label,
      String value,
      Color color,
      ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Colors.white60
                : Colors.black54,
          ),
        ),
      ],
    );
  }
}
