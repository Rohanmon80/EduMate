import 'dart:typed_data';

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
}