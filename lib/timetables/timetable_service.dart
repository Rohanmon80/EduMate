import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:url_launcher/url_launcher.dart';

class TimetableService {
//---------------------------------------------
// Firebase
//---------------------------------------------

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final SupabaseClient supabase =
      Supabase.instance.client;

//---------------------------------------------
// Current User
//---------------------------------------------

  User? get currentUser =>
      auth.currentUser;

//---------------------------------------------
// Document Id
//---------------------------------------------

  String documentId({
    required String year,
    required String department,
    required String section,
  }) {
    return "${year}_${department}_${section}";
  }

//---------------------------------------------
// Storage Path
//---------------------------------------------

  String storagePath({
    required String year,
    required String department,
    required String section,
  }) {
    return "$year/$department/$section/timetable.pdf";
  }

//---------------------------------------------
// Pick PDF
//---------------------------------------------

  Future<File?> pickPDF() async {
    final result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: [
        "pdf",
      ],
    );

    if (result == null) {
      return null;
    }

    if (result.files.first.size >
        20 * 1024 * 1024) {
      throw Exception(
        "Maximum PDF size is 20 MB",
      );
    }

    return File(
      result.files.first.path!,
    );
  }

//---------------------------------------------
// Open PDF
//---------------------------------------------

  Future<void> openPDF(
      String url,
      ) async {
    final uri = Uri.parse(url);

    if (!await canLaunchUrl(uri)) {
      throw Exception(
        "Unable to open PDF",
      );
    }

    await launchUrl(
      uri,
      mode:
      LaunchMode.externalApplication,
    );
  }
//---------------------------------------------
// Get Teacher / Admin Details
//---------------------------------------------

  Future<Map<String, dynamic>> getUserDetails({
    bool isAdmin = false,
  }) async {

    final user = currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final collection =
    isAdmin ? "admins" : "teachers";

    final query = await firestore
        .collection(collection)
        .where(
      "email",
      isEqualTo: user.email,
    )
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception(
        isAdmin
            ? "Admin profile not found"
            : "Teacher profile not found",
      );
    }

    final data = query.docs.first.data();

    return {
      // Firebase Authentication UID
      "uid": user.uid,

      // Teacher's actual ID from Firestore
      // Example: T006
      "teacherId": isAdmin
          ? (data["id"] ?? "")
          : (data["id"] ?? ""),

      // Keep "id" for backward compatibility.
      "id": isAdmin
          ? (data["id"] ?? user.uid)
          : (data["id"] ?? user.uid),

      "name": data["name"] ??
          (isAdmin ? "Admin" : "Teacher"),

      "department": isAdmin
          ? "Administrator"
          : (data["department"] ?? ""),

      "email": data["email"] ?? "",

      "phone": data["phone"] ?? "",

      "role": isAdmin
          ? "Admin"
          : "Teacher",
    };
  }

//---------------------------------------------
// Check Existing Timetable
//---------------------------------------------

  Future<DocumentSnapshot<Map<String, dynamic>>>
  getExistingTimetable({
    required String year,
    required String department,
    required String section,
  }) async {
    return firestore
        .collection("timetables")
        .doc(
      documentId(
        year: year,
        department: department,
        section: section,
      ),
    )
        .get();
  }

