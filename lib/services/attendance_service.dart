import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance calculation service for EduMate.
///
/// Attendance is calculated from attendance_history records using HOURS,
/// not simply the number of classes. Therefore a 2-hour lab contributes
/// twice as much as a 1-hour theory period.
///
/// Expected attendance_history fields:
///   studentId
///   dateKey
///   date
///   present
///   scheduledHours
///   presentHours
///   subject
///   type
///   academicYear
///   semester
///   timetableId
///
/// Global holidays are stored in:
///   academic_holidays/{academicYear_YYYY-MM-DD}
///
/// Attendance configuration is stored in:
///   attendance_config/{academicYear_semester}
class AttendanceService {
  final FirebaseFirestore firestore;

  AttendanceService({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // Backward-compatible method
  // ------------------------------------------------------------

  /// Kept so old code that calls getAttendance() does not break.
  ///
  /// This cannot calculate a real student's percentage without a
  /// student ID, so it returns the previous placeholder value.
  /// New code should use getSemesterPercentage() or getAttendanceSummary().
  double getAttendance() {
    return 0.0;
  }

  // ------------------------------------------------------------
  // Date helpers
  // ------------------------------------------------------------

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dateKey(DateTime value) {
    final date = _dateOnly(value);

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return _dateOnly(value.toDate());
    }

    if (value is DateTime) {
      return _dateOnly(value);
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return _dateOnly(parsed);
      }
    }

    return null;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  // ------------------------------------------------------------
  // Attendance configuration
  // ------------------------------------------------------------

  String _configId({
    required String academicYear,
    required String semester,
  }) {
    return '${academicYear}_$semester';
  }

  Future<Map<String, dynamic>?> getAttendanceConfig({
    required String academicYear,
    required String semester,
  }) async {
    final doc = await firestore
        .collection('attendance_config')
        .doc(
      _configId(
        academicYear: academicYear,
        semester: semester,
      ),
    )
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  /// Returns the date through which attendance should currently be
  /// calculated. Future dates are never included.
  Future<DateTime?> getCalculationEndDate({
    required String academicYear,
    required String semester,
    DateTime? today,
  }) async {
    final config = await getAttendanceConfig(
      academicYear: academicYear,
      semester: semester,
    );

    if (config == null || config['active'] != true) {
      return null;
    }

    final start = _parseDate(config['startDate']);
    final configuredEnd = _parseDate(config['endDate']);

    if (start == null || configuredEnd == null) {
      return null;
    }

    final current = _dateOnly(today ?? DateTime.now());

    if (current.isBefore(start)) {
      return null;
    }

    return current.isBefore(configuredEnd)
        ? current
        : configuredEnd;
  }

  // ------------------------------------------------------------
  // Holidays
  // ------------------------------------------------------------

  Future<bool> isHoliday({
    required String academicYear,
    required DateTime date,
  }) async {
    final key = '${academicYear}_${_dateKey(date)}';

    final doc = await firestore
        .collection('academic_holidays')
        .doc(key)
        .get();

    return doc.exists;
  }

  Future<Set<String>> getHolidayKeys({
    required String academicYear,
  }) async {
    final snapshot = await firestore
        .collection('academic_holidays')
        .where(
      'academicYear',
      isEqualTo: academicYear,
    )
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['date']?.toString())
        .whereType<String>()
        .toSet();
  }

  // ------------------------------------------------------------
  // Working-day helper
  // ------------------------------------------------------------

  /// Sunday is always closed.
  /// Holidays are also closed.
  bool isWorkingDay({
    required DateTime date,
    required Set<String> holidayKeys,
  }) {
    if (date.weekday == DateTime.sunday) {
      return false;
    }

    return !holidayKeys.contains(_dateKey(date));
  }

  // ------------------------------------------------------------
  // Raw history
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAttendanceHistory({
    required String studentId,
    required String academicYear,
    required String semester,
    DateTime? from,
    DateTime? to,
  }) async {
    Query<Map<String, dynamic>> query = firestore
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
    );

    final snapshot = await query.get();

    final result = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    final start = from == null ? null : _dateOnly(from);
    final end = to == null ? null : _dateOnly(to);

    result.removeWhere((item) {
      final date =
          _parseDate(item['date']) ??
              DateTime.tryParse(
                item['dateKey']?.toString() ?? '',
              );

      if (date == null) return true;

      if (start != null && date.isBefore(start)) {
        return true;
      }

      if (end != null && date.isAfter(end)) {
        return true;
      }

      return false;
    });

    result.sort((a, b) {
      final aDate = a['dateKey']?.toString() ?? '';
      final bDate = b['dateKey']?.toString() ?? '';
      return aDate.compareTo(bDate);
    });

    return result;
  }

  // ------------------------------------------------------------
  // Semester calculation
  // ------------------------------------------------------------

