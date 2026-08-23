import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel_community/excel_community.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
class ExcelService {

  // ============================================================
  // PICK EXCEL FILE - shared by Marks and Timetable
  // ============================================================

  Future<List<List<dynamic>>> pickExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final pickedFile = result.files.first;

    Uint8List? bytes = pickedFile.bytes;

    if (bytes == null || bytes.isEmpty) {
      final path = pickedFile.path;

      if (path == null || path.isEmpty) {
        throw Exception(
          "Excel file path is not available.",
        );
      }

      bytes = await File(path).readAsBytes();
    }

    if (bytes.isEmpty) {
      throw Exception("Excel file is empty.");
    }

    debugPrint(
      "EXCEL: file read successfully. Bytes = ${bytes.length}",
    );

    try {
      // IMPORTANT:
      // Do NOT use Excel.decodeBytes().
      //
      // The excel_community parser is crashing on the
      // uploaded XLSX workbook.
      //
      // Use the same safe XLSX reader used by timetable import.

      final rows = _decodeTimetableXlsx(bytes);

      if (rows.isEmpty) {
        throw Exception(
          "The Excel file contains no rows.",
        );
      }

      debugPrint(
        "EXCEL: ${rows.length} rows loaded successfully.",
      );

      return rows;
    } catch (e, stackTrace) {
      debugPrint(
        "EXCEL READ ERROR: $e",
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Unable to read the Excel file. "
            "Please make sure it is a valid .xlsx workbook.",
      );
    }
  }


  // ============================================================
  // PICK EXCEL FILE
  // ============================================================

  Future<List<List<dynamic>>> pickTimetableExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final pickedFile = result.files.first;

    Uint8List? bytes = pickedFile.bytes;

    if (bytes == null || bytes.isEmpty) {
      final path = pickedFile.path;

      if (path == null || path.isEmpty) {
        throw Exception("Timetable Excel file path is not available.");
      }

      bytes = await File(path).readAsBytes();
    }

    if (bytes.isEmpty) {
      throw Exception("Timetable Excel file is empty.");
    }

    debugPrint(
      "TIMETABLE EXCEL: file read successfully. Bytes = ${bytes.length}",
    );

    try {
      final rows = _decodeTimetableXlsx(bytes);

      if (rows.isEmpty) {
        throw Exception("Timetable Excel contains no rows.");
      }

      debugPrint(
        "TIMETABLE EXCEL: ${rows.length} rows loaded successfully.",
      );

      return rows;
    } catch (e, stackTrace) {
      debugPrint("TIMETABLE EXCEL READ ERROR: $e");
      debugPrintStack(stackTrace: stackTrace);

      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        "Unable to read the timetable Excel file. "
            "Please make sure it is a valid .xlsx workbook.",
      );
    }
  }

  // ============================================================
  // XLSX READER FOR TIMETABLE
  //
  // This deliberately does NOT use Excel.decodeBytes().
  // Therefore workbook styles cannot break timetable importing.
  //
  // XLSX is a ZIP file containing XML files. We only read the
  // worksheet data needed by the timetable parser.
  // ============================================================

  List<List<dynamic>> _decodeTimetableXlsx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? findFile(String path) {
      for (final file in archive.files) {
        if (file.name == path) {
          return file;
        }
      }
      return null;
    }

    String readFileText(String path) {
      final file = findFile(path);

      if (file == null) {
        throw Exception("Required XLSX file '$path' was not found.");
      }

      final content = file.content;

      if (content is List<int>) {
        return String.fromCharCodes(content);
      }

      throw Exception("Unable to read XLSX file '$path'.");
    }

    final workbookXml = XmlDocument.parse(
      readFileText("xl/workbook.xml"),
    );

    // Find the first worksheet from workbook.xml.
    XmlElement? sheetElement;

    for (final element in workbookXml.descendants.whereType<XmlElement>()) {
      if (element.localName == "sheet") {
        sheetElement = element;
        break;
      }
    }

    if (sheetElement == null) {
      throw Exception("The Excel workbook has no worksheet.");
    }

    final relationshipId =
        sheetElement.getAttribute("id", namespace: "http://schemas.openxmlformats.org/officeDocument/2006/relationships") ??
            sheetElement.getAttribute("r:id") ??
            sheetElement.getAttribute("id");

    if (relationshipId == null || relationshipId.isEmpty) {
      throw Exception("Unable to find the timetable worksheet relationship.");
    }

    final relsXml = XmlDocument.parse(
      readFileText("xl/_rels/workbook.xml.rels"),
    );

    String? worksheetTarget;

    for (final rel in relsXml.descendants.whereType<XmlElement>()) {
      if (rel.localName != "Relationship") {
        continue;
      }

      final id = rel.getAttribute("Id");
      final target = rel.getAttribute("Target");

      if (id == relationshipId && target != null) {
        worksheetTarget = target;
        break;
      }
    }

    if (worksheetTarget == null || worksheetTarget.isEmpty) {
      throw Exception("Unable to locate the timetable worksheet.");
    }

    String worksheetPath;

    if (worksheetTarget.startsWith("/")) {
      worksheetPath = worksheetTarget.substring(1);
    } else if (worksheetTarget.startsWith("xl/")) {
      worksheetPath = worksheetTarget;
    } else {
      worksheetPath = "xl/$worksheetTarget";
    }

    // Normalise any ../ segments.
    final pathParts = <String>[];
    for (final part in worksheetPath.split("/")) {
      if (part.isEmpty || part == ".") {
        continue;
      }

      if (part == "..") {
        if (pathParts.isNotEmpty) {
          pathParts.removeLast();
        }
      } else {
        pathParts.add(part);
      }
    }

    worksheetPath = pathParts.join("/");

    final worksheetXml = XmlDocument.parse(
      readFileText(worksheetPath),
    );

    // ------------------------------------------------------------
    // Shared strings
    // ------------------------------------------------------------

    final sharedStrings = <String>[];

    final sharedStringsFile = findFile("xl/sharedStrings.xml");

    if (sharedStringsFile != null) {
      final sharedStringsXml = XmlDocument.parse(
        String.fromCharCodes(
          (sharedStringsFile.content as List<int>),
        ),
      );

      for (final si in sharedStringsXml.descendants.whereType<XmlElement>()) {
        if (si.localName != "si") {
          continue;
        }

        final buffer = StringBuffer();

        for (final textNode
        in si.descendants.whereType<XmlElement>()) {
          if (textNode.localName == "t") {
            buffer.write(textNode.innerText);
          }
        }

        sharedStrings.add(buffer.toString());
      }
    }

    // ------------------------------------------------------------
    // Worksheet rows/cells
    // ------------------------------------------------------------

    final rows = <List<dynamic>>[];

    final rowElements = worksheetXml.descendants
        .whereType<XmlElement>()
        .where((element) => element.localName == "row");

    for (final rowElement in rowElements) {
      final cells = rowElement.children
          .whereType<XmlElement>()
          .where((element) => element.localName == "c")
          .toList();

      if (cells.isEmpty) {
        rows.add([]);
        continue;
      }

      final parsedCells = <int, dynamic>{};

      for (final cell in cells) {
        final reference = cell.getAttribute("r");

        if (reference == null || reference.isEmpty) {
          continue;
        }

        final columnIndex = _xlsxColumnIndex(reference);

        if (columnIndex < 0) {
          continue;
        }

        final type = cell.getAttribute("t") ?? "";

        dynamic value = "";

        // Inline string: <c t="inlineStr"><is><t>...</t></is></c>
        if (type == "inlineStr") {
          final buffer = StringBuffer();

          for (final element
          in cell.descendants.whereType<XmlElement>()) {
            if (element.localName == "t") {
              buffer.write(element.innerText);
            }
          }

          value = buffer.toString();
        } else {
          XmlElement? valueElement;

          for (final child in cell.children.whereType<XmlElement>()) {
            if (child.localName == "v") {
              valueElement = child;
              break;
            }
          }

          final rawValue = valueElement?.innerText.trim() ?? "";

          if (type == "s") {
            final sharedIndex = int.tryParse(rawValue);

            if (sharedIndex != null &&
                sharedIndex >= 0 &&
                sharedIndex < sharedStrings.length) {
              value = sharedStrings[sharedIndex];
            } else {
              value = "";
            }
          } else if (type == "b") {
            value = rawValue == "1";
          } else {
            // For timetable we want text exactly as entered whenever
            // possible. Numeric values are kept as strings so the
            // timetable parser can handle them safely.
            value = rawValue;
          }
        }

        parsedCells[columnIndex] = value;
      }

      final maxColumn = parsedCells.keys.isEmpty
          ? -1
          : parsedCells.keys.reduce(
            (a, b) => a > b ? a : b,
      );

      if (maxColumn < 0) {
        rows.add([]);
        continue;
      }

      final rowValues = List<dynamic>.filled(
        maxColumn + 1,
        "",
      );

      parsedCells.forEach((index, value) {
        rowValues[index] = value;
      });

      rows.add(rowValues);
    }

    // Remove completely empty trailing rows.
    while (rows.isNotEmpty &&
        !rows.last.any(
              (cell) =>
          cell != null &&
              cell.toString().trim().isNotEmpty,
        )) {
      rows.removeLast();
    }

    return rows;
  }

  int _xlsxColumnIndex(String cellReference) {
    final match = RegExp(
      r"^([A-Za-z]+)\d+$",
    ).firstMatch(cellReference.trim());

    if (match == null) {
      return -1;
    }

    final letters = match.group(1)!.toUpperCase();

    var result = 0;

    for (final codeUnit in letters.codeUnits) {
      result = result * 26 + (codeUnit - 64);
    }

    return result - 1;
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

  // ============================================================
  // TIMETABLE EXCEL
  // ============================================================

  /// Creates a standard EduMate timetable Excel template.
  ///
  /// One row represents one period.
  ///
  /// Required columns:
  /// Day, StartTime, EndTime, SubjectCode, Subject, Type,
  /// TeacherID, CountsAttendance
  ///
  /// TeacherID can contain multiple IDs for a lab:
  /// T003,T006
  Future<String> downloadTimetableTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel["Timetable"];

    sheet.appendRow([
      TextCellValue("Day"),
      TextCellValue("StartTime"),
      TextCellValue("EndTime"),
      TextCellValue("SubjectCode"),
      TextCellValue("Subject"),
      TextCellValue("Type"),
      TextCellValue("TeacherID"),
      TextCellValue("CountsAttendance"),
    ]);

    final examples = <List<String>>[
      [
        "Monday",
        "09:30",
        "10:30",
        "KRR",
        "KRR",
        "Theory",
        "T001",
        "Yes",
      ],
      [
        "Monday",
        "10:30",
        "11:30",
        "DA",
        "DA",
        "Theory",
        "T004",
        "Yes",
      ],
      [
        "Monday",
        "14:10",
        "16:10",
        "DA-LAB",
        "DA Lab",
        "Lab",
        "T004,T006",
        "Yes",
      ],
      [
        "Thursday",
        "11:30",
        "12:30",
        "LIB",
        "Library",
        "Library",
        "",
        "No",
      ],
      [
        "Saturday",
        "14:10",
        "16:10",
        "SPORTS",
        "Sports",
        "Sports",
        "",
        "No",
      ],
    ];

    for (final row in examples) {
      sheet.appendRow(
        row.map((value) => TextCellValue(value)).toList(),
      );
    }

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception("Unable to create timetable Excel template.");
    }

    final directory = await getTemporaryDirectory();

    final file = File(
      "${directory.path}/EduMate_Timetable_Template.xlsx",
    );

    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "EduMate Timetable Excel Template",
    );

    return file.path;
  }

  /// Picks a timetable Excel file.
  ///
  /// This uses the same Excel picker already used by marks.

  /// Parses and validates timetable rows.
  ///
  /// [teachers] must contain records like:
  ///
  /// {
  ///   'uid': Firebase document ID,
  ///   'teacherId': 'T003',
  ///   'name': 'Teacher Name',
  ///   'department': 'AIML'
  /// }
  ///
  /// The returned schedule is compatible with the timetable page:
  ///
  /// {
  ///   'Monday': [
  ///     {
  ///       'subject': 'KRR',
  ///       'startTime': '09:30',
  ///       'endTime': '10:30',
  ///       'hours': 1.0,
  ///       'type': 'Theory',
  ///       'countsForAttendance': true,
  ///       'teacherId': 'T003',
  ///       'teacherUid': '...',
  ///       'teacherName': '...'
  ///     }
  ///   ]
  /// }
  ///
  /// If any validation error exists, NOTHING is returned as a valid
  /// timetable. The caller should show the errors and not save to Firebase.
  Map<String, List<Map<String, dynamic>>> parseTimetableExcel({
    required List<List<dynamic>> rows,
    required List<Map<String, dynamic>> teachers,
  }) {
    if (rows.length <= 1) {
      throw Exception(
        "Timetable Excel is empty or contains no timetable rows.",
      );
    }

    final headers = rows.first
        .map((e) => e?.toString().trim() ?? "")
        .toList();

    final headerIndex = <String, int>{};

    for (int i = 0; i < headers.length; i++) {
      final normalized = _normalizeTimetableHeader(headers[i]);
      if (normalized.isNotEmpty) {
        headerIndex[normalized] = i;
      }
    }

    const requiredHeaders = [
      "day",
      "starttime",
      "endtime",
      "subjectcode",
      "subject",
      "type",
      "teacherid",
      "countsattendance",
    ];

    final missing = requiredHeaders
        .where((header) => !headerIndex.containsKey(header))
        .toList();

    if (missing.isNotEmpty) {
      throw Exception(
        "Invalid Timetable Excel.\n\n"
            "Missing columns:\n"
            "${missing.join(", ")}\n\n"
            "Please download and use the EduMate Timetable Excel Template.",
      );
    }

    final dataRows = rows.skip(1).where((row) {
      return row.any(
            (cell) => cell != null && cell.toString().trim().isNotEmpty,
      );
    }).toList();

    if (dataRows.isEmpty) {
      throw Exception("No timetable data found in the Excel file.");
    }

    final errors = <String>[];

    final schedule = <String, List<Map<String, dynamic>>>{
      "Monday": [],
      "Tuesday": [],
      "Wednesday": [],
      "Thursday": [],
      "Friday": [],
      "Saturday": [],
    };

    final teacherMap = <String, Map<String, dynamic>>{};

    for (final teacher in teachers) {
      final id = (
          teacher["teacherId"] ??
              teacher["id"] ??
              ""
      ).toString().trim().toUpperCase();

      if (id.isNotEmpty) {
        teacherMap[id] = teacher;
      }
    }

    String readCell(List<dynamic> row, String header) {
      final index = headerIndex[header];
      if (index == null || index >= row.length) return "";
      return row[index]?.toString().trim() ?? "";
    }

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final excelRow = i + 2;

      final dayRaw = readCell(row, "day");
      final startRaw = readCell(row, "starttime");
      final endRaw = readCell(row, "endtime");
      final subjectCode = readCell(row, "subjectcode");
      final subject = readCell(row, "subject");
      final typeRaw = readCell(row, "type");
      final teacherIdsRaw = readCell(row, "teacherid");
      final countsRaw = readCell(row, "countsattendance");

      final day = _normalizeTimetableDay(dayRaw);

      if (day == null) {
        errors.add(
          "Row $excelRow: Invalid Day '$dayRaw'. "
              "Use Monday to Saturday.",
        );
        continue;
      }

      final start = _parseTimetableTime(startRaw);
      final end = _parseTimetableTime(endRaw);

      if (start == null) {
        errors.add(
          "Row $excelRow: Invalid StartTime '$startRaw'. "
              "Use HH:mm, for example 09:30.",
        );
        continue;
      }

      if (end == null) {
        errors.add(
          "Row $excelRow: Invalid EndTime '$endRaw'. "
              "Use HH:mm, for example 10:30.",
        );
        continue;
      }

      if (end <= start) {
        errors.add(
          "Row $excelRow: EndTime must be after StartTime.",
        );
        continue;
      }

      if (subjectCode.isEmpty) {
        errors.add(
          "Row $excelRow: SubjectCode is empty.",
        );
      }

      if (subject.isEmpty) {
        errors.add(
          "Row $excelRow: Subject is empty.",
        );
      }

      final type = _normalizeTimetableType(typeRaw);

      if (type == null) {
        errors.add(
          "Row $excelRow: Type '$typeRaw' is invalid. "
              "Use Theory, Lab, Library, Sports or Other.",
        );
      }

      final countsAttendance =
      _parseAttendanceFlag(countsRaw);

      if (countsAttendance == null) {
        errors.add(
          "Row $excelRow: CountsAttendance must be Yes or No.",
        );
      }

      final teacherIds = teacherIdsRaw
          .split(RegExp(r'[,;/+&]+'))
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toList();

      // Library and Sports normally have no teacher.
      // Other attendance-counting periods should normally have a teacher.
      if (teacherIds.isEmpty &&
          countsAttendance == true &&
          type != "Library" &&
          type != "Sports") {
        errors.add(
          "Row $excelRow: TeacherID is required for "
              "attendance-counting periods.",
        );
      }

      final matchedTeachers = <Map<String, dynamic>>[];

      for (final teacherId in teacherIds) {
        final teacher = teacherMap[teacherId];

        if (teacher == null) {
          errors.add(
            "Row $excelRow: Teacher ID '$teacherId' "
                "was not found in Firebase teachers.",
          );
        } else {
          matchedTeachers.add(teacher);
        }
      }

      if (subject.isEmpty || type == null || countsAttendance == null) {
        continue;
      }

      final durationMinutes = end - start;

      // Do not allow a normal theory period to accidentally become
      // an unreasonable duration.
      if (durationMinutes > 240) {
        errors.add(
          "Row $excelRow: Period duration is "
              "${durationMinutes} minutes, which is too long.",
        );
        continue;
      }

      final hours = durationMinutes / 60.0;

      // Prevent duplicate timetable slots.
      final duplicate = (schedule[day] ?? []).any((existing) {
        final existingStart =
        _parseTimetableTime(
          existing["startTime"]?.toString() ?? "",
        );

        final existingEnd =
        _parseTimetableTime(
          existing["endTime"]?.toString() ?? "",
        );

        if (existingStart == null || existingEnd == null) {
          return false;
        }

        // Two periods overlap if:
        // startA < endB && startB < endA
        return start < existingEnd &&
            existingStart < end;
      });

      if (duplicate) {
        errors.add(
          "Row $excelRow: Period $day "
              "${_minutesToTime(start)}-${_minutesToTime(end)} "
              "overlaps another timetable period.",
        );
        continue;
      }

      final teacherUids = matchedTeachers
          .map(
            (teacher) => (
            teacher["uid"] ??
                teacher["id"] ??
                ""
        ).toString(),
      )
          .where((value) => value.isNotEmpty)
          .toList();

      final teacherNames = matchedTeachers
          .map(
            (teacher) =>
            (teacher["name"] ?? "").toString(),
      )
          .where((value) => value.isNotEmpty)
          .toList();

      schedule[day] ??= [];

      schedule[day]!.add({
        "subject": subject,
        "subjectCode": subjectCode,
        "startTime": _minutesToTime(start),
        "endTime": _minutesToTime(end),
        "hours": double.parse(hours.toStringAsFixed(2)),
        "type": type,
        "countsForAttendance": countsAttendance,

        // Backward-compatible single teacher fields.
        "teacherId": teacherIds.isEmpty
            ? ""
            : teacherIds.first,
        "teacherUid": teacherUids.isEmpty
            ? ""
            : teacherUids.first,
        "teacherName": teacherNames.isEmpty
            ? ""
            : teacherNames.first,

        // Correct representation for labs with multiple teachers.
        "teacherIds": teacherIds,
        "teacherUids": teacherUids,
        "teacherNames": teacherNames,

        "teacherMatchStatus": teacherIds.isEmpty
            ? "NOT_REQUIRED"
            : matchedTeachers.length == teacherIds.length
            ? "MATCHED"
            : "NOT_FOUND",

        "source": "excel",
      });
    }

    if (errors.isNotEmpty) {
      throw Exception(
        "Timetable Excel validation failed.\n\n"
            "${errors.join("\n")}",
      );
    }

    for (final day in schedule.keys) {
      schedule[day] ??= [];

      schedule[day]!.sort((a, b) {
        final aTime = _parseTimetableTime(
          a["startTime"]?.toString() ?? "",
        ) ??
            99999;

        final bTime = _parseTimetableTime(
          b["startTime"]?.toString() ?? "",
        ) ??
            99999;

        return aTime.compareTo(bTime);
      });
    }

    return schedule;
  }

  String _normalizeTimetableHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[\s_\-]+"), "");
  }

  String? _normalizeTimetableDay(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z]"), "");

    const dayMap = {
      "monday": "Monday",
      "mon": "Monday",
      "tuesday": "Tuesday",
      "tue": "Tuesday",
      "tues": "Tuesday",
      "wednesday": "Wednesday",
      "wed": "Wednesday",
      "thursday": "Thursday",
      "thu": "Thursday",
      "thur": "Thursday",
      "thurs": "Thursday",
      "friday": "Friday",
      "fri": "Friday",
      "saturday": "Saturday",
      "sat": "Saturday",
    };

    return dayMap[normalized];
  }

  String? _normalizeTimetableType(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[\s_\-]+"), "");

    switch (normalized) {
      case "theory":
      case "lecture":
      case "class":
        return "Theory";

      case "lab":
      case "laboratory":
      case "practical":
        return "Lab";

      case "library":
      case "lib":
        return "Library";

      case "sports":
      case "sport":
      case "games":
        return "Sports";

      case "other":
      case "seminar":
      case "counselling":
      case "counseling":
        return "Other";

      default:
        return null;
    }
  }

  bool? _parseAttendanceFlag(String value) {
    final normalized = value.trim().toLowerCase();

    if ([
      "yes",
      "y",
      "true",
      "1",
      "present",
      "count",
    ].contains(normalized)) {
      return true;
    }

    if ([
      "no",
      "n",
      "false",
      "0",
      "not",
      "dontcount",
      "don'tcount",
    ].contains(normalized)) {
      return false;
    }

    return null;
  }

  int? _parseTimetableTime(String value) {
    var text = value.trim().toUpperCase();

    if (text.isEmpty) return null;

    // Excel may provide values such as:
    // 09:30
    // 9:30 AM
    // 09.30
    text = text.replaceAll(".", ":");

    final amPmMatch = RegExp(
      r"^(.*?)(?:\s*)(AM|PM)$",
    ).firstMatch(text);

    String? amPm;

    if (amPmMatch != null) {
      text = amPmMatch.group(1)!.trim();
      amPm = amPmMatch.group(2);
    }

    final match = RegExp(
      r"^(\d{1,2})(?::(\d{1,2}))?$",
    ).firstMatch(text);

    if (match == null) {
      return null;
    }

    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? "0");

    if (hour == null || minute == null) {
      return null;
    }

    if (minute < 0 || minute > 59) {
      return null;
    }

    if (amPm != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }

      if (amPm == "AM") {
        if (hour == 12) hour = 0;
      } else {
        if (hour != 12) hour += 12;
      }
    } else {
      if (hour < 0 || hour > 23) {
        return null;
      }
    }

    return hour * 60 + minute;
  }

  String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return "${hour.toString().padLeft(2, "0")}:"
        "${minute.toString().padLeft(2, "0")}";
  }

}
