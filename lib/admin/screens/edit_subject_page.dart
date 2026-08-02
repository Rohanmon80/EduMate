import 'package:flutter/material.dart';
import '../../services/subject_service.dart';

class EditSubjectPage extends StatefulWidget {
  final Map<String, dynamic> subject;

  const EditSubjectPage({
    super.key,
    required this.subject,
  });

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  final SubjectService service = SubjectService();

  late TextEditingController codeController;
  late TextEditingController nameController;

  String department = "AIML";
  String year = "1st";
  int semester = 1;
  int credits = 4;
  String type = "Theory";
  String regulation = "R23";

  @override
  void initState() {
    super.initState();

    codeController =
        TextEditingController(text: widget.subject["subjectCode"]);

    nameController =
        TextEditingController(text: widget.subject["subjectName"]);

    department = widget.subject["department"] ?? "AIML";
    year = widget.subject["year"] ?? "1st";
    semester = widget.subject["semester"] ?? 1;
    credits = widget.subject["credits"] ?? 4;
    type = widget.subject["type"] ?? "Theory";
    regulation = widget.subject["regulation"] ?? "R23";
  }

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    await service.updateSubject(
      codeController.text,
      {
        "subjectName": nameController.text.trim(),
        "department": department,
        "year": year,
        "semester": semester,
        "credits": credits,
        "type": type,
        "regulation": regulation,
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Subject Updated Successfully"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Subject"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: codeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Subject Code",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Subject Name",
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: department,
              items: const [
                DropdownMenuItem(value: "AIML", child: Text("AIML")),
                DropdownMenuItem(value: "CSE", child: Text("CSE")),
                DropdownMenuItem(value: "CSM", child: Text("CSM")),
                DropdownMenuItem(value: "ECE", child: Text("ECE")),
                DropdownMenuItem(value: "EEE", child: Text("EEE")),
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
                DropdownMenuItem(value: "1st", child: Text("1st Year")),
                DropdownMenuItem(value: "2nd", child: Text("2nd Year")),
                DropdownMenuItem(value: "3rd", child: Text("3rd Year")),
                DropdownMenuItem(value: "4th", child: Text("4th Year")),
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
                  child: Text("Semester ${i + 1}"),
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
                DropdownMenuItem(value: 0, child: Text("0 Credit")),
                DropdownMenuItem(value: 1, child: Text("1 Credit")),
                DropdownMenuItem(value: 2, child: Text("2 Credits")),
                DropdownMenuItem(value: 3, child: Text("3 Credits")),
                DropdownMenuItem(value: 4, child: Text("4 Credits")),
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
                DropdownMenuItem(value: "Theory", child: Text("Theory")),
                DropdownMenuItem(value: "Lab", child: Text("Lab")),
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
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: save,
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}