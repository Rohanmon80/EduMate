import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExcelSubjectService {
  Future<void> downloadTemplate() async {

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

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      "${dir.path}/Subject_Template.xlsx",
    );

    final bytes = excel.save();

    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    }
  }
}