//---------------------------------------------
// Get Timetable
//---------------------------------------------

  Future<Map<String, dynamic>?> getTimetable({
    required String year,
    required String department,
    required String section,
  }) async {
    try {
      final cleanYear = year.trim();
      final cleanDepartment = department.trim();
      final cleanSection = section.trim();

      final id =
          "${cleanYear}_${cleanDepartment}_${cleanSection}";

      debugPrint("====================================");
      debugPrint("STUDENT TIMETABLE SEARCH");
      debugPrint("Year       : $cleanYear");
      debugPrint("Department : $cleanDepartment");
      debugPrint("Section    : $cleanSection");
      debugPrint("Document   : $id");
      debugPrint("====================================");

      // ---------------------------------------------------------
      // 1. First try the expected document ID
      // ---------------------------------------------------------

      DocumentSnapshot<Map<String, dynamic>> doc =
      await firestore
          .collection("timetables")
          .doc(id)
          .get();

      // ---------------------------------------------------------
      // 2. If not found, search by fields
      // ---------------------------------------------------------

      if (!doc.exists) {
        debugPrint(
          "Timetable document $id not found. "
              "Trying field-based search...",
        );

        final query = await firestore
            .collection("timetables")
            .where(
          "year",
          isEqualTo: cleanYear,
        )
            .where(
          "department",
          isEqualTo: cleanDepartment,
        )
            .where(
          "section",
          isEqualTo: cleanSection,
        )
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          doc = query.docs.first;

          debugPrint(
            "Timetable found using field search: "
                "${doc.id}",
          );
        }
      }

      // ---------------------------------------------------------
      // 3. Still not found
      // ---------------------------------------------------------

      if (!doc.exists) {
        debugPrint(
          "NO TIMETABLE FOUND for "
              "$cleanYear / $cleanDepartment / $cleanSection",
        );

        return null;
      }

      final data =
      Map<String, dynamic>.from(doc.data() ?? {});

      debugPrint(
        "Timetable Firestore data: $data",
      );

      // ---------------------------------------------------------
      // 4. Make sure fileUrl exists
      // ---------------------------------------------------------

      String fileUrl =
      (data["fileUrl"] ?? "").toString().trim();

      // If Firestore doesn't contain fileUrl,
      // generate it from the known Supabase storage path.
      if (fileUrl.isEmpty) {
        final path = storagePath(
          year: cleanYear,
          department: cleanDepartment,
          section: cleanSection,
        );

        debugPrint(
          "fileUrl missing. Generating Supabase URL:"
              "\n$path",
        );

        fileUrl = supabase.storage
            .from("timetables")
            .getPublicUrl(path);

        // Save it back to Firestore so future loads
        // don't need to generate it again.
        await firestore
            .collection("timetables")
            .doc(doc.id)
            .set(
          {
            "fileUrl": fileUrl,
            "filePath": path,
          },
          SetOptions(merge: true),
        );

        data["fileUrl"] = fileUrl;
        data["filePath"] = path;
      }

      // ---------------------------------------------------------
      // 5. Return complete timetable
      // ---------------------------------------------------------

      data["fileUrl"] = fileUrl;

      debugPrint(
        "FINAL TIMETABLE URL:"
            "\n$fileUrl",
      );

      return data;
    } catch (e, stackTrace) {
      debugPrint(
        "TIMETABLE LOAD ERROR: $e",
      );

      debugPrint(
        stackTrace.toString(),
      );

      rethrow;
    }
  }

//---------------------------------------------
// Timetable Exists?
//---------------------------------------------

  Future<bool> timetableExists({
    required String year,
    required String department,
    required String section,
  }) async {
    final doc =
    await getExistingTimetable(
      year: year,
      department: department,
      section: section,
    );

    return doc.exists;
  }
