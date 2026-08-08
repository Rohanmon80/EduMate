import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/excel_service.dart';

class ExcelPreviewPage extends StatefulWidget {
  final List<List<dynamic>> rows;

  final String teacherId;
  final String teacherName;

  const ExcelPreviewPage({
    super.key,
    required this.rows,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<ExcelPreviewPage> createState() =>
      _ExcelPreviewPageState();
}

class _ExcelPreviewPageState
    extends State<ExcelPreviewPage> {

  bool uploading = false;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final headers =
    widget.rows.isNotEmpty
        ? widget.rows.first
        : [];

    final previewRows =
    widget.rows.length > 11
        ? widget.rows.sublist(1, 11)
        : widget.rows.length > 1
        ? widget.rows.sublist(1)
        : [];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF07111F)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Excel Preview",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [

            // --------------------------------------------------
            // Excel Summary
            // --------------------------------------------------

            glass(
              isDark,

              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Excel Summary",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Rows : ${widget.rows.length > 1 ? widget.rows.length - 1 : 0}",
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Columns : ${headers.length}",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // Detected Columns
            // --------------------------------------------------

            glass(
              isDark,

              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Detected Columns",
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,

                    children: headers
                        .map(
                          (e) => Chip(
                        label: Text(
                          e.toString(),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // Excel Data Preview
            // --------------------------------------------------

            Expanded(
              child: glass(
                isDark,

                SingleChildScrollView(
                  scrollDirection:
                  Axis.horizontal,

                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: headers
                          .map(
                            (e) => DataColumn(
                          label: Text(
                            e.toString(),
                          ),
                        ),
                      )
                          .toList(),

                      rows: previewRows
                          .map(
                            (row) => DataRow(
                          cells: List.generate(
                            headers.length,
                                (index) {

                              final value =
                              index <
                                  row.length
                                  ? row[index]
                                  : "";

                              return DataCell(
                                Text(
                                  value
                                      ?.toString() ??
                                      "",
                                ),
                              );
                            },
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --------------------------------------------------
            // Buttons
            // --------------------------------------------------

            Row(
              children: [

                Expanded(
                  child: OutlinedButton(
                    onPressed: uploading
                        ? null
                        : () {
                      Navigator.pop(
                        context,
                      );
                    },

                    child: const Text(
                      "Cancel",
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child:
                  ElevatedButton.icon(

                    icon: uploading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.cloud_upload,
                    ),

                    label: Text(
                      uploading
                          ? "Uploading..."
                          : "Upload",
                    ),

                    onPressed: uploading
                        ? null
                        : uploadExcel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Upload Excel
  // ============================================================

  Future<void> uploadExcel() async {

    setState(() {
      uploading = true;
    });

    try {

      await ExcelService().uploadMarks(

        rows: widget.rows,

        teacherId:
        widget.teacherId,

        teacherName:
        widget.teacherName,

      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor:
          Colors.green,
          content: Text(
            "Marks Uploaded Successfully",
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.red,
          content: Text(
            e.toString(),
          ),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  // ============================================================
  // Glass UI
  // ============================================================

  Widget glass(
      bool dark,
      Widget child,
      ) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(25),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(
          padding:
          const EdgeInsets.all(15),

          decoration:
          BoxDecoration(
            color: dark
                ? Colors.white
                .withValues(alpha: .08)
                : Colors.white
                .withValues(alpha: .7),

            borderRadius:
            BorderRadius.circular(25),
          ),

          child: child,
        ),
      ),
    );
  }
}