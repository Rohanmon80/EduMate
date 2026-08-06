import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelService {

  Future<List<List<dynamic>>> pickExcel() async {

    FilePickerResult? result =
    await FilePicker.platform.pickFiles(

      type: FileType.custom,

      allowedExtensions: ['xlsx', 'xls'],

      withData: true,

    );

    if (result == null) {
      return [];
    }

    Uint8List bytes = result.files.first.bytes!;

    final excel = Excel.decodeBytes(bytes);

    List<List<dynamic>> rows = [];

    for (final table in excel.tables.keys) {

      final sheet = excel.tables[table];

      if (sheet == null) continue;

      for (final row in sheet.rows) {

        rows.add(

          row.map((e) => e?.value).toList(),

        );

      }

      break;
    }

    return rows;
  }
  Future<void> uploadMarks({
    required List<List<dynamic>> rows,
    required String subjectCode,
    required String subjectName,
    required String exam,
    required String teacherId,
    required String teacherName,
  }) async {

    final firestore = FirebaseFirestore.instance;

    if (rows.length <= 1) {
      throw Exception("Excel file is empty.");
    }

    // ---------- Validate Header ----------
    final header = rows.first.map((e) => e.toString().trim()).toList();

    if (header.length < 3 ||
        header[0] != "RollNumber" ||
        header[1] != "StudentName" ||
        header[2] != "Marks") {

      throw Exception(
        "Invalid Excel Template.\n"
            "Header must be:\n"
            "RollNumber | StudentName | Marks",
      );
    }

    int imported = 0;
    List<String> skipped = [];

    for (int i = 1; i < rows.length; i++) {

      final row = rows[i];

      if (row.length < 3) {
        skipped.add("Row ${i + 1}: Incomplete data");
        continue;
      }

      final roll =
      row[0].toString().trim();

      final marks =
      int.tryParse(row[2].toString());

      if (roll.isEmpty) {
        skipped.add("Row ${i + 1}: Roll Number empty");
        continue;
      }

      if (marks == null) {
        skipped.add("Row ${i + 1}: Invalid marks");
        continue;
      }

      if (marks < 0 || marks > 100) {
        skipped.add("Row ${i + 1}: Marks must be 0-100");
        continue;
      }

      final student = await firestore
          .collection("users")
          .where("role", isEqualTo: "student")
          .where("rollNumber", isEqualTo: roll)
          .limit(1)
          .get();

      if (student.docs.isEmpty) {
        skipped.add("Row ${i + 1}: Student not found");
        continue;
      }

      final doc = student.docs.first;

      final data =
      doc.data();

      await firestore
          .collection("student_marks")
          .doc("${doc.id}_${subjectCode}_$exam")
          .set({

        "studentId": doc.id,

        "rollNumber": data["rollNumber"],

        "studentName": data["name"],

        "department": data["department"],

        "year": data["year"],

        "semester": data["semester"],

        "section": data["section"],

        "subjectCode": subjectCode,

        "subjectName": subjectName,

        "exam": exam,

        "marks": marks,

        "teacherId": teacherId,

        "teacherName": teacherName,

        "released": false,

        "uploadedAt":
        FieldValue.serverTimestamp(),

        "uploadedBy": "teacher",

      }, SetOptions(merge: true));

      imported++;
    }

    if (skipped.isNotEmpty) {

      throw Exception(

        "Imported : $imported\n\n"

            "Skipped : ${skipped.length}\n\n"

            "${skipped.join("\n")}",

      );

    }

  }
}