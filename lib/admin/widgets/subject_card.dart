import 'dart:ui';
import '../../services/subject_service.dart';
import 'package:flutter/material.dart';

import '../screens/edit_subject_page.dart';
class SubjectCard extends StatelessWidget {
  final Map<String, dynamic> subject;

  const SubjectCard({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),

        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),

          child: Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(.08)
                  : Colors.white.withOpacity(.7),

              borderRadius:
              BorderRadius.circular(25),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                /// Subject Code
                Text(
                  subject["subjectCode"] ?? "",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                /// Subject Name
                Text(
                  subject["subjectName"] ?? "",
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 15),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  children: [

                    chip(
                      Icons.school,
                      subject["department"] ?? "",
                    ),

                    chip(
                      Icons.calendar_today,
                      "Sem ${subject["semester"]}",
                    ),

                    chip(
                      Icons.menu_book,
                      "${subject["credits"]} Credits",
                    ),

                    chip(
                      Icons.science,
                      subject["type"] ?? "",
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Text(
                  "Regulation : ${subject["regulation"]}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const Divider(height: 25),

                Row(

                  mainAxisAlignment:
                  MainAxisAlignment.end,

                  children: [

                    TextButton.icon(

                      onPressed: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) => EditSubjectPage(
                              subject: subject,
                            ),

                          ),

                        );

                      },

                      icon: const Icon(
                        Icons.edit,
                      ),

                      label: const Text(
                        "Edit",
                      ),
                    ),

                    const SizedBox(width: 10),

                    TextButton.icon(

                      onPressed: () async {

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Subject"),
                            content: Text(
                              "Delete ${subject["subjectName"]}?",
                            ),
                            actions: [

                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text("Cancel"),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text("Delete"),
                              ),

                            ],
                          ),
                        );

                        if (confirm == true) {

                          await SubjectService().deleteSubject(
                            subject["subjectCode"],
                          );

                          if (context.mounted) {

                            ScaffoldMessenger.of(context).showSnackBar(

                              const SnackBar(
                                content: Text("Subject Deleted"),
                              ),
                            );
                          }
                        }

                      },

                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),

                      label: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget chip(
      IconData icon,
      String text,
      ) {

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(20),

        color: Colors.blue.withOpacity(.12),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),

          const SizedBox(width: 6),

          Text(text),
        ],
      ),
    );
  }
}