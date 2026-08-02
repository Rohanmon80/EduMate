import 'dart:ui';
import '../../services/excel_subject_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/subject_service.dart';
import '../widgets/subject_card.dart';
import '../widgets/add_subject_dialog.dart';

class SubjectManagementPage extends StatefulWidget {
  const SubjectManagementPage({super.key});

  @override
  State<SubjectManagementPage> createState() =>
      _SubjectManagementPageState();
}

class _SubjectManagementPageState
    extends State<SubjectManagementPage> {

  final SubjectService subjectService =
  SubjectService();
  final ExcelSubjectService excelService =
  ExcelSubjectService();

  final TextEditingController searchController =
  TextEditingController();

  String search = "";

  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor:
      isDark
          ? const Color(0xFF07111F)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        title: const Text("Subject Management"),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    "Academic Subjects",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Manage all college subjects",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            TextField(

              controller: searchController,

              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search Subject",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),

              onChanged: (value) {

                setState(() {

                  search = value
                      .trim()
                      .toLowerCase();

                });

              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddSubjectDialog(),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Template"),
                    onPressed: () async {
                      try {

                        final path = await excelService.downloadTemplate();

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Template generated successfully.\nChoose 'Files' to save it.",
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );

                        debugPrint("Template saved at: $path");

                      } catch (e) {

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(e.toString()),
                          ),
                        );

                      }
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Import"),
                    onPressed: () async {

                      final total =
                      await excelService.importSubjects();

                      if (!mounted) return;

                      if (total == 0) {

                        ScaffoldMessenger.of(context).showSnackBar(

                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              "No file selected or no subjects imported",
                            ),
                          ),
                        );

                      } else {

                        ScaffoldMessenger.of(context).showSnackBar(

                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              "$total subjects imported successfully",
                            ),
                          ),
                        );

                      }
                    },
                  ),
                ),

              ],
            ),
            const SizedBox(height: 20),

            Expanded(

              child: StreamBuilder<QuerySnapshot>(

                stream:
                subjectService.getSubjects(),

                builder: (

                    context,

                    snapshot,

                    ) {

                  if (!snapshot.hasData) {

                    return const Center(

                      child:
                      CircularProgressIndicator(),

                    );

                  }

                  final docs =
                      snapshot.data!.docs;

                  if (docs.isEmpty) {

                    return const Center(

                      child: Text(
                        "No Subjects Added",
                      ),
                    );

                  }

                  return ListView.builder(

                    itemCount: docs.length,

                    itemBuilder: (

                        context,

                        index,

                        ) {

                      final data =
                      docs[index].data()

                      as Map<String, dynamic>;

                      if (search.isNotEmpty &&
                          !data["subjectName"]
                              .toString()
                              .toLowerCase()
                              .contains(search) &&
                          !data["subjectCode"]
                              .toString()
                              .toLowerCase()
                              .contains(search)) {

                        return const SizedBox();

                      }

                      return SubjectCard(

                        subject: data,

                      );

                    },
                  );

                },
              ),

            ),


          ], // children

        ), // Column

      ), // Padding

    ); // Scaffold
  }
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  Widget glass(bool dark, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(.08)
                : Colors.white.withOpacity(.7),
            borderRadius: BorderRadius.circular(25),
          ),
          child: child,
        ),
      ),
    );
  }

}