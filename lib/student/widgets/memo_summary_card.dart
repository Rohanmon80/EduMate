import 'package:flutter/material.dart';

class MemoSummaryCard extends StatelessWidget {
  const MemoSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {

    // Temporary values
    const totalCredits = 22;
    const sgpa = 8.62;
    const cgpa = 8.45;
    const result = "PASS";

    return Column(

      children: [

        const Divider(
          thickness: 2,
        ),

        const SizedBox(height: 20),

        Row(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  summaryRow(
                    "Total Credits",
                    totalCredits.toString(),
                  ),

                  summaryRow(
                    "SGPA",
                    sgpa.toString(),
                  ),

                  summaryRow(
                    "CGPA",
                    cgpa.toString(),
                  ),

                  summaryRow(
                    "Overall Result",
                    result,
                  ),

                ],

              ),

            ),

            const SizedBox(width: 40),

            Column(

              children: [

                const SizedBox(height: 60),

                Container(
                  width: 180,
                  height: 1,
                  color: Colors.black,
                ),

                const SizedBox(height: 8),

                const Text(

                  "Controller of Examinations",

                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),

                ),

              ],

            ),

          ],

        ),

      ],

    );
  }

  Widget summaryRow(
      String title,
      String value,
      ) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 10),

      child: Row(

        children: [

          SizedBox(

            width: 150,

            child: Text(

              title,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),

            ),

          ),

          const Text(" : "),

          Text(value),

        ],

      ),

    );
  }
}