//---------------------------------------------
// Upload / Replace Timetable
//---------------------------------------------

  Future<String> uploadTimetable({
    required File pdfFile,
    required String year,
    required String department,
    required String section,
    required String teacherName,
    required String teacherId,
  }) async {

    final docId = documentId(
      year: year,
      department: department,
      section: section,
    );

    final path = storagePath(
      year: year,
      department: department,
      section: section,
    );

//-----------------------------------------
// Delete old PDF if exists
//-----------------------------------------

    final existing = await firestore
        .collection("timetables")
        .doc(docId)
        .get();

    if (existing.exists) {

      final data = existing.data();

      final oldPath =
          data?["filePath"] ?? "";

      if (oldPath.toString().isNotEmpty) {

        try {

          await supabase.storage
              .from("timetables")
              .remove([
            oldPath,
          ]);

        } catch (_) {}
      }
    }

//-----------------------------------------
// Upload new PDF
//-----------------------------------------

    await supabase.storage
        .from("timetables")
        .upload(
      path,
      pdfFile,

      fileOptions:
      const FileOptions(
        upsert: true,
      ),
    );

//-----------------------------------------
// Public URL
//-----------------------------------------

    final fileUrl = supabase.storage
        .from("timetables")
        .getPublicUrl(path);

//-----------------------------------------
// Save Firestore
//-----------------------------------------

    await firestore
        .collection("timetables")
        .doc(docId)
        .set({

      "title":
      "Timetable - $year Year | $department | Section $section",

      "teacher":
      teacherName,

      "teacherId":
      teacherId,

      "year":
      year,

      "department":
      department,

      "section":
      section,

      "fileUrl":
      fileUrl,

      "filePath":
      path,

      "fileName":
      pdfFile.path.split("/").last,

      "uploadedAt":
      FieldValue.serverTimestamp(),

    });

    return fileUrl;
  }

//---------------------------------------------
// Replace Timetable
//---------------------------------------------

  Future<String> replaceTimetable({

    required File pdfFile,

    required String year,

    required String department,

    required String section,

    required String teacherName,

    required String teacherId,

  }) async {

    return uploadTimetable(

      pdfFile: pdfFile,

      year: year,

      department: department,

      section: section,

      teacherName: teacherName,

      teacherId: teacherId,

    );
  }
//---------------------------------------------
// Delete Timetable
//---------------------------------------------

  Future<void> deleteTimetable({
    required String year,
    required String department,
    required String section,
  }) async {

    final docId = documentId(
      year: year,
      department: department,
      section: section,
    );

    final doc = await firestore
        .collection("timetables")
        .doc(docId)
        .get();

    if (!doc.exists) {
      throw Exception("Timetable not found");
    }

    final data = doc.data()!;

    final filePath =
        data["filePath"] ?? "";

//-----------------------------------------
// Delete PDF from Supabase
//-----------------------------------------

    if (filePath.toString().isNotEmpty) {

      try {

        await supabase.storage
            .from("timetables")
            .remove([
          filePath,
        ]);

      } catch (_) {}
    }

//-----------------------------------------
// Delete Firestore document
//-----------------------------------------

    await firestore
        .collection("timetables")
        .doc(docId)
        .delete();
  }

//---------------------------------------------
// Get All Timetables
//---------------------------------------------

  Future<List<Map<String, dynamic>>>
  getAllTimetables() async {

    final snapshot = await firestore
        .collection("timetables")
        .orderBy(
      "uploadedAt",
      descending: true,
    )
        .get();

    return snapshot.docs
        .map((e) => e.data())
        .toList();
  }

//---------------------------------------------
// Get Timetables By Department
//---------------------------------------------

  Future<List<Map<String, dynamic>>>
  getDepartmentTimetables(
      String department,
      ) async {

    final snapshot = await firestore
        .collection("timetables")
        .where(
      "department",
      isEqualTo: department,
    )
        .orderBy(
      "uploadedAt",
      descending: true,
    )
        .get();

    return snapshot.docs
        .map((e) => e.data())
        .toList();
  }

//---------------------------------------------
// Get Timetables By Year
//---------------------------------------------

  Future<List<Map<String, dynamic>>>
  getYearTimetables(
      String year,
      ) async {

    final snapshot = await firestore
        .collection("timetables")
        .where(
      "year",
      isEqualTo: year,
    )
        .orderBy(
      "uploadedAt",
      descending: true,
    )
        .get();

    return snapshot.docs
        .map((e) => e.data())
        .toList();
  }

