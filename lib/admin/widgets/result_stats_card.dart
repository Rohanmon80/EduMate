import 'package:flutter/material.dart';

class ResultStatsCard extends StatelessWidget {

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ResultStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 4,

      child: Container(

        padding: const EdgeInsets.all(18),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 35,
              color: color,
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              textAlign: TextAlign.center,
            ),

          ],

        ),

      ),

    );

  }

}