  /// Calculates weighted semester attendance:
  ///
  /// semester percentage =
  ///     total attended units / total conducted units * 100
  ///
  /// Theory = 1 unit, Lab = 2 units. Both are combined across all subjects.
  Future<Map<String, dynamic>> getSemesterSummary({
    required String studentId,
    required String academicYear,
    required String semester,
    DateTime? today,
  }) async {
    final config = await getAttendanceConfig(
      academicYear: academicYear,
      semester: semester,
    );

    if (config == null) {
      return _emptySummary(
        academicYear: academicYear,
        semester: semester,
      );
    }

    final configuredStart =
    _parseDate(config['startDate']);

    if (configuredStart == null) {
      return _emptySummary(
        academicYear: academicYear,
        semester: semester,
      );
    }

    final end = await getCalculationEndDate(
      academicYear: academicYear,
      semester: semester,
      today: today,
    );

    if (end == null) {
      return _emptySummary(
        academicYear: academicYear,
        semester: semester,
      );
    }

    final history = await getAttendanceHistory(
      studentId: studentId,
      academicYear: academicYear,
      semester: semester,
      from: configuredStart,
      to: end,
    );

    double scheduledHours = 0;
    double presentHours = 0;

    for (final record in history) {
      final units = _attendanceUnits(record);
      scheduledHours += units;
      presentHours += _presentAttendanceUnits(record);
    }

    final percentage = scheduledHours <= 0
        ? 0.0
        : (presentHours / scheduledHours) * 100;

    return {
      'academicYear': academicYear,
      'semester': semester,
      'startDate': _dateKey(configuredStart),
      'endDate': _dateKey(end),
      'scheduledHours': scheduledHours,
      'presentHours': presentHours,
      'absentHours':
      (scheduledHours - presentHours).clamp(0, double.infinity),
      'percentage': percentage.clamp(0, 100),
      'isStarted': true,
    };
  }

  Future<double> getSemesterPercentage({
    required String studentId,
    required String academicYear,
    required String semester,
    DateTime? today,
  }) async {
    final summary = await getSemesterSummary(
      studentId: studentId,
      academicYear: academicYear,
      semester: semester,
      today: today,
    );

    return _number(summary['percentage']);
  }

  // ------------------------------------------------------------
  // 15-day cycle calculation
  // ------------------------------------------------------------

  /// Calculates the current 15-calendar-day cycle from the attendance
  /// start date. The first cycle is startDate through startDate + 14 days,
  /// the second is +15 through +29, etc.
  ///
  /// Theory = 1 unit and Lab = 2 units. Both are included in the
  /// same 15-day cycle percentage.
  ///
  /// Only actual attendance records contribute to the denominator.
  /// Sundays and holidays therefore do not become automatic absences.
  Future<Map<String, dynamic>> getCurrentCycleSummary({
    required String studentId,
    required String academicYear,
    required String semester,
    DateTime? today,
  }) async {
    final config = await getAttendanceConfig(
      academicYear: academicYear,
      semester: semester,
    );

    if (config == null) {
      return _emptyCycleSummary();
    }

    final semesterStart =
    _parseDate(config['startDate']);

    if (semesterStart == null) {
      return _emptyCycleSummary();
    }

    final calculationEnd = await getCalculationEndDate(
      academicYear: academicYear,
      semester: semester,
      today: today,
    );

    if (calculationEnd == null) {
      return _emptyCycleSummary();
    }

    final current = _dateOnly(today ?? DateTime.now());

    if (current.isBefore(semesterStart)) {
      return _emptyCycleSummary();
    }

    final daysFromStart =
        current.difference(semesterStart).inDays;

    final cycleNumber = (daysFromStart ~/ 15) + 1;

    final cycleStart = semesterStart.add(
      Duration(days: (cycleNumber - 1) * 15),
    );

    DateTime cycleEnd = cycleStart.add(
      const Duration(days: 14),
    );

    if (cycleEnd.isAfter(calculationEnd)) {
      cycleEnd = calculationEnd;
    }

    final history = await getAttendanceHistory(
      studentId: studentId,
      academicYear: academicYear,
      semester: semester,
      from: cycleStart,
      to: cycleEnd,
    );

    double scheduledHours = 0;
    double presentHours = 0;

    for (final record in history) {
      final units = _attendanceUnits(record);
      scheduledHours += units;
      presentHours += _presentAttendanceUnits(record);
    }

    final percentage = scheduledHours <= 0
        ? 0.0
        : (presentHours / scheduledHours) * 100;

    return {
      'cycleNumber': cycleNumber,
      'startDate': _dateKey(cycleStart),
      'endDate': _dateKey(cycleEnd),
      'scheduledHours': scheduledHours,
      'presentHours': presentHours,
      'absentHours':
      (scheduledHours - presentHours).clamp(0, double.infinity),
      'percentage': percentage.clamp(0, 100),
    };
  }

  Future<double> getCurrentCyclePercentage({
    required String studentId,
    required String academicYear,
    required String semester,
    DateTime? today,
  }) async {
    final summary = await getCurrentCycleSummary(
      studentId: studentId,
      academicYear: academicYear,
      semester: semester,
      today: today,
    );

    return _number(summary['percentage']);
  }

  // ------------------------------------------------------------
  // Subject-wise calculation
  // ------------------------------------------------------------

