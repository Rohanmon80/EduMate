import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class ExcelSubjectService {
  Future<String> downloadTemplate() async {
    final excel = Excel.createExcel();

    final sheet = excel['Subjects'];

    sheet.appendRow([
      TextCellValue("SubjectCode"),
      TextCellValue("SubjectName"),
      TextCellValue("Department"),
      TextCellValue("Year"),
      TextCellValue("Semester"),
      TextCellValue("Credits"),
      TextCellValue("Type"),
      TextCellValue("Regulation"),
    ]);

    final dir = await getTemporaryDirectory();

    final file = File("${dir.path}/Subject_Template.xlsx");


    final bytes = excel.save();

    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    if (!await file.exists()) {
      throw Exception("Template not created");
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "EduMate Subject Template",
    );

    return file.path;
  }
  Future<int> importSubjects() async {

    FilePickerResult? result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) {
      return 0;
    }

    final filePath = result.files.single.path;

    if (filePath == null) {
      return 0;
    }

    final bytes = File(filePath).readAsBytesSync();

    final excel = Excel.decodeBytes(bytes);

    int count = 0;

    final firestore = FirebaseFirestore.instance;

    if (excel.tables.isEmpty) {
      return 0;
    }

    final sheet = excel.tables.values.first;


    for (int i = 1; i < sheet.rows.length; i++) {

      final row = sheet.rows[i];
      if (row.length < 8) {
        continue;
      }

      if (row.isEmpty) continue;

      final subjectCode =
          row[0]?.value.toString().trim() ?? "";

      if (subjectCode.isEmpty) continue;

      final doc = await firestore
          .collection("subjects")
          .doc(subjectCode)
          .get();

      if (doc.exists) {
        continue;
      }

      await firestore
          .collection("subjects")
          .doc(subjectCode)
          .set({

        "subjectCode": subjectCode,

        "subjectName":
        row[1]?.value.toString() ?? "",

        "department":
        row[2]?.value.toString() ?? "",

        "year":
        row[3]?.value.toString() ?? "",

        "semester":
        int.tryParse(
            row[4]?.value.toString() ?? "1") ??
            1,

        "credits":
        double.tryParse(
            row[5]?.value.toString() ?? "0") ??
            0.0,

        "type":
        row[6]?.value.toString() ?? "",

        "regulation":
        row[7]?.value.toString() ?? "",

        "isActive": true,

      });

      count++;
    }

    debugPrint("Imported $count subjects");

    return count;
  }
}