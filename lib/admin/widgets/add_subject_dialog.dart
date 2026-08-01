import 'package:flutter/material.dart';

import '../../services/subject_service.dart';

class AddSubjectDialog extends StatefulWidget {
  const AddSubjectDialog({super.key});

  @override
  State<AddSubjectDialog> createState() =>
      _AddSubjectDialogState();
}

class _AddSubjectDialogState
    extends State<AddSubjectDialog> {

  final SubjectService service = SubjectService();

  final subjectCodeController =
  TextEditingController();

  final subjectNameController =
  TextEditingController();

  String department = "AIML";
  String year = "1st";
  int semester = 1;
  int credits = 4;
  String type = "Theory";
  String regulation = "R23";

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      title: const Text("Add Subject"),

      content: SingleChildScrollView(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            TextField(
              controller: subjectCodeController,
              decoration: const InputDecoration(
                labelText: "Subject Code",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: subjectNameController,
              decoration: const InputDecoration(
                labelText: "Subject Name",
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: department,

              items: const [

                DropdownMenuItem(
                  value: "AIML",
                  child: Text("AIML"),
                ),

                DropdownMenuItem(
                  value: "CSE",
                  child: Text("CSE"),
                ),

                DropdownMenuItem(
                  value: "CSM",
                  child: Text("CSM"),
                ),

                DropdownMenuItem(
                  value: "ECE",
                  child: Text("ECE"),
                ),

                DropdownMenuItem(
                  value: "EEE",
                  child: Text("EEE"),
                ),
              ],

              onChanged: (v) {
                setState(() {
                  department = v!;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: year,

              items: const [

                DropdownMenuItem(
                  value: "1st",
                  child: Text("1st Year"),
                ),

                DropdownMenuItem(
                  value: "2nd",
                  child: Text("2nd Year"),
                ),

                DropdownMenuItem(
                  value: "3rd",
                  child: Text("3rd Year"),
                ),

                DropdownMenuItem(
                  value: "4th",
                  child: Text("4th Year"),
                ),
              ],

              onChanged: (v) {
                setState(() {
                  year = v!;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<int>(
              value: semester,

              items: List.generate(
                8,
                    (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                    "Semester ${i + 1}",
                  ),
                ),
              ),

              onChanged: (v) {
                setState(() {
                  semester = v!;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<int>(
              value: credits,

              items: const [
                DropdownMenuItem(
                  value: 0,
                  child: Text("0 Credit"),
                ),

                DropdownMenuItem(
                  value: 1,
                  child: Text("1 Credit"),
                ),

                DropdownMenuItem(
                  value: 2,
                  child: Text("2 Credits"),
                ),

                DropdownMenuItem(
                  value: 3,
                  child: Text("3 Credits"),
                ),

                DropdownMenuItem(
                  value: 4,
                  child: Text("4 Credits"),
                ),


              ],

              onChanged: (v) {
                setState(() {
                  credits = v!;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: type,

              items: const [

                DropdownMenuItem(
                  value: "Theory",
                  child: Text("Theory"),
                ),

                DropdownMenuItem(
                  value: "Lab",
                  child: Text("Lab"),
                ),
              ],

              onChanged: (v) {
                setState(() {
                  type = v!;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: regulation,
              items: const [
                DropdownMenuItem(value: "R24", child: Text("R24")),
                DropdownMenuItem(value: "R23", child: Text("R23")),
                DropdownMenuItem(value: "R22", child: Text("R22")),
                DropdownMenuItem(value: "R20", child: Text("R20")),
              ],
              onChanged: (v) {
                setState(() {
                  regulation = v!;
                });
              },
            )
          ],
        ),
      ),

      actions: [

        TextButton(

          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text("Cancel"),
        ),

        ElevatedButton(

          onPressed: () async {

            await service.addSubject(

              subjectCode:
              subjectCodeController.text.trim(),

              subjectName:
              subjectNameController.text.trim(),

              department: department,

              year: year,

              semester: semester,

              credits: credits,

              type: type,

              regulation: regulation,
            );

            if (context.mounted) {

              Navigator.pop(context);

              ScaffoldMessenger.of(context)
                  .showSnackBar(

                const SnackBar(
                  content: Text(
                    "Subject Added Successfully",
                  ),
                ),
              );
            }
          },

          child: const Text("Save"),
        ),
      ],
    );
  }

  @override
  void dispose() {

    subjectCodeController.dispose();

    subjectNameController.dispose();

    super.dispose();
  }
}