import 'dart:ui';
import 'package:flutter/material.dart';

class ExcelPreviewPage extends StatelessWidget {
  final List<List<dynamic>> rows;

  const ExcelPreviewPage({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final headers =
    rows.isNotEmpty ? rows.first : [];

    final previewRows =
    rows.length > 11
        ? rows.sublist(1, 11)
        : rows.sublist(1);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF07111F)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Excel Preview"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [

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
                    "Rows : ${rows.length - 1}",
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Columns : ${headers.length}",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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

                    children:
                    headers
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

            Expanded(
              child: glass(
                isDark,

                SingleChildScrollView(
                  scrollDirection:
                  Axis.horizontal,

                  child: DataTable(
                    columns:
                    headers
                        .map(
                          (e) => DataColumn(
                        label: Text(
                          e.toString(),
                        ),
                      ),
                    )
                        .toList(),

                    rows:
                    previewRows
                        .map(
                          (row) =>
                          DataRow(
                            cells:
                            row
                                .map(
                                  (cell) =>
                                  DataCell(
                                    Text(
                                      cell
                                          ?.toString() ??
                                          "",
                                    ),
                                  ),
                            )
                                .toList(),
                          ),
                    )
                        .toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                          context);
                    },

                    child:
                    const Text(
                      "Cancel",
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child:
                  ElevatedButton.icon(

                    icon: const Icon(
                      Icons.cloud_upload,
                    ),

                    label: const Text(
                      "Upload",
                    ),

                    onPressed: () {

                      ScaffoldMessenger.of(
                          context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Upload feature coming next",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget glass(
      bool dark,
      Widget child) {
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

          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(.08)
                : Colors.white.withOpacity(.7),
          ),

          child: child,
        ),
      ),
    );
  }
}