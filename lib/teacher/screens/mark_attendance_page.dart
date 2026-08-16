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

  final TextEditingController searchController = TextEditingController();

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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get filteredStudents {
    final search = searchController.text.trim().toLowerCase();

    if (search.isEmpty) return students;

    return students.where((doc) {
      final data = doc.data();

      final name = data['name']?.toString().toLowerCase() ?? '';
      final roll = data['rollNumber']?.toString().toLowerCase() ?? '';

      return name.contains(search) || roll.contains(search);
    }).toList();
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
    searchController.dispose();
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
            'Select one of today\'s classes above.',
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

    final visible = filteredStudents;

    return Expanded(
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search roll number or student name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final student = visible[index];
                final data = student.data();
                final id = student.id;

                final name = data['name']?.toString() ?? 'Student';
                final roll = data['rollNumber']?.toString() ?? '';

                attendance.putIfAbsent(id, () => false);

                final present = attendance[id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(name.isEmpty ? 'S' : name[0].toUpperCase()),
                    ),
                    title: Text(
                      '$roll - $name',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      present ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: present ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Switch(
                      value: present,
                      onChanged: (value) {
                        setState(() {
                          attendance[id] = value;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            tooltip: 'Refresh classes',
            onPressed: isLoadingClasses ? null : loadTeacherAndClasses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
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

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Assigned Classes',
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
                            '${selected['subject']} • '
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
                const Spacer(),

              if (selected != null)
                SizedBox(
                  width: double.infinity,
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
                          : (selectedDateKey == _dateKey(DateTime.now())
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
            ],
          ),
        ),
      ),
    );
  }
}
