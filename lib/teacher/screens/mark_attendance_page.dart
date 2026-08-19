import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../timetables/timetable_service.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  // ---------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------
  final TimetableService timetableService = TimetableService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------
  // Teacher info
  // ---------------------------------------------------------------------
  String teacherName = '';
  String teacherId = '';
  String teacherUid = '';

  // ---------------------------------------------------------------------
  // Loading flags
  // ---------------------------------------------------------------------
  bool isLoadingClasses = true;
  bool isLoadingStudents = false;
  bool isSaving = false;

  // ---------------------------------------------------------------------
  // Selection / data state
  // ---------------------------------------------------------------------
  String? selectedClassKey;

  List<Map<String, dynamic>> todayClasses = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> students = [];

  final Map<String, bool> attendance = {};

  DateTime selectedDate = DateTime.now();

  // ---------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------
  DateTime get today => DateTime.now();

  String get selectedDateKey => _dateKey(selectedDate);

  String get selectedDayName {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[selectedDate.weekday - 1];
  }

  Map<String, dynamic>? get selectedClass {
    if (selectedClassKey == null) return null;

    for (final item in todayClasses) {
      if (_classKey(item) == selectedClassKey) {
        return item;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    loadTeacherAndClasses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------
  String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 999999;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return 999999;

    return hour * 60 + minute;
  }

  String _formatHours(dynamic value) {
    final hours = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()} hr';
    }

    return '${hours.toStringAsFixed(2)} hr';
  }

  String _classKey(Map<String, dynamic> item) {
    return [
      item['timetableId'] ?? '',
      item['day'] ?? '',
      item['startTime'] ?? '',
      item['subject'] ?? '',
      item['section'] ?? '',
    ].join('|');
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        error ? Colors.red.shade700 : const Color(0xFF1565C0),
      ),
    );
  }

  bool _isCurrentClass(Map<String, dynamic> classInfo) {
    final start = _timeToMinutes(classInfo['startTime']?.toString() ?? '');
    final end = _timeToMinutes(classInfo['endTime']?.toString() ?? '');
    if (start == 999999 || end == 999999) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    return currentMinutes >= start && currentMinutes < end;
  }

  Map<String, dynamic>? _findCurrentClass(List<Map<String, dynamic>> classes) {
    for (final classInfo in classes) {
      if (_isCurrentClass(classInfo)) return classInfo;
    }
    return null;
  }

  Future<void> _autoOpenCurrentClass() async {
    final current = _findCurrentClass(todayClasses);
    if (current == null) return;
    await loadStudentsForClass(current);
  }

  // ---------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------
  Future<void> loadTeacherAndClasses() async {
    setState(() {
      isLoadingClasses = true;
    });

    try {
      final user = auth.currentUser;

      if (user == null) {
        throw Exception('Teacher is not logged in.');
      }

      final details = await timetableService.getUserDetails();

// Firebase Authentication UID
      teacherUid = user.uid;

// Actual teacher ID stored in Firebase teachers collection.
// Example: T006
      teacherId =
          details['teacherId']?.toString() ??
              details['id']?.toString() ??
              '';

      teacherName =
          details['name']?.toString() ?? 'Teacher';

      if (teacherId.isEmpty) {
        throw Exception(
          'Teacher ID was not found in your Firebase teacher profile.',
        );
      }

      // Sunday is a college closed day.
      if (selectedDayName == 'Sunday') {
        todayClasses = [];
        return;
      }

      final classes =
      await timetableService.getTeacherClassesForDay(
        teacherUid: teacherUid,
        teacherId: teacherId,
        day: selectedDayName,
      );

      classes.sort(
            (a, b) => _timeToMinutes(a['startTime']?.toString() ?? '')
            .compareTo(_timeToMinutes(b['startTime']?.toString() ?? '')),
      );

      todayClasses = classes;

      // Automatically open the timetable period that is happening now.
      // If there is no active period, the teacher can tap any assigned class.
      final currentClass = _findCurrentClass(todayClasses);
      if (currentClass != null) {
        // Do not block the class list from rendering; load the roster after
        // the timetable has been assigned.
        await _autoOpenCurrentClass();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to load assigned classes: $e', error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingClasses = false;
        });
      }
    }
  }

  Future<void> loadStudentsForClass(Map<String, dynamic> classInfo) async {
    final year = classInfo['year']?.toString();
    final department = classInfo['department']?.toString();
    final section = classInfo['section']?.toString();

    if (year == null ||
        department == null ||
        section == null ||
        year.isEmpty ||
        department.isEmpty ||
        section.isEmpty) {
      _showMessage(
        'This timetable class is missing year, department or section.',
        error: true,
      );
      return;
    }

    setState(() {
      selectedClassKey = _classKey(classInfo);
      isLoadingStudents = true;
      students = [];
      attendance.clear();
    });

    try {
      final query = await firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('year', isEqualTo: year)
          .where('department', isEqualTo: department)
          .where('section', isEqualTo: section)
          .get();

      final result = query.docs.toList();

      result.sort((a, b) {
        final aRoll = a.data()['rollNumber']?.toString() ?? '';
        final bRoll = b.data()['rollNumber']?.toString() ?? '';
        return aRoll.compareTo(bRoll);
      });

      for (final doc in result) {
        attendance[doc.id] = false;
      }

      await _loadExistingAttendance(classInfo);

      if (!mounted) return;

      setState(() {
        students = result;
        isLoadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingStudents = false;
      });

      _showMessage('Unable to load students: $e', error: true);
    }
  }

  Future<void> _loadExistingAttendance(Map<String, dynamic> classInfo) async {
    final snapshot = await firestore
        .collection('attendance_history')
        .where('timetableId', isEqualTo: classInfo['timetableId'])
        .where('dateKey', isEqualTo: selectedDateKey)
        .where('subject', isEqualTo: classInfo['subject'])
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final studentId = data['studentId']?.toString();

      if (studentId != null && studentId.isNotEmpty) {
        attendance[studentId] = data['present'] == true;
      }
    }
  }

  Future<bool> _alreadyMarked(Map<String, dynamic> classInfo) async {
    final classDate = selectedDateKey;

    final snapshot = await firestore
        .collection('attendance_history')
        .where('timetableId', isEqualTo: classInfo['timetableId'])
        .where('dateKey', isEqualTo: classDate)
        .where('subject', isEqualTo: classInfo['subject'])
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ---------------------------------------------------------------------
  // Date selection
  // ---------------------------------------------------------------------
  Future<void> pickAttendanceDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(now) ? now : selectedDate,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      helpText: 'Select attendance date',
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
      selectedClassKey = null;
      students = [];
      attendance.clear();
    });

    await loadTeacherAndClasses();
  }

  Future<void> resetToToday() async {
    setState(() {
      selectedDate = DateTime.now();
      selectedClassKey = null;
      students = [];
      attendance.clear();
    });

    await loadTeacherAndClasses();
  }

  // ---------------------------------------------------------------------
  // Save attendance
  // ---------------------------------------------------------------------
  Future<void> saveAttendance() async {
    final classInfo = selectedClass;

    if (classInfo == null) {
      _showMessage('Select one of the assigned classes first.', error: true);
      return;
    }

    if (students.isEmpty) {
      _showMessage('No students are loaded for this class.', error: true);
      return;
    }

    final type = classInfo['type']?.toString() ?? 'Theory';

    if (type == 'Library' || type == 'Sports') {
      _showMessage(
        '$type is configured as non-attendance and cannot be marked.',
        error: true,
      );
      return;
    }

    if (classInfo['countsForAttendance'] == false) {
      _showMessage(
        'This period is configured not to count for attendance.',
        error: true,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (await _alreadyMarked(classInfo)) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Attendance Already Exists'),
            content: const Text(
              'Attendance for this class today has already been '
                  'recorded. Do you want to open the class again and '
                  'replace the existing records?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (replace != true) {
          if (mounted) setState(() => isSaving = false);
          return;
        }

        // Delete today's records for this exact timetable class before
        // writing the corrected attendance.
        final existing = await firestore
            .collection('attendance_history')
            .where('timetableId', isEqualTo: classInfo['timetableId'])
            .where('dateKey', isEqualTo: selectedDateKey)
            .where('subject', isEqualTo: classInfo['subject'])
            .get();

        final batch = firestore.batch();

        for (final doc in existing.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      final hours = classInfo['hours'] is num
          ? (classInfo['hours'] as num).toDouble()
          : double.tryParse(classInfo['hours']?.toString() ?? '') ?? 1.0;

      final batch = firestore.batch();

      for (final student in students) {
        final studentData = student.data();
        final studentId = student.id;
        final isPresent = attendance[studentId] ?? false;

        final historyRef = firestore.collection('attendance_history').doc();

        batch.set(historyRef, {
          'studentId': studentId,
          'studentName': studentData['name'] ?? '',
          'rollNumber': studentData['rollNumber'] ?? '',
          'present': isPresent,

          // Weighted attendance data.
          'hours': hours,
          'presentHours': isPresent ? hours : 0.0,
          'scheduledHours': hours,

          'date': Timestamp.fromDate(selectedDate),
          'dateKey': selectedDateKey,
          'day': selectedDayName,

          'subject': classInfo['subject'] ?? '',
          'type': type,

          'teacher': teacherName,
          'teacherId': teacherId,
          'teacherUid': teacherUid,

          'timetableId': classInfo['timetableId'],
          'academicYear': classInfo['academicYear'],
          'semester': classInfo['semester'],
          'year': classInfo['year'],
          'department': classInfo['department'],
          'section': classInfo['section'],

          'startTime': classInfo['startTime'] ?? '',
          'endTime': classInfo['endTime'] ?? '',

          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      final present = attendance.values.where((v) => v).length;
      final absent = students.length - present;

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      await _showAttendanceResult(classInfo);

      if (!mounted) return;
      setState(() {
        attendance.clear();
      });

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Attendance Saved'),
          content: Text(
            '${classInfo['subject']}\n'
                '${classInfo['startTime']} - ${classInfo['endTime']}\n\n'
                'Present: $present\n'
                'Absent: $absent\n'
                'Class weight: ${_formatHours(hours)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });

        _showMessage('Failed to save attendance: $e', error: true);
      }
    }
  }

  // ---------------------------------------------------------------------
  // UI builders
  // ---------------------------------------------------------------------
  Widget _glassCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(.07) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classInfo, bool isDark) {
    final selected = _classKey(classInfo) == selectedClassKey;

    final type = classInfo['type']?.toString() ?? 'Theory';
    final counts = classInfo['countsForAttendance'] != false;

    final isLab = type.toLowerCase() == 'lab';

    return Card(
      elevation: selected ? 5 : 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? const Color(0xFF1565C0) : Colors.transparent,
          width: selected ? 2 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => loadStudentsForClass(classInfo),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                isLab ? Colors.deepPurple : const Color(0xFF1565C0),
                child: Icon(
                  isLab ? Icons.science_outlined : Icons.menu_book_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classInfo['subject']?.toString() ?? 'Subject',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${classInfo['startTime']} - ${classInfo['endTime']}'
                          ' • ${_formatHours(classInfo['hours'])}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${classInfo['year']} Year • '
                          '${classInfo['department']} • '
                          'Section ${classInfo['section']}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type • ${counts ? 'Attendance counted' : 'Not counted'}',
                      style: TextStyle(
                        color: counts
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudents(bool isDark) {
    if (isLoadingStudents) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (selectedClass == null) {
      return const Expanded(
        child: Center(
          child: Text(
            'Select the current timetable class above.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No students found for this class.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final presentCount = attendance.values.where((value) => value).length;
    final absentCount = students.length - presentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No search field: the complete class roster is always visible.
        Row(
          children: [
            Expanded(
              child: _attendanceCountChip(
                icon: Icons.check_circle,
                label: 'Present',
                count: presentCount,
                iconColor: Colors.green,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _attendanceCountChip(
                icon: Icons.cancel,
                label: 'Absent',
                count: absentCount,
                iconColor: Colors.red,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final data = student.data();
            final id = student.id;

            final name = data['name']?.toString() ?? 'Student';
            final roll = data['rollNumber']?.toString() ?? 'No Roll No';
            final present = attendance[id] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      child: Text(
                        roll.isNotEmpty
                            ? roll.substring(0, 1).toUpperCase()
                            : 'S',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roll,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Two direct controls on every student.
                    OutlinedButton(
                      onPressed: present
                          ? null
                          : () {
                        setState(() {
                          attendance[id] = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade600),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Present'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: present
                          ? () {
                        setState(() {
                          attendance[id] = false;
                        });
                      }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade600),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Absent'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _attendanceCountChip({
    required IconData icon,
    required String label,
    required int count,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttendanceResult(Map<String, dynamic> classInfo) async {
    final present = attendance.values.where((v) => v).length;
    final absent = students.length - present;
    final absentRollNumbers = students
        .where((student) => !(attendance[student.id] ?? false))
        .map((student) => student.data()['rollNumber']?.toString() ?? '')
        .where((roll) => roll.isNotEmpty)
        .toList();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Attendance Summary'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${classInfo['subject'] ?? ''}\n'
                    '${classInfo['startTime'] ?? ''} - ${classInfo['endTime'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Text('Total Students: ${students.length}'),
              Text('Present: $present'),
              Text('Absent: $absent'),
              const SizedBox(height: 14),
              const Text(
                'Absent Roll Numbers',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                absentRollNumbers.isEmpty
                    ? 'None — all students are present.'
                    : absentRollNumbers.join(', '),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> showAttendanceHistory() async {
    final snapshot = await firestore
        .collection('attendance_history')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final records = snapshot.docs.toList()
      ..sort((a, b) {
        final ad = a.data()['dateKey']?.toString() ?? '';
        final bd = b.data()['dateKey']?.toString() ?? '';
        final dateCompare = bd.compareTo(ad);
        if (dateCompare != 0) return dateCompare;

        final at = a.data()['startTime']?.toString() ?? '';
        final bt = b.data()['startTime']?.toString() ?? '';
        return bt.compareTo(at);
      });

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherAttendanceHistoryPage(
          teacherName: teacherName,
          records: records,
        ),
      ),
    );
  }


  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = selectedClass;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF081120) : const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor:
        isDark ? const Color(0xFF0D47A1) : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Attendance history',
            onPressed: teacherId.isEmpty ? null : showAttendanceHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _glassCard(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good day, $teacherName',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Teacher ID: $teacherId',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$selectedDayName, $selectedDateKey',
                            style:
                            const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _glassCard(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedDateKey == _dateKey(DateTime.now())
                              ? 'Today • $selectedDateKey'
                              : 'Edit Attendance • $selectedDateKey',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (selectedDateKey != _dateKey(DateTime.now()))
                        TextButton(
                          onPressed: resetToToday,
                          child: const Text('Today'),
                        ),
                      IconButton(
                        tooltip: 'Choose date',
                        onPressed: pickAttendanceDate,
                        icon: const Icon(Icons.edit_calendar),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (_findCurrentClass(todayClasses) != null) ...[
                _glassCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Current class: ${_findCurrentClass(todayClasses)?['subject'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Text(
                          'NOW',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Today’s Timetable',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (isLoadingClasses)
                const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (selectedDayName == 'Sunday')
                const Padding(
                  padding: EdgeInsets.all(22),
                  child: Text(
                    'Sunday is a college holiday. No attendance is taken.',
                    textAlign: TextAlign.center,
                  ),
                )
              else if (todayClasses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'No timetable classes are assigned to you today.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  SizedBox(
                    height: 190,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayClasses.length,
                      itemBuilder: (context, index) {
                        return _buildClassCard(todayClasses[index], isDark);
                      },
                    ),
                  ),

              if (selected != null) ...[
                const SizedBox(height: 10),
                _glassCard(
                  isDark: isDark,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.how_to_reg, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Marking: ${selected['subject']} • '
                                '${selected['startTime']} - '
                                '${selected['endTime']} • '
                                '${_formatHours(selected['hours'])}',
                            style:
                            const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              if (selected != null)
                _buildStudents(isDark)
              else
                const SizedBox(height: 24),

              if (selected != null)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : saveAttendance,
                          icon: isSaving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.save),
                          label: Text(
                            isSaving
                                ? 'Saving...'
                                : (selectedDateKey ==
                                _dateKey(DateTime.now())
                                ? 'Save Attendance'
                                : 'Update Attendance'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherAttendanceHistoryPage extends StatelessWidget {
  final String teacherName;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> records;

  const TeacherAttendanceHistoryPage({
    super.key,
    required this.teacherName,
    required this.records,
  });

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _groupRecords() {
    final grouped =
    <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final record in records) {
      final data = record.data();
      final key = [
        data['dateKey'] ?? '',
        data['timetableId'] ?? '',
        data['subject'] ?? '',
        data['startTime'] ?? '',
      ].join('|');

      grouped.putIfAbsent(key, () => []).add(record);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _groupRecords();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: isDark
            ? const Color(0xFF0D47A1)
            : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: records.isEmpty
          ? const Center(
        child: Text(
          'No attendance history found.',
          textAlign: TextAlign.center,
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Teacher: $teacherName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...groups.entries.map((entry) {
            final group = entry.value;
            final first = group.first.data();

            final present = group
                .where((doc) => doc.data()['present'] == true)
                .length;
            final absent = group.length - present;

            final absentRolls = group
                .where((doc) => doc.data()['present'] != true)
                .map((doc) =>
            doc.data()['rollNumber']?.toString() ?? '')
                .where((roll) => roll.isNotEmpty)
                .toList()
              ..sort();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16,
                ),
                title: Text(
                  '${first['subject'] ?? 'Subject'} • '
                      '${first['dateKey'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${first['startTime'] ?? ''} - '
                      '${first['endTime'] ?? ''} • '
                      '${first['year'] ?? ''} Year • '
                      '${first['department'] ?? ''} • '
                      'Section ${first['section'] ?? ''}',
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _historyStat(
                          'Present',
                          '$present',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _historyStat(
                          'Absent',
                          '$absent',
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _historyStat(
                          'Total',
                          '${group.length}',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      absentRolls.isEmpty
                          ? 'Absent Roll Numbers: None'
                          : 'Absent Roll Numbers: ${absentRolls.join(', ')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  ...group.map((doc) {
                    final data = doc.data();
                    final isPresent = data['present'] == true;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isPresent
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: isPresent ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        data['rollNumber']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        data['studentName']?.toString() ?? 'Student',
                      ),
                      trailing: Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color:
                          isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _historyStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
