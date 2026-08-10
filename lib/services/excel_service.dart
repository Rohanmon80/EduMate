import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelService {
  // ============================================================
  // PICK EXCEL FILE
  // ============================================================

  Future<List<List<dynamic>>> pickExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null) {
      return [];
    }

    final file = result.files.first;

    if (file.bytes == null) {
      throw Exception("Unable to read the selected Excel file.");
    }

    final Uint8List bytes = file.bytes!;

    final excel = Excel.decodeBytes(bytes);

    final List<List<dynamic>> rows = [];

    for (final tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName];

      if (sheet == null) {
        continue;
      }

      for (final row in sheet.rows) {
        rows.add(row.map((cell) => cell?.value).toList());
      }

      // Only read the first worksheet.
      break;
    }

    return rows;
  }

  // ============================================================
  // DOWNLOAD STUDENT MARKS TEMPLATE
  // ============================================================

  Future<String> downloadMarksTemplate() async {
    final excel = Excel.createExcel();

    final sheet = excel["Student Marks"];

    // Only the information the teacher needs to enter.
    sheet.appendRow([
      TextCellValue("RollNumber"),
      TextCellValue("SubjectCode"),
      TextCellValue("Mid 1"),
      TextCellValue("Mid 2"),
      TextCellValue("External"),
      TextCellValue("Lab Internal 1"),
      TextCellValue("Lab Internal 2"),
      TextCellValue("Lab External"),
      TextCellValue("Type"),
    ]);

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception("Unable to create Excel template.");
    }

    final directory = await getTemporaryDirectory();

    final file = File(
      "${directory.path}/EduMate_Student_Marks_Template.xlsx",
    );

    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "EduMate Student Marks Excel Template",
    );

    return file.path;
  }

  // ============================================================
  // UPLOAD MARKS FROM EXCEL
  // ============================================================

  Future<void> uploadMarks({
    required List<List<dynamic>> rows,
    required String teacherId,
    required String teacherName,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // ------------------------------------------------------------
    // 1. Basic Excel check
    // ------------------------------------------------------------

    if (rows.length <= 1) {
      throw Exception(
        "Excel file is empty or contains no student marks.",
      );
    }

    // ------------------------------------------------------------
    // 2. Required columns
    // ------------------------------------------------------------

    final requiredHeaders = [
      "RollNumber",
      "SubjectCode",
      "Mid 1",
      "Mid 2",
      "External",
      "Lab Internal 1",
      "Lab Internal 2",
      "Lab External",
      "Type",
    ];

    final header = rows.first.map((e) => e.toString().trim()).toList();

    final headerIndex = <String, int>{};

    for (int i = 0; i < header.length; i++) {
      final name = header[i];

      if (name.isNotEmpty) {
        headerIndex[name] = i;
      }
    }

    final missingHeaders = requiredHeaders
        .where((required) => !headerIndex.containsKey(required))
        .toList();

    if (missingHeaders.isNotEmpty) {
    throw Exception(
    "Invalid Excel Template.\n\n"
    "Missing columns:\n"
    "${missingHeaders.join(", ")}\n\n"
    "Please use the EduMate Student Marks Excel Template.",
    );
    }

    // ------------------------------------------------------------
    // 3. Read data rows
    // ------------------------------------------------------------

    final dataRows = rows.skip(1).where((row) {
    return row.any(
    (cell) => cell != null && cell.toString().trim().isNotEmpty,
    );
    }).toList();

    if (dataRows.isEmpty) {
    throw Exception("No marks data found in the Excel file.");
    }

    // ------------------------------------------------------------
    // 4. Helper for reading cells
    // ------------------------------------------------------------

    String readCell(List<dynamic> row, String column) {
    final index = headerIndex[column];

    if (index == null || index >= row.length) {
    return "";
    }

    return row[index]?.toString().trim() ?? "";
    }

    // ------------------------------------------------------------
    // 5. Cache students and subjects
    // ------------------------------------------------------------

    final Map<String, DocumentSnapshot<Map<String, dynamic>>> studentCache =
    {};

    final Map<String, Map<String, dynamic>> subjectCache = {};

    // ------------------------------------------------------------
    // 6. Validate every row
    //
    // IMPORTANT:
    // Different students, subjects and exams are allowed.
    // ------------------------------------------------------------

    final List<String> validationErrors = [];

    for (int i = 0; i < dataRows.length; i++) {
    final row = dataRows[i];
    final excelRowNumber = i + 2;

    final rollNumber = readCell(row, "RollNumber");

    final subjectCode = readCell(row, "SubjectCode");

    final type = readCell(row, "Type");

    // ----------------------------------------------------------
    // Roll Number
    // ----------------------------------------------------------

    if (rollNumber.isEmpty) {
    validationErrors.add(
    "Row $excelRowNumber: RollNumber is empty.",
    );
    } else {
    if (!studentCache.containsKey(rollNumber)) {
    final studentSnapshot = await firestore
        .collection("users")
        .where("role", isEqualTo: "student")
        .where("rollNumber", isEqualTo: rollNumber)
        .limit(1)
        .get();

    if (studentSnapshot.docs.isEmpty) {
    validationErrors.add(
    "Row $excelRowNumber: "
    "Student with Roll Number "
    "$rollNumber does not exist.",
    );
    } else {
    studentCache[rollNumber] = studentSnapshot.docs.first;
    }
    }
    }

    // ----------------------------------------------------------
    // Subject Code
    // ----------------------------------------------------------

    if (subjectCode.isEmpty) {
    validationErrors.add(
    "Row $excelRowNumber: SubjectCode is empty.",
    );
    } else {
    if (!subjectCache.containsKey(subjectCode)) {
    final subjectSnapshot = await firestore
        .collection("subjects")
        .where("subjectCode", isEqualTo: subjectCode)
        .limit(1)
        .get();

    if (subjectSnapshot.docs.isEmpty) {
    validationErrors.add(
    "Row $excelRowNumber: "
    "Subject $subjectCode does not exist.",
    );
    } else {
    subjectCache[subjectCode] = subjectSnapshot.docs.first.data();
    }
    }
    }

    // ----------------------------------------------------------
    // Type
    // ----------------------------------------------------------

    if (type != "Regular" && type != "Supply") {
    validationErrors.add(
    "Row $excelRowNumber: "
    "Type must be Regular or Supply.",
    );
    }

    // ----------------------------------------------------------
    // Determine Theory / Lab
    // ----------------------------------------------------------

    final subjectData = subjectCache[subjectCode];

    if (subjectData == null) {
    continue;
    }

    final subjectType =
    subjectData["type"]?.toString().toLowerCase() ?? "";

    final bool isLab =
    subjectType == "lab" || subjectType.contains("lab");

    final List<String> marksColumns;

    if (isLab) {
    marksColumns = [
    "Lab Internal 1",
    "Lab Internal 2",
    "Lab External",
    ];
    } else {
    marksColumns = [
    "Mid 1",
    "Mid 2",
    "External",
    ];
    }

    // ----------------------------------------------------------
    // Validate marks
    // ----------------------------------------------------------

    bool hasAtLeastOneMark = false;

    for (final column in marksColumns) {
    final text = readCell(row, column);

    if (text.isEmpty) {
    continue;
    }

    hasAtLeastOneMark = true;

    final value = double.tryParse(text);

    if (value == null) {
    validationErrors.add(
    "Row $excelRowNumber: "
    "$column marks must be numeric.",
    );
    continue;
    }

    final int maxMarks = column.contains("External") ? 60 : 40;

    if (value < 0 || value > maxMarks) {
    validationErrors.add(
    "Row $excelRowNumber: "
    "$column marks must be between "
    "0 and $maxMarks.",
    );
    }
    }

    if (!hasAtLeastOneMark) {
    validationErrors.add(
    "Row $excelRowNumber: "
    "At least one mark must be entered.",
    );
    }
    }

    // ------------------------------------------------------------
    // 7. STOP BEFORE FIRESTORE WRITE
    //
    // If even ONE row is invalid, nothing is uploaded.
    // ------------------------------------------------------------

    if (validationErrors.isNotEmpty) {
    throw Exception(
    "Excel validation failed.\n\n"
    "${validationErrors.join("\n")}",
    );
    }

    // ------------------------------------------------------------
    // 8. Firestore batch
    // ------------------------------------------------------------

    final batch = firestore.batch();

    int imported = 0;

    // ------------------------------------------------------------
    // 9. Process every row
    // ------------------------------------------------------------

    for (final row in dataRows) {
    final rollNumber = readCell(row, "RollNumber");

    final subjectCode = readCell(row, "SubjectCode");

    final type = readCell(row, "Type");

    // ----------------------------------------------------------
    // Get student
    // ----------------------------------------------------------

    final studentDoc = studentCache[rollNumber];

    if (studentDoc == null) {
    continue;
    }

    final studentId = studentDoc.id;

    final studentData = studentDoc.data();

    // ----------------------------------------------------------
    // Get subject
    // ----------------------------------------------------------

    final subjectData = subjectCache[subjectCode];

    if (subjectData == null) {
    continue;
    }

    // ----------------------------------------------------------
    // Semester
    // ----------------------------------------------------------

    final firebaseSemester = (subjectData["semester"] as num?)?.toInt();

    if (firebaseSemester == null) {
    throw Exception(
    "Subject $subjectCode does not have "
    "a valid semester in Firebase.",
    );
    }

    // ----------------------------------------------------------
    // Credits
    // ----------------------------------------------------------

    final credits = (subjectData["credits"] as num?)?.toDouble();

    // ----------------------------------------------------------
    // Subject information
    // ----------------------------------------------------------

    final subjectName = subjectData["subjectName"]?.toString() ?? "";

    final subjectType = subjectData["type"]?.toString() ?? "";

    final bool isLab = subjectType.toLowerCase() == "lab" ||
    subjectType.toLowerCase().contains("lab");

    // ----------------------------------------------------------
    // Helper to upload one mark
    // ----------------------------------------------------------

    void uploadMark({
    required String column,
    required String examName,
    }) {
    final marksText = readCell(row, column);

    if (marksText.isEmpty) {
    return;
    }

    final marks = double.parse(marksText);

    final safeExam = examName.replaceAll(
    RegExp(r'[^a-zA-Z0-9]+'),
    "_",
    );

    final safeCategory = type.replaceAll(
    RegExp(r'[^a-zA-Z0-9]+'),
    "_",
    );

    final documentId =
    "${studentId}_${subjectCode}_${safeExam}_${safeCategory}";

    final markRef = firestore.collection("student_marks").doc(documentId);

    batch.set(
    markRef,
    {
    // Student
    "studentId": studentId,

    "rollNumber": studentData?["rollNumber"] ?? rollNumber,

    "studentName": studentData?["name"] ?? "",

    "department": studentData?["department"] ?? "",

    "year": studentData?["year"] ?? "",

    "section": studentData?["section"] ?? "",

    "semester": firebaseSemester,

    "regulation": studentData?["regulation"] ?? "",

    // Subject
    "subjectCode": subjectCode,

    "subjectName": subjectName,

    "type": subjectType,

    "credits": credits,

    // Exam
    "exam": examName,

    "examCategory": type,

    "marks": marks,

    // Teacher
    "teacherId": teacherId,

    "teacherName": teacherName,

    // Result
    "released": false,

    "uploadedAt": FieldValue.serverTimestamp(),

    "uploadedBy": "teacher",

    "uploadMethod": "excel",
    },
    SetOptions(merge: true),
    );

    imported++;
    }

    // ----------------------------------------------------------
    // THEORY
    // ----------------------------------------------------------

    if (!isLab) {
    uploadMark(column: "Mid 1", examName: "Mid 1");

    uploadMark(column: "Mid 2", examName: "Mid 2");

    uploadMark(column: "External", examName: "Sem External");
    }

    // ----------------------------------------------------------
    // LAB
    // ----------------------------------------------------------

    else {
    uploadMark(column: "Lab Internal 1", examName: "Lab Internal 1");

    uploadMark(column: "Lab Internal 2", examName: "Lab Internal 2");

    uploadMark(column: "Lab External", examName: "Lab External");
    }
    }

    // ------------------------------------------------------------
    // 10. Commit all rows together
    // ------------------------------------------------------------

    if (imported == 0) {
    throw Exception("No marks were imported.");
    }

    await batch.commit();
  }
}