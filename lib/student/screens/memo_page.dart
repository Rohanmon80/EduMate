import 'package:flutter/material.dart';
import '../../services/memo_service.dart';
import '../widgets/memo_header.dart';
import '../widgets/memo_student_details.dart';
import '../widgets/memo_subject_table.dart';
import '../widgets/memo_summary_card.dart';
class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final MemoService service = MemoService();
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey.shade200,

      appBar: AppBar(

        title: const Text("Provisional Memo"),

        centerTitle: true,

      ),

      body: Center(

        child: SingleChildScrollView(

          child: Container(

            width: 900,

            margin: const EdgeInsets.all(20),

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(15),

              boxShadow: const [

                BoxShadow(

                  blurRadius: 10,

                  color: Colors.black12,

                ),

              ],

            ),

            child: Padding(

              padding: EdgeInsets.all(25),

              child: Column(

                children: [

                  MemoHeader(),

                  SizedBox(height: 20),

                  MemoStudentDetails(),

                  SizedBox(height: 25),

                  MemoSubjectTable(),

                  SizedBox(height: 20),

                  MemoSummaryCard(),

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }
}