//---------------------------------------------
// Get Timetables By Section
//---------------------------------------------

  Future<List<Map<String, dynamic>>>
  getSectionTimetables({

    required String year,

    required String department,

    required String section,

  }) async {

    final snapshot = await firestore
        .collection("timetables")
        .where(
      "year",
      isEqualTo: year,
    )
        .where(
      "department",
      isEqualTo: department,
    )
        .where(
      "section",
      isEqualTo: section,
    )
        .orderBy(
      "uploadedAt",
      descending: true,
    )
        .get();

    return snapshot.docs
        .map((e) => e.data())
        .toList();
  }
  //---------------------------------------------
  // Get File URL
  //---------------------------------------------

  Future<String?> getFileUrl({
    required String year,
    required String department,
    required String section,
  }) async {

    final data = await getTimetable(
      year: year,
      department: department,
      section: section,
    );

    if (data == null) {
      return null;
    }

    return data["fileUrl"];
  }

  //---------------------------------------------
  // Get File Name
  //---------------------------------------------

  Future<String?> getFileName({
    required String year,
    required String department,
    required String section,
  }) async {

    final data = await getTimetable(
      year: year,
      department: department,
      section: section,
    );

    if (data == null) {
      return null;
    }

    return data["fileName"];
  }

  //---------------------------------------------
  // Get Upload Time
  //---------------------------------------------

  Future<Timestamp?> getUploadTime({
    required String year,
    required String department,
    required String section,
  }) async {

    final data = await getTimetable(
      year: year,
      department: department,
      section: section,
    );

    if (data == null) {
      return null;
    }

    return data["uploadedAt"];
  }

  //---------------------------------------------
  // Check PDF Exists
  //---------------------------------------------

  Future<bool> pdfExists({
    required String year,
    required String department,
    required String section,
  }) async {

    final url = await getFileUrl(
      year: year,
      department: department,
      section: section,
    );

    return url != null &&
        url.toString().isNotEmpty;
  }

  //---------------------------------------------
  // Refresh Timetable
  //---------------------------------------------

  Future<Map<String, dynamic>?> refreshTimetable({
    required String year,
    required String department,
    required String section,
  }) async {

    return await getTimetable(
      year: year,
      department: department,
      section: section,
    );
  }

  //---------------------------------------------
  // Get Timetable Title
  //---------------------------------------------

  String timetableTitle({
    required String year,
    required String department,
    required String section,
  }) {

    return "Timetable - "
        "$year Year | "
        "$department | "
        "Section $section";
  }

