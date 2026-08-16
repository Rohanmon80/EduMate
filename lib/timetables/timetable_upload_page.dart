import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/excel_service.dart';

class TimetableUploadPage extends StatefulWidget {
  final bool isAdmin;

  const TimetableUploadPage({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<TimetableUploadPage> createState() => _TimetableUploadPageState();
}

class _TimetableUploadPageState extends State<TimetableUploadPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> _normalizeSchedule(
      Map<String, List<Map<String, dynamic>>> parsed,
      ) {
    return {
      for (final day in days)
        day: List<Map<String, dynamic>>.from(
          parsed[day] ?? <Map<String, dynamic>>[],
        ),
    };
  }
  final FirebaseAuth auth = FirebaseAuth.instance;
  final SupabaseClient supabase = Supabase.instance.client;

  String teacherName = '';
  String teacherId = '';
  String teacherDepartment = '';

  File? selectedPdf;

  // Timetable Excel is the source of truth for structured attendance.
  final ExcelService excelService = ExcelService();
  List<List<dynamic>>? selectedTimetableExcelRows;
  bool isParsingExcel = false;
  bool isUploadingExcel = false;
  String? selectedExcelName;
  String? excelValidationMessage;

  String selectedAcademicYear = '2026-2027';
  String selectedSemester = '1';
  String selectedYear = '1st';
  String selectedDepartment = 'CSE';
  String selectedSection = 'A';

  Map<String, dynamic>? currentTimetable;
  String? currentDocId;

  bool isLoading = true;
  bool isSearching = false;
  bool isUploading = false;
  bool isSavingSchedule = false;
  bool isStartingAttendance = false;

  final List<String> academicYears = [
    '2025-2026',
    '2026-2027',
    '2027-2028',
    '2028-2029',
  ];

  final List<String> semesters = ['1', '2'];

  final List<String> years = ['1st', '2nd', '3rd', '4th'];

  final List<String> departments = [
    'CSE',
    'AIML',
    'CSM',
    'ECE',
    'EEE',
  ];

  final List<String> sections = ['A', 'B', 'C', 'D'];

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> periodTypes = [
    'Theory',
    'Lab',
    'Library',
    'Sports',
    'Other',
  ];

  List<Map<String, dynamic>> teachers = [];

  Map<String, List<Map<String, dynamic>>> schedule = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
  };

  List<Map<String, dynamic>> holidays = [];