  /// Returns subject attendance using attendance units.
  /// Theory = 1 unit per class; Lab = 2 units per lab.
  /// Each subject is calculated independently first.
  Future<List<Map<String, dynamic>>> getSubjectSummaries({
    required String studentId,
    required String academicYear,
    required String semester,
    DateTime? today,
  }) async {
    final config = await getAttendanceConfig(
      academicYear: academicYear,
      semester: semester,
    );

    if (config == null) return [];

    final start = _parseDate(config['startDate']);
    final end = await getCalculationEndDate(
      academicYear: academicYear,
      semester: semester,
      today: today,
    );

    if (start == null || end == null) return [];

    final history = await getAttendanceHistory(
      studentId: studentId,
      academicYear: academicYear,
      semester: semester,
      from: start,
      to: end,
    );

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final record in history) {
      final subject =
          record['subject']?.toString().trim() ?? '';

      if (subject.isEmpty) continue;

      final key = subject.toUpperCase();

      grouped.putIfAbsent(
        key,
            () => {
          'subject': subject,
          'type': record['type'] ?? 'Theory',
          'scheduledHours': 0.0,
          'presentHours': 0.0,
        },
      );

      final item = grouped[key]!;

      final scheduled = _attendanceUnits(record);
      final present = _presentAttendanceUnits(record);

      item['scheduledHours'] =
          _number(item['scheduledHours']) + scheduled;

      item['presentHours'] =
          _number(item['presentHours']) + present;
    }

    final result = grouped.values.map((item) {
      final scheduled =
      _number(item['scheduledHours']);
      final present =
      _number(item['presentHours']);

      return {
        ...item,
        'absentHours':
        (scheduled - present).clamp(0, double.infinity),
        'percentage': scheduled <= 0
            ? 0.0
            : ((present / scheduled) * 100)
            .clamp(0, 100),
      };
    }).toList();

    result.sort(
          (a, b) => a['subject']
          .toString()
          .compareTo(b['subject'].toString()),
    );

    return result;
  }

  // ------------------------------------------------------------
  // Attendance edit support
  // ------------------------------------------------------------

  /// Updates one existing attendance record.
  ///
  /// This is intended for the teacher's "Edit Attendance" screen.
  Future<void> updateAttendanceRecord({
    required String attendanceRecordId,
    required bool present,
  }) async {
    final doc = await firestore
        .collection('attendance_history')
        .doc(attendanceRecordId)
        .get();

    if (!doc.exists) {
      throw Exception('Attendance record not found.');
    }

    final data = doc.data() ?? {};

    final attendanceUnits = _attendanceUnits(data);

    await doc.reference.update({
      'present': present,
      'presentHours':
      present ? attendanceUnits : 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Edit attendance by student + date + timetable + subject.
  /// Useful when the UI does not know the Firestore document ID.
  Future<void> updateAttendanceByDetails({
    required String studentId,
    required String dateKey,
    required String timetableId,
    required String subject,
    required bool present,
  }) async {
    final snapshot = await firestore
        .collection('attendance_history')
        .where(
      'studentId',
      isEqualTo: studentId,
    )
        .where(
      'dateKey',
      isEqualTo: dateKey,
    )
        .where(
      'timetableId',
      isEqualTo: timetableId,
    )
        .where(
      'subject',
      isEqualTo: subject,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception(
        'Attendance record not found for this student/class/date.',
      );
    }

    final doc = snapshot.docs.first;
    final attendanceUnits = _attendanceUnits(doc.data());

    await doc.reference.update({
      'present': present,
      'presentHours':
      present ? attendanceUnits : 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // Attendance units
  // ------------------------------------------------------------

  /// College attendance units:
  /// Theory/Other = 1 unit (or the stored period duration).
  /// Lab = exactly 2 units.
  /// Library/Sports = 0 units.
  double _attendanceUnits(Map<String, dynamic> record) {
    final type = (record['type'] ?? 'Theory')
        .toString()
        .trim()
        .toLowerCase();

    if (type == 'library' ||
        type == 'lib' ||
        type == 'sports' ||
        type == 'sport') {
      return 0.0;
    }

    if (type == 'lab' ||
        type == 'laboratory' ||
        type == 'practical') {
      return 2.0;
    }

    final scheduled = _number(record['scheduledHours']);
    return scheduled > 0 ? scheduled : 1.0;
  }

  double _presentAttendanceUnits(Map<String, dynamic> record) {
    return record['present'] == true
        ? _attendanceUnits(record)
        : 0.0;
  }

  // ------------------------------------------------------------
  // Summary helpers
  // ------------------------------------------------------------

  Map<String, dynamic> _emptySummary({
    required String academicYear,
    required String semester,
  }) {
    return {
      'academicYear': academicYear,
      'semester': semester,
      'scheduledHours': 0.0,
      'presentHours': 0.0,
      'absentHours': 0.0,
      'percentage': 0.0,
      'isStarted': false,
    };
  }

  Map<String, dynamic> _emptyCycleSummary() {
    return {
      'cycleNumber': 0,
      'startDate': null,
      'endDate': null,
      'scheduledHours': 0.0,
      'presentHours': 0.0,
      'absentHours': 0.0,
      'percentage': 0.0,
    };
  }
}
