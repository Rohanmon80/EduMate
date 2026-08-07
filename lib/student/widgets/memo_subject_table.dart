import 'package:flutter/material.dart';

class MemoSubjectTable extends StatelessWidget {
  const MemoSubjectTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Table(

      border: TableBorder.all(
        color: Colors.black,
      ),

      columnWidths: const {

        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.2),

      },

      children: [

        const TableRow(

          decoration: BoxDecoration(
            color: Color(0xFFE8E8E8),
          ),

          children: [

            tableHeader("Subject Code"),
            tableHeader("Subject Name"),
            tableHeader("Credits"),
            tableHeader("Grade"),
            tableHeader("Result"),

          ],

        ),

        buildRow(
          "AIM501",
          "Artificial Intelligence",
          "4",
          "O",
          "PASS",
        ),

        buildRow(
          "AIM502",
          "Machine Learning",
          "3",
          "A+",
          "PASS",
        ),

        buildRow(
          "AIM503",
          "DBMS",
          "3",
          "A",
          "PASS",
        ),

        buildRow(
          "AIM504",
          "Computer Networks",
          "3",
          "B+",
          "PASS",
        ),

      ],

    );
  }

  static Widget tableHeader(String text) {

    return Padding(

      padding: const EdgeInsets.all(10),

      child: Text(

        text,

        textAlign: TextAlign.center,

        style: const TextStyle(

          fontWeight: FontWeight.bold,

          fontSize: 15,

        ),

      ),

    );
  }

  static TableRow buildRow(
      String code,
      String subject,
      String credits,
      String grade,
      String result,
      ) {

    return TableRow(

      children: [

        cell(code),

        cell(subject),

        cell(credits),

        cell(grade),

        cell(result),

      ],

    );
  }

  static Widget cell(String value) {

    return Padding(

      padding: const EdgeInsets.all(10),

      child: Text(

        value,

        textAlign: TextAlign.center,

      ),

    );
  }
}