import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'role_selection_page.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen>
  createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>

    with
        SingleTickerProviderStateMixin {

  late AnimationController
  controller;

  @override
  void initState() {

    super.initState();

    controller =

    AnimationController(

      vsync: this,

      duration:
      const Duration(
        seconds: 2,
      ),
    )

      ..repeat();

    WidgetsBinding
        .instance

        .addPostFrameCallback(

          (_) {

        goNext();
      },
    );
  }

  Future<void>
  goNext() async {

    await Future.delayed(

      const Duration(
        seconds: 3,
      ),
    );

    if (
    mounted
    ) {

      Navigator.of(
        context,
      )

          .pushReplacement(

        MaterialPageRoute(

          builder:
              (_) =>

          const RoleSelectionPage(),
        ),
      );
    }
  }

  @override
  void dispose() {

    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(
        0xFFF4F8FC,
      ),

      body:
      Center(

        child:
        Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            Image.asset(

              "assets/images/logo.png",

              width: 300,

              height: 300,

              fit:
              BoxFit.contain,
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(

              "EduMate",

              style: TextStyle(

                fontSize: 42,

                fontWeight:
                FontWeight.bold,

                color:
                Color(
                  0xFF0B1736,
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(

              "Smart College Ecosystem",

              style: TextStyle(

                fontSize: 18,

                color:
                Colors.grey,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            AnimatedBuilder(

              animation:
              controller,

              builder:
                  (
                  context,
                  child,
                  ) {

                return Transform.rotate(

                  angle:

                  controller
                      .value *

                      2 *

                      math.pi,

                  child:

                  Container(

                    width: 40,

                    height: 40,

                    decoration:
                    BoxDecoration(

                      shape:
                      BoxShape.circle,

                      border:
                      Border.all(

                        color:
                        Colors.blue,

                        width:
                        4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}