//---------------------------------------------
// Close Service Class
//---------------------------------------------


  // ============================================================
  // STRUCTURED TIMETABLE MANAGEMENT
  // ============================================================

  Future<void> saveStructuredTimetable({
    required String year,
    required String department,
    required String section,
    required Map<String, dynamic> schedule,
    String? academicYear,
    String? semester,
  }) async {
    final docId = documentId(
      year: year,
      department: department,
      section: section,
    );

    await firestore.collection("timetables").doc(docId).set(
      {
        "year": year,
        "department": department,
        "section": section,
        if (academicYear != null) "academicYear": academicYear,
        if (semester != null) "semester": semester,
        "schedule": schedule,
        "scheduleUpdatedAt": FieldValue.serverTimestamp(),
        "scheduleUpdatedById": currentUser?.uid,
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>> getStructuredSchedule({
    required String year,
    required String department,
    required String section,
  }) async {
    final data = await getTimetable(
      year: year,
      department: department,
      section: section,
    );

    final raw = data?["schedule"];
    return raw is Map ? Map<String, dynamic>.from(raw) : {};
  }

  /// Finds every timetable period assigned to this teacher.
  ///
  /// Supports:
  /// 1. Firebase UID
  /// 2. Teacher ID such as T006
  /// 3. Old timetable format:
  ///    teacherUid / teacherId
  /// 4. New Excel timetable format:
  ///    teacherUids[] / teacherIds[]
  ///
  /// This also supports multiple teachers for labs.
  Future<List<Map<String, dynamic>>> getTeacherAssignedClasses({
    required String teacherUid,
    String? teacherId,
    String? academicYear,
    String? semester,
  }) async {
    Query<Map<String, dynamic>> query =
    firestore.collection("timetables");

    if (academicYear != null &&
        academicYear.isNotEmpty) {
      query = query.where(
        "academicYear",
        isEqualTo: academicYear,
      );
    }

    if (semester != null &&
        semester.isNotEmpty) {
      query = query.where(
        "semester",
        isEqualTo: semester,
      );
    }

    final snapshot = await query.get();

    final result = <Map<String, dynamic>>[];

    // Normalize IDs for safe comparison.
    final currentUid = teacherUid.trim().toLowerCase();

    final currentTeacherId =
    (teacherId ?? "").trim().toLowerCase();

    for (final doc in snapshot.docs) {
      final timetable = doc.data();

      final rawSchedule =
      timetable["schedule"];

      if (rawSchedule is! Map) {
        continue;
      }

      rawSchedule.forEach((day, rawPeriods) {
        if (rawPeriods is! List) {
          return;
        }

        for (final rawPeriod in rawPeriods) {
          if (rawPeriod is! Map) {
            continue;
          }

          final period =
          Map<String, dynamic>.from(rawPeriod);

          // -------------------------------------------------
          // OLD FORMAT
          // -------------------------------------------------

          final assignedUid =
          (period["teacherUid"] ?? "")
              .toString()
              .trim()
              .toLowerCase();

          final assignedId =
          (period["teacherId"] ?? "")
              .toString()
              .trim()
              .toLowerCase();

          // -------------------------------------------------
          // NEW EXCEL FORMAT
          // -------------------------------------------------

          final assignedUids =
          _stringList(period["teacherUids"]);

          final assignedIds =
          _stringList(period["teacherIds"]);

          // -------------------------------------------------
          // CHECK UID
          // -------------------------------------------------

          final uidMatched =
              assignedUid == currentUid ||
                  assignedUids.any(
                        (id) => id.toLowerCase() == currentUid,
                  );

          // -------------------------------------------------
          // CHECK TEACHER ID
          // -------------------------------------------------

          final teacherIdMatched =
              currentTeacherId.isNotEmpty &&
                  (
                      assignedId == currentTeacherId ||
                          assignedIds.any(
                                (id) =>
                            id.toLowerCase() ==
                                currentTeacherId,
                          )
                  );

          // -------------------------------------------------
          // FINAL MATCH
          // -------------------------------------------------

          if (uidMatched || teacherIdMatched) {
            result.add({
              ...period,

              "day": day.toString(),

              "year":
              timetable["year"],

              "department":
              timetable["department"],

              "section":
              timetable["section"],

              "academicYear":
              timetable["academicYear"],

              "semester":
              timetable["semester"],

              "timetableId":
              doc.id,
            });
          }
        }
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getTeacherClassesForDay({
    required String teacherUid,
    required String day,
    String? teacherId,
    String? academicYear,
    String? semester,
  }) async {
    final all = await getTeacherAssignedClasses(
      teacherUid: teacherUid,
      teacherId: teacherId,
      academicYear: academicYear,
      semester: semester,
    );

    final result = all.where((item) {
      return item["day"]?.toString().toLowerCase() ==
          day.toLowerCase();
    }).toList();

    result.sort(
          (a, b) => _timeToMinutes(a["startTime"]?.toString() ?? "")
          .compareTo(
        _timeToMinutes(b["startTime"]?.toString() ?? ""),
      ),
    );

    return result;
  }

  int _timeToMinutes(String value) {
    final parts = value.split(":");
    if (parts.length != 2) return 999999;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return 999999;
    return hour * 60 + minute;
  }

  // ============================================================
  // ATTENDANCE CONFIGURATION
  // ============================================================

  String attendanceConfigId({
    required String academicYear,
    required String semester,
  }) {
    return "${academicYear}_$semester";
  }

  Future<Map<String, dynamic>> startAttendanceCalculation({
    required String academicYear,
    required String semester,
    DateTime? startDate,
    String? startedByName,
  }) async {
    final start = _dateOnly(startDate ?? DateTime.now());

    final end = DateTime(
      start.year,
      start.month + 6,
      start.day,
    ).subtract(const Duration(days: 1));

    final data = <String, dynamic>{
      "academicYear": academicYear,
      "semester": semester,
      "startDate": _dateKey(start),
      "endDate": _dateKey(end),
      "active": true,
      "startedById": currentUser?.uid,
      "startedByName": startedByName ?? "",
      "startedAt": FieldValue.serverTimestamp(),
    };

    await firestore
        .collection("attendance_config")
        .doc(
      attendanceConfigId(
        academicYear: academicYear,
        semester: semester,
      ),
    )
        .set(data, SetOptions(merge: true));

    return {
      ...data,
      "startDate": _dateKey(start),
      "endDate": _dateKey(end),
    };
  }

  Future<Map<String, dynamic>?> getAttendanceConfig({
    required String academicYear,
    required String semester,
  }) async {
    final doc = await firestore
        .collection("attendance_config")
        .doc(
      attendanceConfigId(
        academicYear: academicYear,
        semester: semester,
      ),
    )
        .get();

    return doc.exists ? doc.data() : null;
  }

  Future<DateTime?> getAttendanceCalculationEndDate({
    required String academicYear,
    required String semester,
  }) async {
    final config = await getAttendanceConfig(
      academicYear: academicYear,
      semester: semester,
    );

    if (config == null) return null;

    final start = _parseDate(config["startDate"]);
    final end = _parseDate(config["endDate"]);

    if (start == null || end == null) return null;

    final today = _dateOnly(DateTime.now());

    if (today.isBefore(start)) return null;
    return today.isBefore(end) ? today : end;
  }

  // ============================================================
  // HOLIDAY MANAGEMENT
  // ============================================================

  String holidayDocumentId({
    required String academicYear,
    required DateTime date,
  }) {
    return "${academicYear}_${_dateKey(date)}";
  }

  Future<void> addHoliday({
    required String academicYear,
    required DateTime date,
    required String name,
  }) async {
    final day = _dateOnly(date);

    await firestore
        .collection("academic_holidays")
        .doc(
      holidayDocumentId(
        academicYear: academicYear,
        date: day,
      ),
    )
        .set(
      {
        "academicYear": academicYear,
        "date": _dateKey(day),
        "name": name.trim().isEmpty ? "Holiday" : name.trim(),
        "createdById": currentUser?.uid,
        "createdAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeHoliday({
    required String academicYear,
    required DateTime date,
  }) async {
    await firestore
        .collection("academic_holidays")
        .doc(
      holidayDocumentId(
        academicYear: academicYear,
        date: date,
      ),
    )
        .delete();
  }

  Future<List<Map<String, dynamic>>> getHolidays({
    required String academicYear,
  }) async {
    final snapshot = await firestore
        .collection("academic_holidays")
        .where("academicYear", isEqualTo: academicYear)
        .get();

    final result = snapshot.docs.map((doc) {
      return {
        "id": doc.id,
        ...doc.data(),
      };
    }).toList();

    result.sort(
          (a, b) => (a["date"] ?? "")
          .toString()
          .compareTo((b["date"] ?? "").toString()),
    );

    return result;
  }

  Future<bool> isHoliday({
    required String academicYear,
    required DateTime date,
  }) async {
    final doc = await firestore
        .collection("academic_holidays")
        .doc(
      holidayDocumentId(
        academicYear: academicYear,
        date: date,
      ),
    )
        .get();

    return doc.exists;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dateKey(DateTime value) {
    final date = _dateOnly(value);

    return "${date.year.toString().padLeft(4, "0")}-"
        "${date.month.toString().padLeft(2, "0")}-"
        "${date.day.toString().padLeft(2, "0")}";
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
      if (parsed != null) return _dateOnly(parsed);
    }

    return null;
  }
  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[,;/+&]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

}