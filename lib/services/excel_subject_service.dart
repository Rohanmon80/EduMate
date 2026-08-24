import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

import 'package:excel_community/excel_community.dart';

class ExcelSubjectService {
  // ============================================================
  // DOWNLOAD SUBJECT TEMPLATE
  // ============================================================

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

    final file = File(
      "${dir.path}/Subject_Template.xlsx",
    );

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception("Unable to create subject template.");
    }

    await file.writeAsBytes(bytes, flush: true);

    if (!await file.exists()) {
      throw Exception("Template not created.");
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "EduMate Subject Template",
    );

    return file.path;
  }

  // ============================================================
  // IMPORT SUBJECTS
  // ============================================================

  Future<int> importSubjects() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return 0;
      }

      final pickedFile = result.files.first;

      Uint8List? bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        final filePath = pickedFile.path;

        if (filePath == null || filePath.isEmpty) {
          throw Exception(
            "Excel file path is not available.",
          );
        }

        bytes = await File(filePath).readAsBytes();
      }

      if (bytes.isEmpty) {
        throw Exception("Excel file is empty.");
      }

      debugPrint(
        "SUBJECT EXCEL: ${bytes.length} bytes loaded.",
      );

      // IMPORTANT:
      // Do NOT use Excel.decodeBytes() here.
      // That was causing:
      //
      // Null check operator used on a null value
      // Parser._parseTable
      //
      final rows = _readXlsxRows(bytes);

      if (rows.length <= 1) {
        throw Exception(
          "Excel file contains no subject data.",
        );
      }

      final headers = rows.first
          .map(
            (e) => e.toString().trim(),
      )
          .toList();

      final requiredHeaders = [
        "SubjectCode",
        "SubjectName",
        "Department",
        "Year",
        "Semester",
        "Credits",
        "Type",
        "Regulation",
      ];

      final headerIndex = <String, int>{};

      for (int i = 0; i < headers.length; i++) {
        if (headers[i].isNotEmpty) {
          headerIndex[headers[i]] = i;
        }
      }

      final missingHeaders = requiredHeaders
          .where(
            (header) => !headerIndex.containsKey(header),
      )
          .toList();

      if (missingHeaders.isNotEmpty) {
        throw Exception(
          "Invalid Subject Excel.\n\n"
              "Missing columns:\n"
              "${missingHeaders.join(", ")}\n\n"
              "Please use the EduMate Subject Template.",
        );
      }

      final firestore =
          FirebaseFirestore.instance;

      int count = 0;

      final dataRows = rows.skip(1).where(
            (row) {
          return row.any(
                (cell) =>
            cell != null &&
                cell.toString().trim().isNotEmpty,
          );
        },
      );

      for (final row in dataRows) {
        String readCell(String column) {
          final index = headerIndex[column];

          if (index == null ||
              index >= row.length) {
            return "";
          }

          return row[index]
              .toString()
              .trim();
        }

        final subjectCode =
        readCell("SubjectCode");

        if (subjectCode.isEmpty) {
          continue;
        }

        final subjectName =
        readCell("SubjectName");

        final department =
        readCell("Department");

        final year =
        readCell("Year");

        final semesterText =
        readCell("Semester");

        final creditsText =
        readCell("Credits");

        final type =
        readCell("Type");

        final regulation =
        readCell("Regulation");

        final semester =
        int.tryParse(semesterText);

        final credits =
        double.tryParse(creditsText);

        if (subjectName.isEmpty) {
          throw Exception(
            "Subject $subjectCode: SubjectName is empty.",
          );
        }

        if (semester == null) {
          throw Exception(
            "Subject $subjectCode: Semester must be a number.",
          );
        }

        if (credits == null) {
          throw Exception(
            "Subject $subjectCode: Credits must be a number.",
          );
        }

        if (type.isEmpty) {
          throw Exception(
            "Subject $subjectCode: Type is empty.",
          );
        }

        final docRef = firestore
            .collection("subjects")
            .doc(subjectCode);

        final existing =
        await docRef.get();

        if (existing.exists) {
          debugPrint(
            "Subject already exists: $subjectCode",
          );

          continue;
        }

        await docRef.set({
          "subjectCode": subjectCode,
          "subjectName": subjectName,
          "department": department,
          "year": year,
          "semester": semester,
          "credits": credits,
          "type": type,
          "regulation": regulation,
          "isActive": true,
        });

        count++;

        debugPrint(
          "Imported subject: $subjectCode",
        );
      }

      debugPrint(
        "Imported $count subjects successfully.",
      );

      return count;
    } catch (e, stackTrace) {
      debugPrint(
        "SUBJECT EXCEL IMPORT ERROR: $e",
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // SAFE XLSX READER
  // ============================================================

  List<List<dynamic>> _readXlsxRows(
      Uint8List bytes,
      ) {
    final archive =
    ZipDecoder().decodeBytes(bytes);

    ArchiveFile? findFile(
        String path,
        ) {
      for (final file in archive.files) {
        if (file.name == path) {
          return file;
        }
      }

      return null;
    }

    String readFileText(
        String path,
        ) {
      final file = findFile(path);

      if (file == null) {
        throw Exception(
          "Required XLSX file '$path' was not found.",
        );
      }

      final content = file.content;

      if (content is List<int>) {
        return String.fromCharCodes(content);
      }

      throw Exception(
        "Unable to read XLSX file '$path'.",
      );
    }

    // ----------------------------------------------------------
    // Workbook
    // ----------------------------------------------------------

    final workbookXml =
    XmlDocument.parse(
      readFileText(
        "xl/workbook.xml",
      ),
    );

    XmlElement? sheetElement;

    for (final element
    in workbookXml.descendants
        .whereType<XmlElement>()) {
      if (element.localName == "sheet") {
        final name =
        element.getAttribute("name");

        // Prefer the Subjects worksheet.
        if (name == "Subjects") {
          sheetElement = element;
          break;
        }

        sheetElement ??= element;
      }
    }

    if (sheetElement == null) {
      throw Exception(
        "The Excel workbook contains no worksheet.",
      );
    }

    final relationshipId =
        sheetElement.getAttribute(
          "id",
          namespace:
          "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
        ) ??
            sheetElement.getAttribute("r:id") ??
            sheetElement.getAttribute("id");

    if (relationshipId == null ||
        relationshipId.isEmpty) {
      throw Exception(
        "Unable to find worksheet relationship.",
      );
    }

    // ----------------------------------------------------------
    // Workbook relationships
    // ----------------------------------------------------------

    final relsXml =
    XmlDocument.parse(
      readFileText(
        "xl/_rels/workbook.xml.rels",
      ),
    );

    String? worksheetTarget;

    for (final rel
    in relsXml.descendants
        .whereType<XmlElement>()) {
      if (rel.localName !=
          "Relationship") {
        continue;
      }

      final id =
      rel.getAttribute("Id");

      final target =
      rel.getAttribute("Target");

      if (id == relationshipId &&
          target != null) {
        worksheetTarget = target;
        break;
      }
    }

    if (worksheetTarget == null ||
        worksheetTarget.isEmpty) {
      throw Exception(
        "Unable to locate worksheet.",
      );
    }

    String worksheetPath;

    if (worksheetTarget.startsWith("/")) {
      worksheetPath =
          worksheetTarget.substring(1);
    } else if (worksheetTarget
        .startsWith("xl/")) {
      worksheetPath = worksheetTarget;
    } else {
      worksheetPath =
      "xl/$worksheetTarget";
    }

    // Normalize ../
    final pathParts =
    <String>[];

    for (final part
    in worksheetPath.split("/")) {
      if (part.isEmpty ||
          part == ".") {
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

    worksheetPath =
        pathParts.join("/");

    // ----------------------------------------------------------
    // Worksheet
    // ----------------------------------------------------------

    final worksheetXml =
    XmlDocument.parse(
      readFileText(worksheetPath),
    );

    // ----------------------------------------------------------
    // Shared strings
    // ----------------------------------------------------------

    final sharedStrings =
    <String>[];

    final sharedStringsFile =
    findFile(
      "xl/sharedStrings.xml",
    );

    if (sharedStringsFile != null) {
      final sharedStringsXml =
      XmlDocument.parse(
        String.fromCharCodes(
          sharedStringsFile.content
          as List<int>,
        ),
      );

      for (final si
      in sharedStringsXml
          .descendants
          .whereType<XmlElement>()) {
        if (si.localName != "si") {
          continue;
        }

        final buffer =
        StringBuffer();

        for (final textNode
        in si.descendants
            .whereType<XmlElement>()) {
          if (textNode.localName ==
              "t") {
            buffer.write(
              textNode.innerText,
            );
          }
        }

        sharedStrings.add(
          buffer.toString(),
        );
      }
    }

    // ----------------------------------------------------------
    // Rows
    // ----------------------------------------------------------

    final rows =
    <List<dynamic>>[];

    final rowElements =
    worksheetXml.descendants
        .whereType<XmlElement>()
        .where(
          (element) =>
      element.localName ==
          "row",
    );

    for (final rowElement
    in rowElements) {
      final cells =
      rowElement.children
          .whereType<XmlElement>()
          .where(
            (element) =>
        element.localName ==
            "c",
      )
          .toList();

      if (cells.isEmpty) {
        rows.add([]);
        continue;
      }

      final parsedCells =
      <int, dynamic>{};

      for (final cell in cells) {
        final reference =
        cell.getAttribute("r");

        if (reference == null ||
            reference.isEmpty) {
          continue;
        }

        final columnIndex =
        _xlsxColumnIndex(
          reference,
        );

        if (columnIndex < 0) {
          continue;
        }

        final type =
            cell.getAttribute("t") ??
                "";

        dynamic value = "";

        // Inline string
        if (type == "inlineStr") {
          final buffer =
          StringBuffer();

          for (final element
          in cell.descendants
              .whereType<XmlElement>()) {
            if (element.localName ==
                "t") {
              buffer.write(
                element.innerText,
              );
            }
          }

          value =
              buffer.toString();
        } else {
          XmlElement? valueElement;

          for (final child
          in cell.children
              .whereType<XmlElement>()) {
            if (child.localName ==
                "v") {
              valueElement = child;
              break;
            }
          }

          final rawValue =
              valueElement
                  ?.innerText
                  .trim() ??
                  "";

          if (type == "s") {
            final sharedIndex =
            int.tryParse(
              rawValue,
            );

            if (sharedIndex != null &&
                sharedIndex >= 0 &&
                sharedIndex <
                    sharedStrings
                        .length) {
              value =
              sharedStrings[
              sharedIndex];
            } else {
              value = "";
            }
          } else if (type == "b") {
            value =
                rawValue == "1";
          } else {
            value = rawValue;
          }
        }

        parsedCells[
        columnIndex] =
            value;
      }

      if (parsedCells.isEmpty) {
        rows.add([]);
        continue;
      }

      final maxColumn =
      parsedCells.keys.reduce(
            (a, b) =>
        a > b ? a : b,
      );

      final rowValues =
      List<dynamic>.filled(
        maxColumn + 1,
        "",
      );

      parsedCells.forEach(
            (index, value) {
          rowValues[index] =
              value;
        },
      );

      rows.add(rowValues);
    }

    // Remove empty trailing rows.
    while (rows.isNotEmpty &&
        !rows.last.any(
              (cell) =>
          cell != null &&
              cell
                  .toString()
                  .trim()
                  .isNotEmpty,
        )) {
      rows.removeLast();
    }

    return rows;
  }

  // ============================================================
  // XLSX COLUMN INDEX
  // ============================================================

  int _xlsxColumnIndex(
      String cellReference,
      ) {
    final match =
    RegExp(
      r"^([A-Za-z]+)\d+$",
    ).firstMatch(
      cellReference.trim(),
    );

    if (match == null) {
      return -1;
    }

    final letters =
    match.group(1)!.toUpperCase();

    var result = 0;

    for (final codeUnit
    in letters.codeUnits) {
      result =
          result * 26 +
              (codeUnit - 64);
    }

    return result - 1;
  }
}