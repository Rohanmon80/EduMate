import 'package:flutter/material.dart';

class MemoHeader extends StatelessWidget {
  const MemoHeader({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(

      children: [

        Row(

          children: [

            Image.asset(
              "assets/logo.png",
              height: 70,
            ),

            const SizedBox(width: 20),

            const Expanded(

              child: Column(

                children: [

                  Text(

                    "SCIENT INSTITUTION OF TECHNOLOGY",

                    textAlign: TextAlign.center,

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  SizedBox(height: 8),

                  Text(

                    "PROVISIONAL GRADE MEMO",

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

        Divider(
          thickness: 2,
        ),

      ],

    );

  }
}