  DateTime? attendanceStartDate;
  DateTime? attendanceEndDate;
  bool attendanceCalculationStarted = false;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime value) {
    final d = _dateOnly(value);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String get documentId =>
      '${selectedAcademicYear}_${selectedSemester}_${selectedYear}_${selectedDepartment}_${selectedSection}';

  String get storagePath =>
      '$selectedAcademicYear/$selectedSemester/'
          '$selectedYear/$selectedDepartment/$selectedSection/timetable.pdf';

  @override
  void initState() {
    super.initState();
    loadTeacherDetails();
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        error ? Colors.red.shade700 : const Color(0xFF1565C0),
      ),
    );
  }

  Future<void> loadTeacherDetails() async {
    try {
      final user = auth.currentUser;

      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      teacherId = user.uid;

      final collection = widget.isAdmin ? 'admins' : 'teachers';

      final query = await firestore
          .collection(collection)
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();

        teacherName = (data['name'] ?? (widget.isAdmin ? 'Admin' : 'Teacher'))
            .toString();

        teacherDepartment = widget.isAdmin
            ? 'Administrator'
            : (data['department'] ?? '').toString();
      } else {
        showMessage(
          widget.isAdmin
              ? 'Admin profile not found'
              : 'Teacher profile not found',
          error: true,
        );
      }

      if (widget.isAdmin) {
        await loadTeachers();
      }

      if (mounted) {
        setState(() => isLoading = false);
      }

      await searchTimetable();
      await loadHolidays();
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      showMessage(e.toString(), error: true);
    }
  }

  Future<void> loadTeachers() async {
    final snap = await firestore.collection('teachers').get();

    teachers = snap.docs.map((doc) {
      final data = doc.data();

      // The Firestore document ID IS the Firebase Auth uid for teacher docs.
      final firebaseUid = doc.id;

      // Your schema stores the human-readable faculty ID in the "id" field.
      final facultyId = (
          data['id'] ??
              data['teacherId'] ??
              data['facultyId'] ??
              firebaseUid
      ).toString();

      return {
        'id': doc.id,
        'uid': firebaseUid,
        'teacherId': facultyId,
        'name': (data['name'] ?? 'Unnamed Teacher').toString(),
        'email': (data['email'] ?? '').toString(),
        'department': (data['department'] ?? '').toString(),
      };
    }).toList();

    teachers.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
    );
  }

  Future<void> pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.first.path == null) return;

    if (result.files.first.size > 20 * 1024 * 1024) {
      showMessage('Maximum PDF size is 20 MB', error: true);
      return;
    }

    setState(() {
      selectedPdf = File(result.files.first.path!);
    });
  }
  Future<void> openPDF(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      showMessage('Invalid PDF URL', error: true);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        showMessage('Unable to open PDF', error: true);
      }
    } catch (e) {
      showMessage('Unable to open PDF: $e', error: true);
    }
  }

  Future<void> searchTimetable() async {
    if (!mounted) return;

    setState(() => isSearching = true);

    try {
      final doc = await firestore
          .collection('timetables')
          .doc(documentId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          currentTimetable = data;
          currentDocId = doc.id;
          _loadScheduleFromFirestore(data);
          _loadAttendanceConfigFromFirestore(data);
        });
      } else {
        setState(() {
          currentTimetable = null;
          currentDocId = null;
          _resetSchedule();
          attendanceCalculationStarted = false;
          attendanceStartDate = null;
          attendanceEndDate = null;
        });
      }
    } catch (e) {
      showMessage(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  void _resetSchedule() {
    schedule = {
      for (final day in days) day: <Map<String, dynamic>>[],
    };
  }

  void _loadScheduleFromFirestore(Map<String, dynamic> data) {
    _resetSchedule();

    final raw = data['schedule'];

    if (raw is! Map) return;

    for (final day in days) {
      final items = raw[day];

      if (items is List) {
        schedule[day] = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    for (final day in days) {
      schedule[day]!.sort(
            (a, b) => _timeToMinutes(
          a['startTime']?.toString() ?? '',
        ).compareTo(
          _timeToMinutes(
            b['startTime']?.toString() ?? '',
          ),
        ),
      );
    }
  }

  void _loadAttendanceConfigFromFirestore(Map<String, dynamic> data) {
    final active = data['attendanceCalculationStarted'] == true;

    final startRaw = data['attendanceStartDate'];
    final endRaw = data['attendanceEndDate'];

    DateTime? parse(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    attendanceCalculationStarted = active;
    attendanceStartDate = parse(startRaw);
    attendanceEndDate = parse(endRaw);
  }
  Future<void> downloadTimetableTemplate() async {
    if (!widget.isAdmin) return;

    try {
      await excelService.downloadTimetableTemplate();

      if (!mounted) return;

      showMessage(
        'Timetable Excel template created successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Unable to create timetable template: $e',
        error: true,
      );
    }
  }

  Future<void> pickTimetableExcel() async {
    if (!widget.isAdmin) return;

    setState(() {
      isParsingExcel = true;
      excelValidationMessage = null;
    });

    try {
      final rows = await excelService.pickTimetableExcel();

      if (rows.isEmpty) {
        if (mounted) {
          setState(() => isParsingExcel = false);
        }
        return;
      }

      // Parse and validate before changing the saved Firebase timetable.
      final parsed = excelService.parseTimetableExcel(
        rows: rows,
        teachers: teachers,
      );

      final totalPeriods = parsed.values.fold<int>(
        0,
            (sum, list) => sum + list.length,
      );

      if (totalPeriods == 0) {
        throw Exception('No valid timetable periods were found.');
      }

      if (!mounted) return;

      setState(() {
        selectedTimetableExcelRows = rows;
        schedule = _normalizeSchedule(parsed);
        selectedExcelName = 'Timetable Excel selected';
        excelValidationMessage =
        '✓ $totalPeriods periods validated successfully. '
            'All Teacher IDs were matched with Firebase.';
      });

      showMessage(
        'Excel validated successfully. Review the structured timetable and save it.',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          selectedTimetableExcelRows = null;
          excelValidationMessage = null;
        });
      }

      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => isParsingExcel = false);
      }
    }
  }

  Future<void> uploadOptionalPDF() async {
    if (!widget.isAdmin) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.first.path == null) return;

    if (result.files.first.size > 20 * 1024 * 1024) {
      showMessage('Maximum PDF size is 20 MB', error: true);
      return;
    }

    setState(() {
      selectedPdf = File(result.files.first.path!);
    });

    await uploadPDFOnly();
  }

  Future<void> uploadPDFOnly() async {
    if (selectedPdf == null || !widget.isAdmin) return;

    setState(() => isUploading = true);

    try {
      final existing = await firestore
          .collection('timetables')
          .doc(documentId)
          .get();

      if (existing.exists) {
        final oldPath = existing.data()?['filePath']?.toString() ?? '';

        if (oldPath.isNotEmpty && oldPath != storagePath) {
          try {
            await supabase.storage
                .from('timetables')
                .remove([oldPath]);
          } catch (_) {}
        }
      }

      await supabase.storage.from('timetables').upload(
        storagePath,
        selectedPdf!,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = supabase.storage
          .from('timetables')
          .getPublicUrl(storagePath);

      await firestore.collection('timetables').doc(documentId).set(
        {
          'fileUrl': url,
          'filePath': storagePath,
          'fileName':
          selectedPdf!.path.split(Platform.pathSeparator).last,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedById': auth.currentUser?.uid,
          'updatedByName': teacherName,
        },
        SetOptions(merge: true),
      );

      selectedPdf = null;
      await searchTimetable();

      showMessage(
        'PDF uploaded for viewing. Excel remains the attendance source.',
      );
    } catch (e) {
      showMessage('PDF upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> saveExcelTimetable() async {
    if (!widget.isAdmin) return;

    if (selectedTimetableExcelRows == null) {
      showMessage(
        'Choose and validate a timetable Excel file first.',
        error: true,
      );
      return;
    }

    // Re-validate immediately before saving in case teacher records changed.
    setState(() => isUploadingExcel = true);

    try {
      final parsed = excelService.parseTimetableExcel(
        rows: selectedTimetableExcelRows!,
        teachers: teachers,
      );

      final totalPeriods = parsed.values.fold<int>(
        0,
            (sum, list) => sum + list.length,
      );

      if (totalPeriods == 0) {
        throw Exception('No timetable periods found.');
      }

      schedule = _normalizeSchedule(parsed);

      final data = <String, dynamic>{
        'title':
        'Timetable - $selectedYear Year | $selectedDepartment | '
            'Semester $selectedSemester | Section $selectedSection',
        'academicYear': selectedAcademicYear,
        'semester': selectedSemester,
        'year': selectedYear,
        'department': selectedDepartment,
        'section': selectedSection,

        // Excel is the official structured timetable.
        'timetableSource': 'excel',
        'excelImported': true,
        'excelPeriodCount': totalPeriods,
        'schedule': schedule,

        'uploadedById': auth.currentUser?.uid,
        'uploadedByName': teacherName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedById': auth.currentUser?.uid,
        'updatedByName': teacherName,

        'attendanceCalculationStarted':
        attendanceCalculationStarted,
        'attendanceStartDate': attendanceStartDate == null
            ? null
            : _dateKey(attendanceStartDate!),
        'attendanceEndDate': attendanceEndDate == null
            ? null
            : _dateKey(attendanceEndDate!),
      };

      await firestore
          .collection('timetables')
          .doc(documentId)
          .set(data, SetOptions(merge: true));

      await searchTimetable();

      if (!mounted) return;

      setState(() {
        selectedTimetableExcelRows = null;
        selectedExcelName = null;
        excelValidationMessage =
        '✓ Timetable saved: $totalPeriods periods.';
      });

      showMessage(
        'Excel timetable saved successfully. Teachers can now see their assigned periods.',
      );
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => isUploadingExcel = false);
    }
  }

  Future<void> saveStructuredTimetable() async {
    if (!widget.isAdmin) return;

    setState(() => isSavingSchedule = true);

    try {
      await firestore.collection('timetables').doc(documentId).set(
        {
          'academicYear': selectedAcademicYear,
          'semester': selectedSemester,
          'year': selectedYear,
          'department': selectedDepartment,
          'section': selectedSection,
          'schedule': schedule,
          'timetableSource': 'excel',
          'excelImported': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedById': auth.currentUser?.uid,
          'updatedByName': teacherName,
        },
        SetOptions(merge: true),
      );

      await searchTimetable();

      showMessage('Structured timetable saved successfully.');
    } catch (e) {
      showMessage(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => isSavingSchedule = false);
    }
  }

  Future<void> startAttendanceCalculation() async {
    if (!widget.isAdmin) return;

    if (currentTimetable == null) {
      showMessage(
        'Upload a timetable before starting attendance.',
        error: true,
      );
      return;
    }

    final today = _dateOnly(DateTime.now());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start Attendance Calculation?'),
        content: Text(
          'Attendance will start from ${_dateKey(today)} and '
              'run for 6 months. The system will calculate attendance '
              'only up to the current date and will not count future days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isStartingAttendance = true);

    try {
      final endDate = DateTime(
        today.year,
        today.month + 6,
        today.day,
      ).subtract(const Duration(days: 1));

      final attendanceConfigId =
          '${selectedAcademicYear}_${selectedSemester}_${selectedYear}_${selectedDepartment}_${selectedSection}';

      await firestore
          .collection('attendance_config')
          .doc(attendanceConfigId)
          .set(
        {
          'academicYear': selectedAcademicYear,
          'semester': selectedSemester,
          'year': selectedYear,
          'department': selectedDepartment,
          'section': selectedSection,
          'startDate': _dateKey(today),
          'endDate': _dateKey(endDate),
          'startedAt': FieldValue.serverTimestamp(),
          'startedById': auth.currentUser?.uid,
          'startedByName': teacherName,
          'active': true,
        },
        SetOptions(merge: true),
      );

      await firestore.collection('timetables').doc(documentId).set(
        {
          'attendanceCalculationStarted': true,
          'attendanceStartDate': _dateKey(today),
          'attendanceEndDate': _dateKey(endDate),
          'attendanceConfigId': attendanceConfigId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      setState(() {
        attendanceCalculationStarted = true;
        attendanceStartDate = today;
        attendanceEndDate = endDate;
      });

      showMessage(
        'Attendance calculation started from ${_dateKey(today)}.',
      );
    } catch (e) {
      showMessage(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => isStartingAttendance = false);
    }
  }

  Future<void> loadHolidays() async {
    try {
      final snap = await firestore
          .collection('academic_holidays')
          .where(
        'academicYear',
        isEqualTo: selectedAcademicYear,
      )
          .orderBy('date')
          .get();

      holidays = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      if (mounted) setState(() {});
    } catch (e) {
      // If an index is required, don't break the whole page.
      final snap = await firestore
          .collection('academic_holidays')
          .where(
        'academicYear',
        isEqualTo: selectedAcademicYear,
      )
          .get();

      holidays = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      holidays.sort(
            (a, b) => a['date'].toString().compareTo(
          b['date'].toString(),
        ),
      );

      if (mounted) setState(() {});
    }
  }

  Future<void> addHoliday() async {
    if (!widget.isAdmin) return;

    DateTime? selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (selectedDate == null) return;

    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Holiday'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Holiday name',
            hintText: 'Example: Independence Day',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                controller.text.trim().isEmpty
                    ? 'Holiday'
                    : controller.text.trim(),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null) return;

    final key = _dateKey(selectedDate);
    final docId = '${selectedAcademicYear}_$key';

    await firestore.collection('academic_holidays').doc(docId).set(
      {
        'academicYear': selectedAcademicYear,
        'date': key,
        'name': name,
        'createdById': auth.currentUser?.uid,
        'createdByName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await loadHolidays();

    showMessage('$name added as a holiday.');
  }

  Future<void> removeHoliday(String id) async {
    if (!widget.isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Holiday?'),
        content: const Text(
          'This date will become a normal working day again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await firestore.collection('academic_holidays').doc(id).delete();
    await loadHolidays();

    showMessage('Holiday removed.');
  }

  Future<void> addOrEditPeriod({
    required String day,
    Map<String, dynamic>? existing,
    int? existingIndex,
  }) async {
    if (!widget.isAdmin) return;

    final subjectController = TextEditingController(
      text: existing?['subject']?.toString() ?? '',
    );

    final startController = TextEditingController(
      text: existing?['startTime']?.toString() ?? '09:30',
    );

    final endController = TextEditingController(
      text: existing?['endTime']?.toString() ?? '10:30',
    );

    String type = existing?['type']?.toString() ?? 'Theory';
    bool counts = existing?['countsForAttendance'] != false;

    String? teacherUid = existing?['teacherUid']?.toString();

    if (teacherUid != null &&
        !teachers.any((t) => t['uid'].toString() == teacherUid)) {
      teacherUid = null;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existing == null
                  ? 'Add $day Period'
                  : 'Edit $day Period',
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Activity',
                        hintText: 'Example: DA-LAB',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            decoration: const InputDecoration(
                              labelText: 'Start',
                              hintText: '09:30',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            decoration: const InputDecoration(
                              labelText: 'End',
                              hintText: '10:30',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: periodTypes
                          .map(
                            (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          type = value;
                          if (type == 'Library' || type == 'Sports') {
                            counts = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: teacherUid,
                      decoration: const InputDecoration(
                        labelText: 'Teacher',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No teacher'),
                        ),
                        ...teachers.map(
                              (teacher) => DropdownMenuItem<String?>(
                            value: teacher['uid'].toString(),
                            child: Text(
                              '${teacher['name']}'
                                  '${teacher['department'].toString().isEmpty ? '' : ' • ${teacher['department']}'}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => teacherUid = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Count for attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        type == 'Library' || type == 'Sports'
                            ? 'Library/Sports are normally excluded.'
                            : 'This period contributes its duration to attendance.',
                      ),
                      value: counts,
                      onChanged:
                      type == 'Library' || type == 'Sports'
                          ? null
                          : (value) {
                        setDialogState(() => counts = value);
                      },
                    ),
                    if (teacherUid != null)
                      Builder(
                        builder: (_) {
                          final teacher = teachers.firstWhere(
                                (t) => t['uid'].toString() == teacherUid,
                            orElse: () => <String, dynamic>{},
                          );

                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Teacher ID: ${teacher['teacherId'] ?? teacherUid}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final subject = subjectController.text.trim();

                  if (subject.isEmpty) return;

                  final start =
                  _timeToMinutes(startController.text.trim());
                  final end =
                  _timeToMinutes(endController.text.trim());

                  if (start < 0 || end <= start) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter valid start/end times. Example: 09:30 and 10:30.',
                        ),
                      ),
                    );
                    return;
                  }

                  final minutes = end - start;
                  final hours = minutes / 60.0;

                  final teacher = teacherUid == null
                      ? null
                      : teachers.firstWhere(
                        (t) =>
                    t['uid'].toString() == teacherUid,
                    orElse: () => <String, dynamic>{},
                  );

                  Navigator.pop(
                    context,
                    {
                      'subject': subject,
                      'startTime': startController.text.trim(),
                      'endTime': endController.text.trim(),
                      'hours': double.parse(
                        hours.toStringAsFixed(2),
                      ),
                      'type': type,
                      'countsForAttendance': counts,
                      'teacherUid': teacherUid,
                      'teacherId': teacher == null || teacher.isEmpty
                          ? ''
                          : (teacher['teacherId'] ?? teacher['uid']).toString(),
                      'teacherName':
                      teacher == null || teacher.isEmpty
                          ? ''
                          : teacher['name'].toString(),
                    },
                  );
                },
                child: Text(
                  existing == null ? 'Add' : 'Save',
                ),
              ),
            ],
          );
        },
      ),
    );

    subjectController.dispose();
    startController.dispose();
    endController.dispose();

    if (result == null) return;

    setState(() {
      if (existingIndex == null) {
        schedule[day]!.add(result);
      } else {
        schedule[day]![existingIndex] = result;
      }

      schedule[day]!.sort(
            (a, b) => _timeToMinutes(
          a['startTime']?.toString() ?? '',
        ).compareTo(
          _timeToMinutes(
            b['startTime']?.toString() ?? '',
          ),
        ),
      );
    });
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return -1;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return -1;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return -1;
    }

    return hour * 60 + minute;
  }

  Future<void> deletePeriod(String day, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Period?'),
        content: Text(
          'Delete ${schedule[day]![index]['subject']} from $day?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      schedule[day]!.removeAt(index);
    });
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? const Color(0xFFB8C4D6)
                  : const Color(0xFF455A64),
            ),
          ),
        ),
        Container(
          height: 54,
          decoration: BoxDecoration(
            // Dark mode: solid dark field instead of white/light glass.
            color: isDark
                ? const Color(0xFF111827)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFD6DCE5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(.25)
                    : Colors.black.withOpacity(.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF455A64),
              ),
              dropdownColor: isDark
                  ? const Color(0xFF172033)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF263238),
              ),
              items: items.map(
                    (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    e.toString(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF263238),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleEditor(bool isDark) {
    if (!widget.isAdmin) {
      return const SizedBox.shrink();
    }

    return glassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Structured Attendance Timetable',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The PDF is for viewing. This structured timetable is what '
                  'the attendance system will use.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            for (final day in days) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(.06)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white24
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => addOrEditPeriod(day: day),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Period'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (schedule[day]!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'No periods configured.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...schedule[day]!.asMap().entries.map(
                            (entry) {
                          final index = entry.key;
                          final item = entry.value;

                          final counts =
                              item['countsForAttendance'] != false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  '${index + 1}',
                                ),
                              ),
                              title: Text(
                                item['subject']?.toString() ??
                                    'Subject',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${item['startTime']} - ${item['endTime']}'
                                    ' • ${item['hours']} hr'
                                    ' • ${item['type']}'
                                    '\n'
                                    'Teacher: ${item['teacherName']?.toString().isEmpty ?? true ? 'Not assigned' : item['teacherName']}'
                                    '${item['teacherId']?.toString().isEmpty ?? true ? '' : ' • ID: ${item['teacherId']}'}'
                                    ' • Attendance: ${counts ? 'COUNT' : 'IGNORE'}',
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => addOrEditPeriod(
                                      day: day,
                                      existing: item,
                                      existingIndex: index,
                                    ),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () =>
                                        deletePeriod(day, index),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                isSavingSchedule ? null : saveStructuredTimetable,
                icon: isSavingSchedule
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: const Text(
                  'Save Structured Timetable',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayManagement(bool isDark) {
    if (!widget.isAdmin) {
      return const SizedBox.shrink();
    }

    return glassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF1565C0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Holiday Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: addHoliday,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Holiday'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These holidays apply to every class for $selectedAcademicYear. '
                  'They are excluded from attendance calculations.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            if (holidays.isEmpty)
              const Text(
                'No holidays configured.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...holidays.map(
                    (holiday) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.event_busy,
                    color: Colors.orange,
                  ),
                  title: Text(
                    holiday['name']?.toString() ?? 'Holiday',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    holiday['date']?.toString() ?? '',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove holiday',
                    onPressed: () => removeHoliday(
                      holiday['id'].toString(),
                    ),
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceControl(bool isDark) {
    if (!widget.isAdmin) {
      return const SizedBox.shrink();
    }

    return glassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Calculation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (!attendanceCalculationStarted ||
                attendanceStartDate == null ||
                attendanceEndDate == null)
              const Text(
                'Attendance has not been started for this timetable.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              Text(
                'Started: ${attendanceStartDate == null
                    ? 'Not available'
                    : _dateKey(attendanceStartDate!)}',
              ),
              Text(
                'Ends: ${attendanceEndDate == null
                    ? 'Not available'
                    : _dateKey(attendanceEndDate!)}',
              ),
              const SizedBox(height: 6),
              const Text(
                'The calculation uses the current date, so future '
                    'attendance is never counted.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isStartingAttendance
                    ? null
                    : startAttendanceCalculation,
                icon: isStartingAttendance
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  attendanceCalculationStarted
                      ? Icons.refresh
                      : Icons.play_arrow,
                ),
                label: Text(
                  attendanceCalculationStarted
                      ? 'Restart from Today'
                      : 'Start Attendance Calculation',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimetable(bool isDark) {
    if (currentTimetable == null) {
      return const SizedBox.shrink();
    }

    final title =
        currentTimetable!['title']?.toString() ?? 'Timetable';

    final uploaded = currentTimetable!['uploadedAt'];

    final uploadedText = uploaded is Timestamp
        ? uploaded.toDate().toLocal().toString().substring(0, 16)
        : 'Available';

    final source =
        currentTimetable!['timetableSource']?.toString() ?? 'excel';

    final periodCount =
        currentTimetable!['excelPeriodCount']?.toString() ?? '';

    final fileUrl =
        currentTimetable!['fileUrl']?.toString() ?? '';

    return glassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.table_chart_rounded,
                  size: 44,
                  color: isDark
                      ? Colors.lightBlueAccent
                      : const Color(0xFF1565C0),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Structured source: ${source.toUpperCase()}'
                            '${periodCount.isEmpty ? '' : ' • $periodCount periods'}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Teacher assignments are stored in Firebase.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Updated: $uploadedText',
              style: TextStyle(
                color: isDark
                    ? Colors.white60
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            if (fileUrl.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => openPDF(fileUrl),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('View PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                        isUploading ? null : uploadOptionalPDF,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Replace PDF'),
                      ),
                    ),
                  ],
                ],
              )
            else if (widget.isAdmin)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                  isUploading ? null : uploadOptionalPDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'Upload Optional PDF for Viewing',
                  ),
                ),
              )
            else
              Text(
                'No PDF was uploaded. The structured timetable is still available.',
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTimetable(bool isDark) {
    if (widget.isAdmin) {
      return const SizedBox.shrink();
    }

    // Filter every day's periods down to only the ones assigned to the
    // currently logged-in teacher (matched by Firebase Auth uid).
    final myScheduleByDay = <String, List<Map<String, dynamic>>>{
      for (final day in days)
        day: schedule[day]!
            .where((item) {
          final singleUid = item['teacherUid']?.toString() ?? '';
          final singleId = item['teacherId']?.toString() ?? '';

          final rawUids = item['teacherUids'];
          final rawIds = item['teacherIds'];

          final uids = rawUids is List
              ? rawUids.map((e) => e.toString()).toList()
              : <String>[];

          final ids = rawIds is List
              ? rawIds.map((e) => e.toString()).toList()
              : <String>[];

          final teacherRecord = teachers.firstWhere(
                (t) => t['uid']?.toString() == teacherId,
            orElse: () => <String, dynamic>{},
          );

          final humanTeacherId =
              teacherRecord['teacherId']?.toString() ?? '';

          return singleUid == teacherId ||
              singleId == humanTeacherId ||
              uids.contains(teacherId) ||
              ids.contains(humanTeacherId);
        })
            .toList(),
    };

    final hasAnyPeriod =
    myScheduleByDay.values.any((list) => list.isNotEmpty);

    return glassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Periods',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Only periods assigned to you are shown below.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasAnyPeriod)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'No periods assigned to you yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              for (final day in days)
                if (myScheduleByDay[day]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  ...myScheduleByDay[day]!.map(
                        (item) {
                      final counts =
                          item['countsForAttendance'] != false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item['subject']?.toString() ?? 'Subject',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            '${item['startTime']} - ${item['endTime']}'
                                ' • ${item['hours']} hr'
                                ' • ${item['type']}'
                                ' • Attendance: ${counts ? 'COUNT' : 'IGNORE'}',
                          ),
                        ),
                      );
                    },
                  ),
                ],
          ],
        ),
      ),
    );
  }

  Future<void> deleteTimetable() async {
    if (!widget.isAdmin || currentTimetable == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Timetable'),
        content: const Text(
          'This removes the structured timetable from Firebase. '
              'If a PDF exists, its stored copy is also removed. '
              'Holidays are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isUploading = true);

    try {
      final path =
          currentTimetable!['filePath']?.toString() ?? '';

      if (path.isNotEmpty) {
        try {
          await supabase.storage
              .from('timetables')
              .remove([path]);
        } catch (_) {}
      }

      await firestore
          .collection('timetables')
          .doc(documentId)
          .delete();

      setState(() {
        currentTimetable = null;
        currentDocId = null;
        _resetSchedule();
        attendanceCalculationStarted = false;
        attendanceStartDate = null;
        attendanceEndDate = null;
      });

      showMessage('Timetable deleted.');
    } catch (e) {
      showMessage(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF0D47A1)
            : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.isAdmin
              ? 'Admin Timetable Management'
              : 'Timetable',
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            glassCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAdmin
                          ? 'Class Timetable'
                          : 'My Timetable',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dropdown<String>(
                      label: 'Academic Year',
                      value: selectedAcademicYear,
                      items: academicYears,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          selectedAcademicYear = value;
                          currentTimetable = null;
                        });
                        await searchTimetable();
                        await loadHolidays();
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdown<String>(
                      label: 'Semester',
                      value: selectedSemester,
                      items: semesters,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          selectedSemester = value;
                          currentTimetable = null;
                        });
                        await searchTimetable();
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdown<String>(
                      label: 'Year',
                      value: selectedYear,
                      items: years,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          selectedYear = value;
                          currentTimetable = null;
                        });
                        await searchTimetable();
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdown<String>(
                      label: 'Department',
                      value: selectedDepartment,
                      items: departments,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          selectedDepartment = value;
                          currentTimetable = null;
                        });
                        await searchTimetable();
                      },
                    ),
                    const SizedBox(height: 12),
                    _dropdown<String>(
                      label: 'Section',
                      value: selectedSection,
                      items: sections,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          selectedSection = value;
                          currentTimetable = null;
                        });
                        await searchTimetable();
                      },
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(height: 18),

                      // Download the official EduMate Excel template.
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: downloadTimetableTemplate,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text(
                            'Download Timetable Excel Template',
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Excel is the source of truth for attendance.
                      OutlinedButton.icon(
                        onPressed:
                        isParsingExcel ? null : pickTimetableExcel,
                        icon: isParsingExcel
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.table_view_rounded),
                        label: Text(
                          selectedExcelName ??
                              'Choose Timetable Excel',
                        ),
                      ),

                      if (selectedTimetableExcelRows != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Excel rows: ${selectedTimetableExcelRows!.length - 1}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      if (excelValidationMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: excelValidationMessage!
                                .startsWith('✓')
                                ? Colors.green.withOpacity(.12)
                                : Colors.orange.withOpacity(.12),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Text(
                            excelValidationMessage!,
                            style: TextStyle(
                              color: excelValidationMessage!
                                  .startsWith('✓')
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                          isUploadingExcel ||
                              selectedTimetableExcelRows ==
                                  null
                              ? null
                              : saveExcelTimetable,
                          icon: isUploadingExcel
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.save_rounded),
                          label: const Text(
                            'Validate & Save Excel Timetable',
                          ),
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // PDF is optional and is only for visual viewing.
                      OutlinedButton.icon(
                        onPressed:
                        isUploading ? null : uploadOptionalPDF,
                        icon: const Icon(
                          Icons.picture_as_pdf,
                        ),
                        label: const Text(
                          'Upload Optional PDF for Viewing',
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Excel controls the structured timetable and attendance. '
                            'PDF is optional and is stored only for viewing.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),

                      if (currentTimetable != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: deleteTimetable,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete Timetable',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildCurrentTimetable(isDark),
            if (widget.isAdmin) ...[
              const SizedBox(height: 14),
              _buildScheduleEditor(isDark),
              const SizedBox(height: 14),
              _buildAttendanceControl(isDark),
              const SizedBox(height: 14),
              _buildHolidayManagement(isDark),
            ] else ...[
              const SizedBox(height: 14),
              _buildMyTimetable(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget glassCard({
    required Widget child,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(.08)
                : Colors.white.withOpacity(.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white24
                  : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(.30)
                    : Colors.black.withOpacity(.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
